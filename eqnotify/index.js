const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.eqnotify = functions.pubsub.schedule("every 1 minutes").onRun(
    async (context) => {
      try {
        const response = await axios.get(
            "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson",
        );
        const earthquakes = response.data.features;

        if (!earthquakes || earthquakes.length === 0) {
          console.log("No earthquakes found in the last hour.");
          return;
        }

        const usersSnapshot = await db.collection("user_preferences").get();

        if (usersSnapshot.empty) {
          console.log("No users found in the user_preferences collection.");
          return;
        }

        for (const earthquake of earthquakes) {
          const magnitude = earthquake.properties.mag;
          const place = earthquake.properties.place;

          for (const userDoc of usersSnapshot.docs) {
            const user = userDoc.data();
            const minMagnitude = user.min_magnitude || 0;
            const fcmToken = user.fcm_token;

            if (fcmToken && magnitude >= minMagnitude) {
              const payload = {
                notification: {
                  title: `New Earthquake: ${magnitude.toFixed(1)} magnitude`,
                  body: place,
                },
                token: fcmToken,
              };

              try {
                await messaging.send(payload);
                console.log(
                    `Notification sent to user ${userDoc.id} for earthquake
                    ${earthquake.id}`,
                );
              } catch (error) {
                console.error(
                    `Error sending notification to user ${userDoc.id}:`,
                    error,
                );
              }
            }
          }
        }
      } catch (error) {
        console.error(
            "Error fetching earthquake data or sending notifications:",
            error,
        );
      }
    },
);
