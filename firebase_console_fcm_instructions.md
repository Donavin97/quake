To send a test notification to your app's topic using the Firebase Console, follow these steps:

1.  **Go to the Firebase Console:** Open your web browser and navigate to [https://console.firebase.google.com/](https://console.firebase.google.com/).
2.  **Select Your Project:** Make sure you have selected the correct Firebase project for your QuakeTrack app.
3.  **Navigate to Cloud Messaging:** In the left-hand navigation pane, expand "Engage" and click on "Messaging."
4.  **Send Your First Message:** Click the "Send your first message" button (or "Send your first message" if it's your first time).
5.  **Compose Notification:**
    *   **Notification title:** Enter a title for your notification (e.g., "Test Earthquake Alert").
    *   **Notification text:** Enter the message body (e.g., "A test earthquake has occurred.").
    *   **(Optional) Notification image:** You can add an image URL if desired.
6.  **Target:**
    *   Click on the "Send to a test device" dropdown and choose "User segment" or "Topic".
    *   If targeting a topic, select the "Topic" option and enter the name of your app's topic (e.g., `earthquake_alerts`).
    *   Ensure "QuakeTrack" is selected in the "App" dropdown.
7.  **Scheduling:** For a test, you can select "Now".
8.  **Review and Publish:** Click "Review" and then "Publish" to send the notification.

Your app should receive the notification if it's running in the foreground or background and subscribed to the specified topic.