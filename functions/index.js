const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const geohash = require('ngeohash');

admin.initializeApp();

const sendNotification = async (earthquake) => {
  const payload = {
    data: {
      title: 'New Earthquake Alert!',
      body: `Magnitude ${earthquake.magnitude.toFixed(1)} (${earthquake.source}) near ${earthquake.place}`,
      earthquake: JSON.stringify(earthquake),
      mapUrl: `https://www.google.com/maps/search/?api=1&query=${earthquake.latitude},${earthquake.longitude}`,
      sound: 'earthquake'
    }
  };

  try {
    const magnitude = Math.floor(earthquake.magnitude);
    if (magnitude < 0) {
        console.log('Skipping notification for earthquake with negative magnitude:', earthquake.id);
        return;
    }

    const topics = new Set();
    for (let i = 0; i <= magnitude; i++) {
      topics.add(`minmag_${i}`);
    }

    // Add geohash topics for different precision levels
    for (let precision = 1; precision <= 5; precision++) {
      const geohashTopic = geohash.encode(earthquake.latitude, earthquake.longitude, precision);
      topics.add(geohashTopic);
    }
    
    topics.add('global');


    if (topics.size === 0) {
      console.log('No topics to notify for earthquake:', earthquake.id);
      return;
    }
    
    const topicList = Array.from(topics);
    // FCM allows sending to a maximum of 5 topics in a single request.
    const CHUNK_SIZE = 5;
    for (let i = 0; i < topicList.length; i += CHUNK_SIZE) {
        const chunk = topicList.slice(i, i + CHUNK_SIZE);
        const condition = chunk.map(topic => `\'${topic}\' in topics`).join(' || ');
        
        const message = {
            ...payload,
            condition: condition,
        };

        await admin.messaging().send(message);
        console.log(`Notification sent for condition: ${condition}`);
    }

    console.log('Notifications sent successfully for earthquake:', earthquake.id);
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


exports.usgsNotifier = createEarthquakeNotifier(
  'usgs',
  'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson',
  (data) => {
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
);

exports.emscNotifier = createEarthquakeNotifier(
  'emsc',
  'https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=50&nodata=404',
  (data) => {
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
);
