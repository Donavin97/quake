const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

// We can assume admin is already initialized

exports.usgsNotifier = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
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
