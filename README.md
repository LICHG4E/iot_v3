# PlantCare IoT 🌱

A modern Flutter-based IoT application for monitoring and managing plant care devices with real-time data visualization, Firebase integration, and ML-powered plant disease detection.

## ✨ Features

### 🔐 Authentication & User Management
- Secure Firebase Authentication (Email/Password)
- Email verification system
- Password reset functionality
- User profile management

### 📱 Device Management
- QR code-based device pairing
- Multi-device support
- Real-time device status monitoring
- Easy device addition and removal
- Pull-to-refresh data updates

### 📊 Real-Time Monitoring
- Temperature, humidity, and pressure tracking
- Light intensity monitoring
- Fire detection alerts
- Customizable chart data points
- Auto-refreshing data visualization
- Interactive FL Chart graphs

### 🎨 Modern UI/UX
- Material 3 design system
- Light and dark theme support
- Smooth animations with Rive
- Responsive grid layouts
- Hero transitions
- Modern card-based interface

### 🔔 Notifications
- Push notifications for alerts
- Background service for monitoring
- Customizable notification settings
- Fire alarm system

### 🌿 Plant Disease Detection
- TensorFlow Lite integration
- Camera-based plant scanning
- Real-time disease identification
- ML model for plant health analysis

### ⚙️ Settings & Customization
- Configurable data refresh intervals
- Customizable sensor thresholds
- Temperature, humidity, pressure ranges
- Light intensity preferences
- Notification preferences

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.5.4)
- Dart SDK
- Firebase account and project setup
- Android Studio / VS Code
- Physical device or emulator with camera

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd iot_v3
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android and iOS apps to your Firebase project
   - Download and place `google-services.json` in `android/app/`
   - Download and place `GoogleService-Info.plist` in `ios/Runner/`
   - Run FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point
├── main_page.dart            # Auth state management
├── firebase_options.dart     # Firebase configuration
├── constants/
│   ├── routes.dart          # Route definitions
│   └── app_constants.dart   # App-wide constants
├── models/
│   └── *.tflite            # ML models
├── pages/
│   ├── home_page.dart       # Main dashboard
│   ├── device_data.dart     # Device details & charts
│   ├── camera_screen.dart   # Camera for plant scanning
│   ├── scan_screen.dart     # ML scanning interface
│   ├── auth_pages/          # Authentication screens
│   ├── drawer_pages/        # Settings, profile, etc.
│   └── providers/           # State management
├── app_theme/
│   ├── app_themes.dart      # Theme definitions
│   ├── theme_provider.dart  # Theme state management
│   └── custom_themes/       # Component themes
├── widgets/
│   └── app_widgets.dart     # Reusable UI components
├── tasks/
│   └── alert_task.dart      # Background notifications
└── assets/
    ├── animations/          # Rive animations
    ├── images/             # Image assets
    └── sounds/             # Audio files
```

## 🔧 Configuration

### Firebase Collections Structure

**users/**
- `userId` (document ID)
  - `email`: string
  - `devices`: array of device IDs

**beaglebones/**
- `deviceId` (document ID)
  - **data/** (subcollection)
    - `timestamp`: Timestamp
    - `temperature`: number
    - `humidity_percent`: number
    - `pressure`: number
    - `light_percent`: number
    - `fire_status`: string

### App Constants

Key configurations in `lib/constants/app_constants.dart`:
- Default sensor thresholds
- Update intervals
- UI constants
- Animation durations
- Error messages

## 📦 Dependencies

### Core
- `flutter` - UI framework
- `firebase_core` - Firebase SDK
- `firebase_auth` - Authentication
- `cloud_firestore` - Database

### State Management
- `provider` - State management solution

### UI/UX
- `rive` - Advanced animations
- `fl_chart` - Beautiful charts
- `font_awesome_flutter` - Icon library

### Camera & ML
- `camera` - Camera access
- `tflite_flutter` - TensorFlow Lite
- `image` - Image processing
- `mobile_scanner` - QR code scanning

### Services
- `flutter_background_service` - Background tasks
- `flutter_local_notifications` - Local notifications
- `shared_preferences` - Local storage

### Utilities
- `permission_handler` - Permission management
- `path_provider` - File paths
- `external_path` - External storage
- `intl` - Internationalization
- `flutter_email_sender` - Email support

## 🎨 Theming

The app supports both light and dark themes with:
- Material 3 design system
- Custom color schemes based on green palette
- Consistent component theming
- Smooth theme transitions
- Persistent theme preferences

## 🔔 Notifications

Background service monitors device data and sends alerts for:
- Fire detection
- Sensor threshold violations
- Device connectivity issues

## 📸 Plant Disease Detection

1. Navigate to camera screen
2. Capture plant image
3. ML model analyzes the image
4. View disease detection results
5. Get care recommendations

## 🛠️ Development

### Code Quality
- Flutter lints enabled
- Material 3 compliance
- Null safety
- Proper error handling

### Best Practices
- Separation of concerns
- Reusable widgets
- Constants management
- Proper state management
- Async/await patterns

## 📝 Version History

- **v1.0.0** (Current)
  - Initial release
  - Firebase integration
  - Material 3 UI
  - Real-time monitoring
  - ML plant disease detection
  - Background notifications

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Support

For support, email your configured support email or open an issue on GitHub.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- TensorFlow Lite for ML capabilities
- Rive for beautiful animations
- FL Chart for data visualization

---

Made with ❤️ using Flutter

