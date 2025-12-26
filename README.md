# Silent Bypass Pager

**Never miss a critical SMS alert again.**

Silent Bypass Pager is a Flutter application designed for on-call professionals (EMTs, Firefighters, Doctors, Sysadmins) who need to receive loud audio alerts from specific dispatch numbers, even when their phone is set to **Silent**, **Vibrate**, or **Do Not Disturb**.

## Features

* **Silent Mode Bypass:** Uses the Android Alarm Stream to play sound at full volume regardless of ringer settings.
* **Custom Sounds:** Assign different MP3 files to different contacts or dispatch centers.
* **Background Listening:** Works reliably even when the app is closed or the screen is off.
* **Alphanumeric Support:** Supports standard phone numbers (e.g., `123456`) and Sender IDs (e.g., `Dispatch`).
* **Master Toggle:** Quickly disable all pager alerts when you are off-duty.
* **Stop Button:** Big, accessible button to immediately silence an active alert.
* **MVVM Architecture:** Clean, maintainable code structure using the Provider pattern.


## Installation & Setup

This app is designed for **Android** devices (iOS does not allow apps to intercept incoming SMS messages).

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
* An Android device (Physical device recommended for SMS testing).

### Steps
1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/kiwimarc/pager_sms_alert.git](https://github.com/kiwimarc/pager_sms_alert.git)
    cd pager_sms_alert
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    Connect your Android device and run:
    ```bash
    flutter run
    ```

4.  **Grant Permissions:**
    On the first launch, the app will request:
    * **SMS Permissions:** To read incoming sender numbers.
    * **Notification Permissions:** To keep the background service alive.

## How to Use

1.  **Pick a Sound:** Click "Pick Sound" and select a loud MP3 file from your device storage.
2.  **Enter Sender:** Type the phone number (e.g., `123456`) or the Name (e.g., `Dispatch`) exactly as it appears in your messages.
3.  **Add to List:** Click "Add Priority Contact".
4.  **Test It:**
    * Put your phone on **Silent**.
    * Send a text from that number.
    * The chosen sound should play loudly!
5.  **Stop Alarm:** Open the app and press the big red **STOP ALARM** button to silence the alert.

## Technical Details

This project uses **Flutter** with a specific focus on Android native APIs.

* **State Management:** `provider` (MVVM pattern).
* **SMS Handling:** `another_telephony` (Forks a BroadcastReceiver to intercept `android.provider.Telephony.SMS_RECEIVED`).
* **Audio:** `just_audio` and `audio_session` (Configured with `AndroidAudioUsage.alarm` to bypass volume restrictions).
* **Storage:** `shared_preferences` (Stores contact list and settings JSON).
* **File Handling:** `path_provider` (Copies picked MP3s to internal app storage for secure background access).

## Disclaimer

**Use at your own risk.** While this app is designed to be reliable, changes in Android OS battery optimizations or background restrictions can potentially delay or block alerts. Do not rely solely on this app for life-safety situations without verifying it works on your specific device configuration.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the [GPLv3 License](LICENSE).