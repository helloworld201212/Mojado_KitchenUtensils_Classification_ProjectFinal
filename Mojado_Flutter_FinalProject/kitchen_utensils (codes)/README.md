# Flutter Camera App

A simple Flutter app that demonstrates camera functionality using only Flutter and Dart.

## Features

- 📷 **Camera Preview**: Live camera feed
- 📸 **Take Pictures**: Capture photos with a button
- 🎥 **Record Videos**: Start and stop video recording
- 📱 **Cross-Platform**: Works on Android, iOS, and Web
- 🔒 **Permissions**: Automatic camera permission handling

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

### Installation

1. **Clone the project**
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Usage

1. **Grant camera permissions** when prompted
2. **Take pictures** using the "Take Picture" button
3. **Record videos** using the "Start Recording" button
4. **Stop recording** using the "Stop Recording" button

## Dependencies

- **camera**: Camera access and preview
- **permission_handler**: Camera permission management

## Platform Support

- ✅ **Android**: Full camera functionality
- ✅ **iOS**: Full camera functionality  
- ✅ **Web**: Camera access (limited by browser)

## File Structure

```
tm_flutter_app/
├── lib/
│   └── main.dart              # Main app with camera functionality
├── android/app/src/main/
│   └── AndroidManifest.xml    # Android camera permissions
├── ios/Runner/
│   └── Info.plist            # iOS camera permissions
├── web/
│   ├── index.html            # Web entry point
│   └── manifest.json         # Web app manifest
└── pubspec.yaml              # Dependencies
```

## Key Features

### Camera Preview
- Live camera feed taking up most of the screen
- Automatic camera initialization
- Error handling for camera access

### Picture Taking
- Simple button to capture photos
- Automatic file saving
- Success/error feedback

### Video Recording
- Start and stop video recording
- Visual feedback for recording state
- Automatic file saving

### Status Display
- Real-time status updates
- Error messages
- Success confirmations

## Troubleshooting

### Camera Permission Denied
- Check device settings for camera permissions
- Restart the app after granting permissions

### No Cameras Found
- Ensure device has a camera
- Check if camera is being used by another app

### Web Camera Issues
- Ensure you're using HTTPS (required for camera access)
- Check browser compatibility (Chrome, Firefox, Safari)

## Next Steps

1. **Test the app** on your device
2. **Customize the UI** as needed
3. **Add more features** like image filters or effects
4. **Deploy** to app stores

## License

This project is open source and available under the MIT License.
