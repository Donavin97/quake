const functions = require('firebase-functions');
const admin = require('firebase-admin');
const geohash = require('ngeohash');

admin.initializeApp();

exports.earthquakeNotifier = functions.firestore
  .document('earthquakes/{earthquakeId}')
  .onCreate(async (snap, context) => {
    const earthquake = snap.data();

    // Calculate geohash for the earthquake's location
    const earthquakeGeohash = geohash.encode(earthquake.latitude, earthquake.longitude, 5);

    const payload = {
      notification: {
        title: 'New Earthquake Alert!',
        body: `Magnitude ${earthquake.magnitude} earthquake near ${earthquake.place}`,
        sound: 'default',
      },
      data: {
        earthquakeId: context.params.earthquakeId,
      },
    };

    try {
      // Send notification to the geohash topic
      await admin.messaging().sendToTopic(earthquakeGeohash, payload);

      // Send notification to the magnitude topic
      const magnitudeTopic = `magnitude_${Math.floor(earthquake.magnitude)}`;
      await admin.messaging().sendToTopic(magnitudeTopic, payload);

      console.log('Notifications sent successfully!');
    } catch (error) {
      console.error('Error sending notifications:', error);
    }
  });
