# ProPlanet 

ProPlanet is an eco-friendly mobile application built with Flutter that helps users track their environmental activities, earn points, and make a positive impact on our planet.

## Features

###  Core Functionality
- **Activity Tracking**: Track various eco-friendly activities across multiple categories
- **Points System**: Earn points for completing environmental activities
- **Real-time Notifications**: Get reminders and achievements notifications
- **Progress Monitoring**: Track your environmental impact and progress
- **Leaderboard**: Compete with other eco-warriors globally
- **Achievements & Badges**: Unlock badges and achievements as you progress

###  User Experience
- **Modern UI**: Beautiful, intuitive interface with smooth animations
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Onboarding**: Smooth onboarding experience for new users
- **Profile Management**: Customize your profile and settings
- **Statistics**: Detailed statistics and charts showing your progress

###  Activity Categories
- **Transport**: Walking, biking, public transport, carpooling
- **Energy**: LED bulbs, unplugging devices, thermostat adjustments
- **Waste**: Composting, recycling, reusable bags
- **Water**: Shorter showers, fixing leaks, rainwater collection
- **Food**: Plant-based meals, local produce, reducing food waste
- **Shopping**: Sustainable shopping practices
- **Nature**: Tree planting, litter cleanup, wildlife habitat creation

###  Smart Notifications
- Daily activity reminders
- Achievement celebrations
- Milestone notifications
- Weekly eco-tips
- Customizable notification settings

## Screenshots

[Screenshots would go here in a real project]

## Installation

### Prerequisites
- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Setup
1. Clone the repository:
`ash
git clone https://github.com/Mohammed-kaif-13/ProPlanet.git
cd proplanet
`

2. Install dependencies:
`ash
flutter pub get
`

3. Run the app:
`ash
flutter run
`

## Project Structure

`
lib/
 main.dart                 # App entry point
 models/                   # Data models
    user_model.dart
    activity_model.dart
    notification_model.dart
 providers/                # State management
    user_provider.dart
    activity_provider.dart
    notification_provider.dart
 screens/                  # UI screens
    splash_screen.dart
    onboarding_screen.dart
    home_screen.dart
    activities_screen.dart
    leaderboard_screen.dart
    profile_screen.dart
 widgets/                  # Reusable widgets
    activity_card.dart
    stats_card.dart
    quick_action_button.dart
 services/                 # Services
    notification_service.dart
 utils/                    # Utilities
     app_theme.dart
`

## Dependencies

### Core Dependencies
- **flutter**: UI framework
- **provider**: State management
- **shared_preferences**: Local storage
- **sqflite**: Local database

### UI & Animation
- **flutter_animate**: Smooth animations
- **animated_bottom_navigation_bar**: Animated navigation
- **lottie**: Lottie animations
- **shimmer**: Loading effects
- **fl_chart**: Charts and graphs

### Notifications
- **flutter_local_notifications**: Local notifications

### Utilities
- **http** & **dio**: HTTP requests
- **intl**: Internationalization
- **font_awesome_flutter**: Icons
- **permission_handler**: Permissions
- **geolocator** & **geocoding**: Location services

## Key Features Implementation

### Points System
- Users earn points by completing eco-friendly activities
- Points contribute to user level progression
- Different activities have different point values based on impact

### Notification System
- Smart scheduling of daily reminders
- Achievement and milestone celebrations
- Customizable notification preferences
- Real-time notifications for completed activities

### Progress Tracking
- Visual progress indicators for level advancement
- Category-wise point distribution
- Activity completion statistics
- Environmental impact calculations

### Gamification
- Level progression system (1-10 levels)
- Badge system for achievements
- Streak tracking for consecutive days
- Leaderboard for competitive motivation

## Environmental Impact Calculations

The app provides estimated environmental impact based on completed activities:
- **CO2 Saved**: 0.5 kg per point earned
- **Water Saved**: 2.3 liters per point earned
- **Energy Saved**: 1.2 kWh per point earned
- **Tree Equivalent**: 1 tree per 50 points earned

## Contributing

1. Fork the repository
2. Create your feature branch (git checkout -b feature/AmazingFeature)
3. Commit your changes (git commit -m 'Add some AmazingFeature')
4. Push to the branch (git push origin feature/AmazingFeature)
5. Open a Pull Request

## Future Enhancements

- [ ] Social features (friends, challenges)
- [ ] AI-powered activity suggestions
- [ ] Integration with fitness trackers
- [ ] Carbon footprint calculator
- [ ] Community challenges
- [ ] Reward partnerships with eco-friendly brands
- [ ] Photo verification for activities
- [ ] Location-based eco-tips
- [ ] Multi-language support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Icons by FontAwesome
- Animations by Lottie
- Charts by FL Chart
- Notifications by Flutter Local Notifications

## Contact

For questions or support, please reach out:
- Email: mohammedkaif1328@gmail.com
- GitHub: https://github.com/Mohammed-kaif-13

---

**Together, let's make every action count for our planet! **
