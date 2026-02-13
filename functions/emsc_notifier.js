import functions from 'firebase-functions';
import admin from 'firebase-admin';
import axios from 'axios';

export const emscNotifier = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
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
        source: 'EMSC',
      };

      // Check if the earthquake already exists in Firestore
      const earthquakeRef = admin.firestore().collection('earthquakes').doc(earthquakeId);
      const doc = await earthquakeRef.get();

      if (!doc.exists) {
        await earthquakeRef.set(earthquakeData);
      }
    }
  });
