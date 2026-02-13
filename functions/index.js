const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const geohash = require('ngeohash');

admin.initializeApp();

exports.usgsNotifier = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const response = await axios.get(
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson'
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
        source: 'USGS',
      };

      // Check if the earthquake already exists in Firestore
      const earthquakeRef = admin.firestore().collection('earthquakes').doc(earthquakeId);
      const doc = await earthquakeRef.get();

      if (!doc.exists) {
        await earthquakeRef.set(earthquakeData);
      }
    }
  });

exports.emscNotifier = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  try {
    const response = await axios.get('https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=100');
    const earthquakes = response.data.features;

    const batch = admin.firestore().batch();

    earthquakes.forEach(earthquake => {
      const id = earthquake.id;
      const properties = earthquake.properties;
      const geometry = earthquake.geometry;

      const docRef = admin.firestore().collection('earthquakes').doc(id);

      const timeInMillis = Date.parse(properties.time);
      const timestamp = admin.firestore.Timestamp.fromMillis(timeInMillis);

      batch.set(docRef, {
        magnitude: properties.mag,
        place: properties.flynn_region,
        time: timestamp,
        latitude: geometry.coordinates[1],
        longitude: geometry.coordinates[0],
        source: 'EMSC'
      });
    });

    await batch.commit();
    console.log('Successfully fetched and stored earthquake data from EMSC.');
  } catch (error) {
    console.error('Error fetching earthquake data from EMSC:', error);
  }
});

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
