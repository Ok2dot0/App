# Cycle Calendar

A simple, privacy-focused menstrual cycle tracking application built with Flutter.

## Features

- **Calendar View**: Track your period days with an easy-to-use calendar interface
- **Period Prediction**: Algorithm predicts your next period based on your history
- **Cycle Insights**: View statistics about your average cycle length and period duration
- **Privacy First**: All data is stored locally on your device, not in the cloud
- **No Ads or Subscriptions**: Free to use with no hidden costs
- **Simple Interface**: Clean, intuitive design focused on essential features

## Screenshots

_Screenshots will be added in the future_

## To-Do

- Generate app icons using [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) package
  ```
  flutter pub add --dev flutter_launcher_icons
  ```
  And create a `flutter_launcher_icons.yaml` configuration file.

## Getting Started

### Prerequisites

- Flutter SDK 3.8.0 or higher
- Dart SDK 3.8.0 or higher
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone this repository
   ```
   git clone https://github.com/yourusername/cycle_calendar.git
   ```

2. Navigate to the project directory
   ```
   cd cycle_calendar
   ```

3. Get dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## How It Works

The app uses a simple algorithm to analyze your period history and predict future cycles:

1. You mark days when you experience bleeding on the calendar
2. The app groups consecutive days into period ranges
3. It calculates your average cycle length (time between period starts)
4. It determines your average period duration
5. Based on your history, it predicts when your next period will likely occur

All this data is stored locally using SharedPreferences, ensuring your personal health information stays private.

## Dependencies

- [flutter](https://flutter.dev/) - UI framework
- [shared_preferences](https://pub.dev/packages/shared_preferences) - Local data storage

## Contributing

Contributions are welcome! Feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
