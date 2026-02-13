const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const geohash = require('ngeohash');

// We can assume admin is already initialized

exports.emscNotifier = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const response = await axios.get(
      'https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=10'
    );
    const earthquakes = response.data.features;

    for (const earthquake of earthquakes) {
      const { properties, geometry } = earthquake;
      const earthquakeId = earthquake.id;
      const { mag, place, time } = properties;
      const [longitude, latitude] = geometry.coordinates;

      const earthquakeData = {
        magnitude: mag,
        place: place,
        time: new admin.firestore.Timestamp(Math.floor(time / 1000), 0),
        latitude: latitude,
        longitude: longitude,
      };

      // Check if the earthquake already exists in Firestore
      const earthquakeRef = admin.firestore().collection('earthquakes').doc(earthquakeId);
      const doc = await earthquakeRef.get();

      if (!doc.exists) {
        await earthquakeRef.set(earthquakeData);

        const earthquakeGeohash = geohash.encode(latitude, longitude, 5);

        const payload = {
          notification: {
            title: 'New Earthquake Alert!',
            body: `Magnitude ${mag} earthquake near ${place}`,
            sound: 'default',
          },
          data: {
            earthquakeId: earthquakeId,
          },
        };

        try {
          // Send notification to the geohash topic
          await admin.messaging().sendToTopic(earthquakeGeohash, payload);

          // Send notification to the magnitude topic
          const magnitudeTopic = `magnitude_${Math.floor(mag)}`;
          await admin.messaging().sendToTopic(magnitudeTopic, payload);

          console.log(`Notifications sent successfully for ${earthquakeId}`)
        } catch (error) {
          console.error(`Error sending notifications for ${earthquakeId}:`, error);
        }
      }
    }
  });
