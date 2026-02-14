const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const geohash = require('ngeohash');

admin.initializeApp();

const sendNotification = async (earthquake) => {
  const earthquakeGeohash = geohash.encode(earthquake.latitude, earthquake.longitude, 5);

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
    apns: {
      payload: {
        aps: {
          sound: 'earthquake.wav',
        },
      },
    },
  };

  try {
    // Send notification to the geohash topic
    await admin.messaging().sendToTopic(earthquakeGeohash, payload);

    // Send notification to the magnitude topic
    const magnitudeTopic = `magnitude_${Math.floor(earthquake.magnitude)}`;
    await admin.messaging().sendToTopic(magnitudeTopic, payload);

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
