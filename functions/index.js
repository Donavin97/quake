/* eslint-disable require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const db = admin.firestore();

exports.checkEarthquakes = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async (context) => {
      const snapshot = await db.collection("earthquakes").get();
      const existingEarthquakes = snapshot.docs.map((doc) => doc.id);

      const response = await axios.get(
          "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson",
      );
      const newEarthquakes = response.data.features;

      for (const earthquake of newEarthquakes) {
        const earthquakeId = earthquake.id;
        if (!existingEarthquakes.includes(earthquakeId)) {
          await db.collection("earthquakes").doc(earthquakeId).set(earthquake);

          const usersSnapshot = await db.collection("users").get();
          usersSnapshot.forEach(async (userDoc) => {
            const user = userDoc.data();
            if (user.fcmToken) {
              const distance = getDistance(
                  user.latitude,
                  user.longitude,
                  earthquake.geometry.coordinates[1],
                  earthquake.geometry.coordinates[0],
              );

              if (distance <= user.radius) {
                const payload = {
                  notification: {
                    title: `New Earthquake: ${earthquake.properties.mag}`,
                    body: earthquake.properties.place,
                  },
                  data: {
                    earthquakeId: earthquakeId,
                  },
                };

                await admin.messaging().sendToDevice(user.fcmToken, payload);
              }
            }
          });
        }
      }
    });

function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the earth in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) *
        Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const d = R * c; // Distance in km
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI / 180);
}
