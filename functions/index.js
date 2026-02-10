const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.earthquakeWebhook = functions.https.onRequest(async (req, res) => {
    try {
        const geojson = req.body;
        const earthquakes = geojson.features;

        if (!earthquakes || earthquakes.length === 0) {
            console.log("No earthquakes in the webhook payload.");
            res.status(200).send("No earthquakes to process.");
            return;
        }

        const usersSnapshot = await db.collection("user_preferences").get();

        if (usersSnapshot.empty) {
            console.log("No users found in the user_preferences collection.");
            res.status(200).send("No users to notify.");
            return;
        }

        const users = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        for (const earthquake of earthquakes) {
            const magnitude = earthquake.properties.mag;
            const place = earthquake.properties.place;

            for (const user of users) {
                const minMagnitude = user.min_magnitude || 0;
                const fcmToken = user.fcm_token;

                if (fcmToken && magnitude >= minMagnitude) {
                    const payload = {
                        notification: {
                            title: `New Earthquake: ${magnitude.toFixed(2)} magnitude`,
                            body: place,
                        },
                        data: {
                          magnitude: magnitude.toString(),
                          lat: earthquake.geometry.coordinates[1].toString(),
                          lng: earthquake.geometry.coordinates[0].toString(),
                        },
                        token: fcmToken,
                    };

                    try {
                        await messaging.send(payload);
                        console.log(
                            `Notification sent to user ${user.id} for earthquake ${earthquake.id}`
                        );
                    } catch (error) {
                        console.error(
                            `Error sending notification to user ${user.id}:`,
                            error,
                        );
                    }
                }
            }
        }
        res.status(200).send("Notifications processed.");

    } catch (error) {
        console.error(
            "Error processing earthquake webhook:",
            error,
        );
        res.status(500).send("Internal Server Error");
    }
});
