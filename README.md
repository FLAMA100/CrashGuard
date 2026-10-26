 CrashGuard
Your phone, watching your back.

Automatic accident detection that alerts your emergency contact the moment you can't.


In a serious accident, the first minutes matter most, yet the person who needs help is often the one least able to ask for it. CrashGuard turns the smartphone already in your pocket into a silent safety net.

Built with Flutter, CrashGuard continuously reads your phone's motion sensors, recognises the sudden, violent signature of an impact, and, unless you cancel it, automatically sends an SMS with your exact GPS location to your emergency contact. No internet connection, no account, no server: just the sensors and cellular network your phone already has.

Designed with real roads and real response times in mind, especially in regions where emergency services are slow to be notified.

 Features
	Feature	Description
	Smart crash detection	Rolling-average spike analysis on accelerometer data separates genuine impacts from everyday bumps and movement.
	Precise location sharing	The emergency message includes your GPS coordinates so responders and loved ones know exactly where to go.
	Cancellable countdown	A short countdown after detection gives you full control to dismiss a false alarm before anything is sent.
	Background SMS delivery	Alerts are sent as standard text messages, with no data connection or Wi-Fi required.
	Sensor-efficient design	Uses only the accelerometer and GPS, so it works on a wide range of Android devices, including budget phones.
	Private by design	Settings stay on your device. No accounts, no cloud, no tracking.
	Permission-aware	Clear runtime permission handling for location and SMS access.
 How It Works
┌──────────────┐    ┌───────────────────┐    ┌──────────────┐    ┌───────────────┐
│ Accelerometer│ ─▶ │ Rolling-average   │ ─▶ │  Countdown   │ ─▶ │  GPS + SMS    │
│   stream     │    │ spike detection   │    │ (cancellable)│    │ emergency alert│
└──────────────┘    └───────────────────┘    └──────────────┘    └───────────────┘
Monitor. sensors_plus streams accelerometer readings in real time.
Detect. Each new reading is compared against a rolling average of recent values. A sharp spike far above the recent baseline signals a possible impact, while normal driving, walking, and phone handling stay within the baseline.
Confirm. The app starts a countdown and alerts you. One tap cancels it if you're fine.
Locate. If the countdown completes, geolocator retrieves your current GPS position.
Alert. background_sms sends the emergency message with your location to your saved contact.
Why accelerometer-only?

CrashGuard is built to work without a gyroscope. By relying on rolling-average accelerometer analysis, it runs on devices where gyroscope hardware is absent or disabled, which makes it accessible to far more users than designs that require a full sensor suite.

 Tech Stack
Purpose	Package
Framework	Flutter / Dart
Motion sensing	sensors_plus
Location	geolocator
Background SMS	background_sms, with a custom-rewritten Java plugin for Flutter v2 embedding
Local persistence	shared_preferences
Runtime permissions	permission_handler
Custom SMS plugin

The stock background_sms plugin was rewritten (BackgroundSmsPlugin.java) to support Flutter's v2 Android embedding, keeping CrashGuard compatible with modern Flutter toolchains.

 Getting Started
Prerequisites
Flutter SDK (stable channel)
Android SDK
A physical Android device with a SIM card, which is the best way to experience sensors and SMS exactly as they work in real use
Installation
bash
# Clone the repository
git clone https://github.com/FLAMA100/CrashGuard.git
cd CrashGuard

# Install dependencies
flutter pub get

# Run on a connected device
flutter run
Build a release APK
bash
flutter build apk --release

The APK will be generated at build/app/outputs/flutter-apk/app-release.apk.

Permissions

On first launch, CrashGuard requests:

 Location, to include your position in the alert
 SMS, to send the emergency message
 Sensor access, to monitor motion
 Windows Setup Tip

For the smoothest Android builds on Windows, keep your SDKs and project in paths without spaces:

C:\Flutter        → Flutter SDK (a directory junction works great)
C:\Android\Sdk    → Android SDK
C:\crashguard     → Project directory
 Tested On
Device	OS
Samsung Galaxy A07	Android 15
 Roadmap
 Accelerometer-based crash detection with rolling-average analysis
 GPS-tagged emergency SMS
 Cancellable countdown
 Custom background SMS plugin for Flutter v2 embedding
 Multiple emergency contacts
 Sensor fusion with gyroscope on supported devices
 Customisable detection sensitivity
 Emergency services integration
 Crash event history
 iOS support
 Safety Note

CrashGuard is designed as an additional layer of protection and works best alongside safe driving habits and standard safety equipment.

GitHub

 Contributing

Ideas, issues, and pull requests are welcome!

Fork the repository
Create your feature branch: git checkout -b feature/amazing-feature
Commit your changes: git commit -m "Add amazing feature"
Push to the branch: git push origin feature/amazing-feature
Open a Pull Request
 License

Distributed under the MIT License. See LICENSE for more information.

If CrashGuard looks useful to you, give it a ⭐ on GitHub!
