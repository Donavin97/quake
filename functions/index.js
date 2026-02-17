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
    const earthquakeTime = new Date(earthquake.time); // Convert earthquake time to Date object

    // Fetch all users who have notifications enabled and minMagnitude <= earthquake.magnitude
    const usersSnapshot = await admin.firestore().collection('users')
      .where('preferences.notificationsEnabled', '==', true)
      .where('preferences.minMagnitude', '<=', earthquakeMagnitude)
      .get();

    const recipientTokens = [];

    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      const preferences = userData.preferences;
      const fcmToken = userData.fcmToken;
      const userLocation = userData.location; // User's last known location

      if (!fcmToken) {
        console.log(`User ${doc.id} has no FCM token. Skipping.`);
        return;
      }

      // Check quiet hours
      const currentTime = new Date(); // Current time on the server
      let shouldSendNotification = true; // Assume notification should be sent by default

      if (isDuringQuietHours(preferences, currentTime, earthquakeTime)) {
        // We are in quiet hours, check for emergency override
        shouldSendNotification = false; // Don't send by default during quiet hours

        if (earthquakeMagnitude >= preferences.emergencyMagnitudeThreshold) {
          // Magnitude threshold met, now check proximity
          if (userLocation && userLocation.latitude && userLocation.longitude) {
            const distance = getDistance(
              userLocation.latitude, userLocation.longitude,
              earthquakeLatitude, earthquakeLongitude
            );

            if (distance <= preferences.emergencyRadius) {
              shouldSendNotification = true; // Emergency override - send notification
              console.log(`Emergency override for user ${doc.id}: Magnitude ${earthquakeMagnitude} >= ${preferences.emergencyMagnitudeThreshold} AND distance ${distance} km <= ${preferences.emergencyRadius} km.`);
            } else {
              console.log(`User ${doc.id}: Emergency magnitude met but not within emergency radius. Distance: ${distance} km, Radius: ${preferences.emergencyRadius} km.`);
            }
          } else {
            console.log(`User ${doc.id}: Emergency magnitude met but no user location available for distance check. Will not send notification.`);
            // If no location, cannot apply radius filter, so no emergency override based on proximity.
          }
        } else {
          console.log(`User ${doc.id}: During quiet hours. Emergency magnitude (${earthquakeMagnitude}) not met (${preferences.emergencyMagnitudeThreshold}). Will not send notification.`);
        }
      }

      // Final decision to send based on all criteria
      if (shouldSendNotification) {
        recipientTokens.push(fcmToken);
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

    // Send messages in batches
    const response = await admin.messaging().sendEachForMulticast({
      tokens: recipientTokens,
      data: messagePayload.data,
      android: messagePayload.android,
      apns: messagePayload.apns
    });

    console.log(`Notifications sent successfully for earthquake ${earthquake.id}: ${response.successCount} successful, ${response.failureCount} failed.`);

    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`Failed to send message to token ${recipientTokens[idx]}: ${resp.error}`);
          // TODO: Optionally remove invalid tokens from Firestore
        }
      });
    }

  } catch (error) {
    console.error('Error sending notifications for earthquake:', earthquake.id, error);
  }
};


const createEarthquakeNotifier = (source, apiUrl, dataTransformer) => {
  return functions.pubsub.schedule('every 5 minutes').onRun(async () => {
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
