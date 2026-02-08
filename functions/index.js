const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

const USGS_API_URL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson";

exports.fetchEarthquakes = functions.pubsub
    .schedule("every 1 minutes")
    .onRun(async (context) => {
      const response = await fetch(USGS_API_URL);
      const data = await response.json();

      const earthquakes = data.features.map((feature) => {
        return {
          id: feature.id,
          mag: feature.properties.mag,
          place: feature.properties.place,
          time: feature.properties.time,
          url: feature.properties.url,
          lat: feature.geometry.coordinates[1],
          long: feature.geometry.coordinates[0],
        };
      });

      const lastFetchDoc = await admin.firestore()
          .collection("internal")
          .doc("lastFetch")
          .get();
      const lastFetchTime = lastFetchDoc.data()?.time || 0;

      let newLastFetchTime = lastFetchTime;

      for (const earthquake of earthquakes) {
        if (earthquake.time > lastFetchTime) {
          if (earthquake.time > newLastFetchTime) {
            newLastFetchTime = earthquake.time;
          }
          const message = {
            notification: {
              title: `New Earthquake: ${earthquake.mag.toFixed(2)} magnitude`,
              body: earthquake.place,
            },
            topic: "all",
          };

          await admin.messaging().send(message);
        }
      }

      if (newLastFetchTime > lastFetchTime) {
        await admin.firestore().collection("internal").doc("lastFetch").set({
          time: newLastFetchTime,
        });
      }

      return null;
    });
