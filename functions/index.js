const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const axios = require('axios');
const geohash = require('ngeohash');

admin.initializeApp();

// Haversine formula to calculate distance between two points in km
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of Earth in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  return distance;
}

// Helper for reverse geocoding using Nominatim
const reverseGeocode = async (lat, lon) => {
  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/reverse', {
      params: {
        format: 'jsonv2',
        lat: lat,
        lon: lon,
        zoom: 13,
        addressdetails: 1
      },
      headers: {
        'User-Agent': 'QuakeTrackApp/1.0'
      }
    });

    if (response.status === 200 && response.data) {
      const address = response.data.address;
      if (address) {
        const city = address.city || address.town || address.suburb || address.village;
        const state = address.state || address.province || address.county;
        const country = address.country;

        if (city && state) return `${city}, ${state}, ${country}`;
        if (state) return `${state}, ${country}`;
        return country;
      }
      return response.data.display_name;
    }
  } catch (error) {
    console.error(`Geocoding error for ${lat}, ${lon}:`, error.message);
  }
  return null;
};

// Function to check if current time is within quiet hours
function isDuringQuietHours(preferences, currentTime, earthquakeTime) {
  if (!preferences.quietHoursEnabled) {
    return false; // Quiet hours not enabled
  }

  const currentHour = currentTime.getHours();
  const currentMinute = currentTime.getMinutes();
  const currentDay = currentTime.getDay(); // 0 = Sunday, 6 = Saturday

  const quietStartHour = preferences.quietHoursStart[0];
  const quietStartMinute = preferences.quietHoursStart[1];
  const quietEndHour = preferences.quietHoursEnd[0];
  const quietEndMinute = preferences.quietHoursEnd[1];
  const quietDays = preferences.quietHoursDays;

  // Check if today is a quiet day
  // quietDays from preferences is an array of numbers [0,1,2,3,4,5,6]
  if (!quietDays.includes(currentDay)) {
    return false; // Not a quiet day
  }

  // Convert current time to minutes from midnight
  const currentTotalMinutes = currentHour * 60 + currentMinute;
  const quietStartTotalMinutes = quietStartHour * 60 + quietStartMinute;
  const quietEndTotalMinutes = quietEndHour * 60 + quietEndMinute;

  if (quietStartTotalMinutes < quietEndTotalMinutes) {
    // Quiet hours are within the same day (e.g., 08:00 - 17:00)
    return currentTotalMinutes >= quietStartTotalMinutes && currentTotalMinutes < quietEndTotalMinutes;
  } else {
    // Quiet hours span across midnight (e.g., 22:00 - 06:00)
    return currentTotalMinutes >= quietStartTotalMinutes || currentTotalMinutes < quietEndTotalMinutes;
  }
}



const sendNotification = async (earthquake) => {
  try {
    const earthquakeMagnitude = earthquake.magnitude;
    const earthquakeLatitude = earthquake.latitude;
    const earthquakeLongitude = earthquake.longitude;
    const earthquakeTime = new Date(earthquake.time);
    
    // Calculate earthquake geohash
    const eqHash = geohash.encode(earthquakeLatitude, earthquakeLongitude, 10);
    const eqPrefix2 = eqHash.substring(0, 2); // ~1250km area
    
    console.log(`Processing notification for ${earthquake.id}. Magnitude: ${earthquakeMagnitude}. Geohash: ${eqHash} (Prefix: ${eqPrefix2})`);

    const usersCollection = admin.firestore().collection('users');
    const baseQuery = usersCollection.where('preferences.notificationsEnabled', '==', true);

    // We perform two queries in parallel to catch both local and global users
    // Query 1: Local users (using geohash range for prefix)
    const localQuery = baseQuery
      .where('location.geohash', '>=', eqPrefix2)
      .where('location.geohash', '<=', eqPrefix2 + '\uf8ff')
      .get();

    // Query 2: Global users (radius set to 0)
    const globalQuery = baseQuery
      .where('preferences.radius', '==', 0)
      .get();

    const [localSnapshot, globalSnapshot] = await Promise.all([localQuery, globalQuery]);

    // Use a Map to deduplicate users by ID
    const uniqueUsers = new Map();
    
    localSnapshot.forEach(doc => uniqueUsers.set(doc.id, doc.data()));
    globalSnapshot.forEach(doc => uniqueUsers.set(doc.id, doc.data()));

    console.log(`Found ${uniqueUsers.size} potential recipients (${localSnapshot.size} local, ${globalSnapshot.size} global).`);

    const recipientTokens = [];

    uniqueUsers.forEach((userData, userId) => {
      const preferences = userData.preferences;
      const fcmToken = userData.fcmToken;
      const userLocation = userData.location;

      if (!fcmToken) return;

      // Filter by magnitude first (most common filter)
      if (earthquakeMagnitude < (preferences.minMagnitude || 0)) {
        // Check if global magnitude override applies
        if (!(preferences.globalMinMagnitudeOverrideQuietHours > 0 && earthquakeMagnitude >= preferences.globalMinMagnitudeOverrideQuietHours)) {
          return; 
        }
      }

      const currentTime = new Date();
      let shouldSendNotification = false;

      // 1. Check for Global Minimum Magnitude Override
      if (preferences.globalMinMagnitudeOverrideQuietHours > 0 && earthquakeMagnitude >= preferences.globalMinMagnitudeOverrideQuietHours) {
        shouldSendNotification = true;
      }

      // 2. Check for Always Notify Radius
      if (!shouldSendNotification && preferences.alwaysNotifyRadiusEnabled && preferences.alwaysNotifyRadiusValue > 0 && userLocation) {
        const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
        if (distance <= preferences.alwaysNotifyRadiusValue) {
          shouldSendNotification = true;
        }
      }

      // 3. Regular Radius check (if radius is set and not worldwide)
      if (!shouldSendNotification && preferences.radius > 0 && userLocation) {
        const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
        if (distance > preferences.radius) {
          return; // Outside requested notification radius
        }
      }

      // 4. Quiet Hours / Emergency Logic
      if (!shouldSendNotification) {
        if (isDuringQuietHours(preferences, currentTime, earthquakeTime)) {
          if (earthquakeMagnitude >= preferences.emergencyMagnitudeThreshold && userLocation) {
            const distance = getDistance(userLocation.latitude, userLocation.longitude, earthquakeLatitude, earthquakeLongitude);
            if (distance <= preferences.emergencyRadius) {
              shouldSendNotification = true;
            }
          }
        } else {
          shouldSendNotification = true;
        }
      }

      if (shouldSendNotification) {
        recipientTokens.push({ token: fcmToken, userId: userId });
      }
    });

    const magnitudeText = earthquake.source === 'SEC' 
      ? earthquake.magnitude.toFixed(2) 
      : earthquake.magnitude.toFixed(1);

    const messagePayload = {
      data: {
        title: 'New Earthquake Alert!',
        body: `Magnitude ${magnitudeText} (${earthquake.source}) near ${earthquake.place}`,
        earthquake: JSON.stringify(earthquake),
        mapUrl: `https://www.google.com/maps/search/?api=1&query=${earthquake.latitude},${earthquake.longitude}`,
        sound: 'earthquake'
      },
      android: {
        priority: 'high',
      }
    };

    if (recipientTokens.length === 0) {
      console.log('No eligible recipients found in Firestore for earthquake:', earthquake.id);
    } else {
      const messages = recipientTokens.map(r => ({
        token: r.token,
        data: messagePayload.data,
        android: messagePayload.android
      }));

      // Send messages in batches of 500 (Firebase limit for sendEach)
      const BATCH_SIZE = 500;
      for (let i = 0; i < messages.length; i += BATCH_SIZE) {
        const batch = messages.slice(i, i + BATCH_SIZE);
        const response = await admin.messaging().sendEach(batch);

        console.log(`Batch ${Math.floor(i / BATCH_SIZE) + 1} sent: ${response.successCount} successful, ${response.failureCount} failed.`);

        if (response.failureCount > 0) {
          const cleanupPromises = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const invalidToken = batch[idx].token;
              const invalidUserId = recipientTokens[i + idx].userId;
              
              if (resp.error.code === 'messaging/invalid-registration-token' ||
                  resp.error.code === 'messaging/registration-token-not-registered' ||
                  resp.error.code === 'messaging/unregistered') {
                console.log(`Removing invalid FCM token for user ${invalidUserId}.`);
                cleanupPromises.push(
                  admin.firestore().collection('users').doc(invalidUserId).update({
                    fcmToken: admin.firestore.FieldValue.delete()
                  })
                );
              }
            }
          });
          if (cleanupPromises.length > 0) {
            await Promise.all(cleanupPromises);
          }
        }
      }
    }

    // ALSO send to topics as requested (Global and Geohash-based)
    // This serves as a broadcast mechanism
    try {
      const topicMessages = [];
      
      // 1. Global topic
      topicMessages.push({
        topic: 'global',
        data: messagePayload.data,
        android: messagePayload.android
      });

      // 2. Geohash topic (prefix of 2 chars)
      topicMessages.push({
        topic: `geo_${eqPrefix2}`,
        data: messagePayload.data,
        android: messagePayload.android
      });

      // 3. Magnitude topic (e.g. minmag_5)
      const magFloor = Math.floor(earthquakeMagnitude);
      topicMessages.push({
        topic: `minmag_${magFloor}`,
        data: messagePayload.data,
        android: messagePayload.android
      });

      await Promise.all(topicMessages.map(msg => admin.messaging().send(msg)));
      console.log(`Topic notifications sent for ${earthquake.id} (global, geo_${eqPrefix2}, minmag_${magFloor})`);
    } catch (topicError) {
      console.error('Error sending topic notifications:', topicError);
    }

  } catch (error) {
    console.error('Error sending notifications for earthquake:', earthquake.id, error);
  }
};


const createEarthquakeNotifier = (source, apiUrl, dataTransformer) => {
  return functions.pubsub.schedule('every 2 minutes').onRun(async () => {
    const lastTimestampRef = admin.database().ref(`last_timestamps/${source}`);
    const lastTimestampSnapshot = await lastTimestampRef.once('value');
    let lastTimestamp = lastTimestampSnapshot.val() || 0;

    try {
      const response = await axios.get(apiUrl);
      const earthquakes = dataTransformer(response.data);
      let maxTimestamp = lastTimestamp;

      for (const earthquakeData of earthquakes) {
        if (earthquakeData.time > lastTimestamp) {
          // Geocode for better place description
          const betterPlace = await reverseGeocode(earthquakeData.latitude, earthquakeData.longitude);
          if (betterPlace) {
            earthquakeData.place = betterPlace;
          }
          await sendNotification(earthquakeData);
          if (earthquakeData.time > maxTimestamp) {
            maxTimestamp = earthquakeData.time;
          }
        }
      }
      await lastTimestampRef.set(maxTimestamp);
    } catch (error) {
      console.error(`Error fetching earthquake data from ${source}:`, error);
    }
  });
};

const sources = [
  {
    name: 'usgs',
    url: 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson',
    transformer: (data) => {
      return data.features.map(earthquake => {
        const { properties, geometry, id } = earthquake;
        const { mag, place, time } = properties;
        const [longitude, latitude] = geometry.coordinates;
        return {
          id: id,
          magnitude: mag,
          place: place,
          time: time,
          latitude: latitude,
          longitude: longitude,
          source: 'USGS',
        };
      });
    }
  },
  {
    name: 'emsc',
    url: 'https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=50&nodata=404',
    transformer: (data) => {
      return data.features.map(earthquake => {
        const { properties, geometry, id } = earthquake;
        const { mag, flynn_region, time } = properties;
        const [longitude, latitude] = geometry.coordinates;
        const timeInMillis = Date.parse(time);
        return {
          id: id,
          magnitude: mag,
          place: flynn_region,
          time: timeInMillis,
          latitude: latitude,
          longitude: longitude,
          source: 'EMSC'
        };
      });
    }
  },
  {
    name: 'sec',
    url: 'http://quakewatch.freeddns.org:8080/fdsnws/event/1/query?limit=5&format=json',
    transformer: (data) => {
      if (!data.seiscomp || !data.seiscomp.events) return [];
      return data.seiscomp.events.map(event => {
        return {
          id: event.eventID,
          magnitude: event.mag,
          place: event.region,
          time: Date.parse(event.otime),
          latitude: event.lat,
          longitude: event.lon,
          source: 'SEC'
        };
      });
    }
  }
];

const usgsSource = sources.find(s => s.name === 'usgs');
const emscSource = sources.find(s => s.name === 'emsc');
const secSource = sources.find(s => s.name === 'sec');

exports.usgsNotifier = createEarthquakeNotifier(usgsSource.name, usgsSource.url, usgsSource.transformer);
exports.emscNotifier = createEarthquakeNotifier(emscSource.name, emscSource.url, emscSource.transformer);
exports.secNotifier = createEarthquakeNotifier(secSource.name, secSource.url, secSource.transformer);
