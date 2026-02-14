const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const geohash = require('ngeohash');

admin.initializeApp({
    databaseURL: "https://quakewatch-89047796-c7f3c-default-rtdb.firebaseio.com"
});

const sendNotification = async (earthquake) => {
  const payload = {
    notification: {
      title: 'New Earthquake Alert!',
      body: `Magnitude ${earthquake.magnitude} (${earthquake.source}) near ${earthquake.place}`,
    },
    data: {
      earthquakeId: earthquake.id,
    },
    android: {
      notification: {
        sound: 'earthquake',
      },
    },
  };

  try {
    const magnitude = Math.floor(earthquake.magnitude);
    const magTopics = [];
    for (let i = 0; i <= magnitude; i++) {
      magTopics.push(`'minmag_${i}' in topics`);
    }

    if (magTopics.length === 0) {
      return;
    }

    for (let precision = 1; precision <= 6; precision++) {
      const earthquakeGeohash = geohash.encode(earthquake.latitude, earthquake.longitude, precision);
      
      // FCM condition can have max 5 topics. We use 1 for geohash, so 4 for magnitude.
      const chunkSize = 4; 
      for (let i = 0; i < magTopics.length; i += chunkSize) {
        const chunk = magTopics.slice(i, i + chunkSize);
        const condition = `'${earthquakeGeohash}' in topics && (${chunk.join(' || ')})`;
        
        const message = {
            ...payload,
            condition: condition,
        };

        await admin.messaging().send(message);
      }
    }

    console.log('Notifications sent successfully for earthquake:', earthquake.id);
  } catch (error) {
    console.error('Error sending notifications:', error);
  }
};

exports.usgsNotifier = functions.pubsub.schedule('every 5 minutes').onRun(async () => {
  const lastTimestampRef = admin.database().ref('last_timestamps/usgs');
  const lastTimestampSnapshot = await lastTimestampRef.once('value');
  let lastTimestamp = lastTimestampSnapshot.val() || 0;

  const response = await axios.get(
    'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson'
  );
  const earthquakes = response.data.features;
  let maxTimestamp = lastTimestamp;

  for (const earthquake of earthquakes) {
    const { properties, geometry, id } = earthquake;
    const { mag, place, time } = properties;
    const [longitude, latitude] = geometry.coordinates;

    if (time > lastTimestamp) {
      const earthquakeData = {
        id: id,
        magnitude: mag,
        place: place,
        time: time,
        latitude: latitude,
        longitude: longitude,
        source: 'USGS',
      };

      await sendNotification(earthquakeData);
      if (time > maxTimestamp) {
        maxTimestamp = time;
      }
    }
  }
  await lastTimestampRef.set(maxTimestamp);
});

exports.emscNotifier = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  const lastTimestampRef = admin.database().ref('last_timestamps/emsc');
  const lastTimestampSnapshot = await lastTimestampRef.once('value');
  let lastTimestamp = lastTimestampSnapshot.val() || 0;

  try {
    const response = await axios.get('https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=50&nodata=404');
    const earthquakes = response.data.features;
    let maxTimestamp = lastTimestamp;

    for (const earthquake of earthquakes) {
      const { properties, geometry, id } = earthquake;
      const { mag, flynn_region, time } = properties;
      const [longitude, latitude] = geometry.coordinates;

      const timeInMillis = Date.parse(time);

      if (timeInMillis > lastTimestamp) {
        const earthquakeData = {
          id: id,
          magnitude: mag,
          place: flynn_region,
          time: timeInMillis,
          latitude: latitude,
          longitude: longitude,
          source: 'EMSC'
        };
        await sendNotification(earthquakeData);
        if (timeInMillis > maxTimestamp) {
          maxTimestamp = timeInMillis;
        }
      }
    }
    await lastTimestampRef.set(maxTimestamp);
  } catch (error) {
    console.error('Error fetching earthquake data from EMSC:', error);
  }
});