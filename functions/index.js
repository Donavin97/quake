const functions = require('firebase-functions');
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

    if (recipientTokens.length === 0) {
      console.log('No eligible recipients for earthquake:', earthquake.id);
      return;
    }

    const messagePayload = {
      data: {
        title: 'New Earthquake Alert!',
        body: `Magnitude ${earthquake.magnitude.toFixed(1)} (${earthquake.source}) near ${earthquake.place}`,
        earthquake: JSON.stringify(earthquake),
        mapUrl: `https://www.google.com/maps/search/?api=1&query=${earthquake.latitude},${earthquake.longitude}`,
        sound: 'earthquake'
      },
      android: {
        priority: 'high'
      },
      apns: {
        headers: {
          'apns-priority': '10' // High priority for iOS
        }
      }
    };

    const tokensOnly = recipientTokens.map(r => r.token); // Extract tokens for sendEachForMulticast

    // Send messages in batches
    const response = await admin.messaging().sendEachForMulticast({
      tokens: tokensOnly,
      data: messagePayload.data,
      android: messagePayload.android,
      apns: messagePayload.apns
    });

    console.log(`Notifications sent successfully for earthquake ${earthquake.id}: ${response.successCount} successful, ${response.failureCount} failed.`);

    if (response.failureCount > 0) {
      response.responses.forEach(async (resp, idx) => { // Use async here
        if (!resp.success) {
          const invalidToken = recipientTokens[idx].token;
          const invalidUserId = recipientTokens[idx].userId;
          console.error(`Failed to send message to user ${invalidUserId} with token ${invalidToken}: ${resp.error}`);

          // Check if error indicates an invalid or expired token
          if (resp.error.code === 'messaging/invalid-registration-token' ||
              resp.error.code === 'messaging/registration-token-not-registered' ||
              resp.error.code === 'messaging/unregistered') { // Added 'messaging/unregistered' for completeness
            console.log(`Removing invalid FCM token for user ${invalidUserId}.`);
            // Remove the token from Firestore document
            await admin.firestore().collection('users').doc(invalidUserId).update({
              fcmToken: admin.firestore.FieldValue.delete() // Remove the field
            });
          }
        }
      });
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
  }
];

sources.forEach(source => {
  exports[`${source.name}Notifier`] = createEarthquakeNotifier(source.name, source.url, source.transformer);
});
