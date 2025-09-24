import 'dart:math';
import '../models/activity_model.dart';

class DailyActivityService {
  static final DailyActivityService _instance =
      DailyActivityService._internal();
  factory DailyActivityService() => _instance;
  DailyActivityService._internal();

  final Random _random = Random();

  // Generate daily activities for the user with intelligent suggestions
  List<EcoActivity> generateDailyActivities({
    int count = 5,
    List<ActivityCategory>? preferredCategories,
    String difficulty = 'mixed',
    List<String>? completedToday,
    List<String>? completedThisWeek,
    int userLevel = 1,
    String? weatherCondition,
  }) {
    final allActivities = getAllActivities();

    // Start with all activities and apply intelligent filters
    List<EcoActivity> filteredActivities = allActivities;

    // 1. Remove activities completed today
    if (completedToday != null && completedToday.isNotEmpty) {
      filteredActivities = filteredActivities
          .where((activity) => !completedToday.contains(activity.id))
          .toList();
    }

    // 2. Apply preferred categories filter
    if (preferredCategories != null && preferredCategories.isNotEmpty) {
      filteredActivities = filteredActivities
          .where(
            (activity) => preferredCategories.contains(activity.category),
          )
          .toList();
    }

    // 3. Apply difficulty filter with level-based intelligence
    if (difficulty != 'mixed') {
      filteredActivities = filteredActivities
          .where((activity) => activity.difficulty == difficulty)
          .toList();
    } else {
      // Smart difficulty based on user level
      filteredActivities = _getLevelAppropriateActivities(
        filteredActivities,
        userLevel,
      );
    }

    // 4. Weather-based filtering
    if (weatherCondition != null) {
      filteredActivities = _filterByWeather(
        filteredActivities,
        weatherCondition,
      );
    }

    // 5. Variety boost - reduce recently completed activities
    if (completedThisWeek != null && completedThisWeek.isNotEmpty) {
      filteredActivities = _boostVariety(filteredActivities, completedThisWeek);
    }

    // Shuffle and select random activities
    filteredActivities.shuffle(_random);

    // Select activities ensuring variety
    final selectedActivities = <EcoActivity>[];
    final usedCategories = <ActivityCategory>{};

    // First, try to get one activity from each category
    for (final category in ActivityCategory.values) {
      if (selectedActivities.length >= count) break;

      final categoryActivities = filteredActivities
          .where((activity) => activity.category == category)
          .toList();

      if (categoryActivities.isNotEmpty) {
        selectedActivities.add(categoryActivities.first);
        usedCategories.add(category);
      }
    }

    // Fill remaining slots with random activities
    while (selectedActivities.length < count && filteredActivities.isNotEmpty) {
      final remainingActivities = filteredActivities
          .where((activity) => !selectedActivities.contains(activity))
          .toList();

      if (remainingActivities.isNotEmpty) {
        selectedActivities.add(remainingActivities.first);
      } else {
        break;
      }
    }

    return selectedActivities;
  }

  // Get activities for specific time of day
  List<EcoActivity> getActivitiesForTimeOfDay(TimeOfDay timeOfDay) {
    final allActivities = getAllActivities();

    switch (timeOfDay) {
      case TimeOfDay.morning:
        return allActivities
            .where((activity) => _isMorningActivity(activity))
            .toList();
      case TimeOfDay.afternoon:
        return allActivities
            .where((activity) => _isAfternoonActivity(activity))
            .toList();
      case TimeOfDay.evening:
        return allActivities
            .where((activity) => _isEveningActivity(activity))
            .toList();
      case TimeOfDay.night:
        return allActivities
            .where((activity) => _isNightActivity(activity))
            .toList();
    }
  }

  // Get seasonal activities
  List<EcoActivity> getSeasonalActivities() {
    final month = DateTime.now().month;
    final allActivities = getAllActivities();

    // Define seasonal preferences
    if (month >= 3 && month <= 5) {
      // Spring
      return allActivities
          .where((activity) => _isSpringActivity(activity))
          .toList();
    } else if (month >= 6 && month <= 8) {
      // Summer
      return allActivities
          .where((activity) => _isSummerActivity(activity))
          .toList();
    } else if (month >= 9 && month <= 11) {
      // Autumn
      return allActivities
          .where((activity) => _isAutumnActivity(activity))
          .toList();
    } else {
      // Winter
      return allActivities
          .where((activity) => _isWinterActivity(activity))
          .toList();
    }
  }

  // Get challenge activities (higher points, more difficult)
  List<EcoActivity> getChallengeActivities() {
    return getAllActivities()
        .where(
          (activity) => activity.points >= 25 && activity.difficulty != 'easy',
        )
        .toList();
  }

  // Get quick activities (low time commitment)
  List<EcoActivity> getQuickActivities() {
    return getAllActivities()
        .where((activity) => activity.estimatedTime.inMinutes <= 15)
        .toList();
  }

  // Get all available activities
  List<EcoActivity> getAllActivities() {
    return [
      // Transport Activities
      EcoActivity(
        id: 'transport_1',
        title: 'Walk or Bike Instead of Drive',
        description:
            'Choose walking or biking for short trips instead of using a car',
        category: ActivityCategory.transport,
        points: 20,
        icon: '🚲',
        estimatedTime: const Duration(minutes: 30),
        tags: ['transport', 'health', 'carbon-reduction'],
        difficulty: 'easy',
        instructions:
            'For trips under 2 miles, try walking or biking instead of driving.',
      ),
      EcoActivity(
        id: 'transport_2',
        title: 'Use Public Transportation',
        description:
            'Take the bus, train, or other public transport instead of driving',
        category: ActivityCategory.transport,
        points: 15,
        icon: '🚌',
        estimatedTime: const Duration(minutes: 45),
        tags: ['transport', 'community', 'carbon-reduction'],
        difficulty: 'easy',
        instructions: 'Plan your route using public transportation apps.',
      ),
      EcoActivity(
        id: 'transport_3',
        title: 'Carpool or Rideshare',
        description:
            'Share a ride with others to reduce individual carbon footprint',
        category: ActivityCategory.transport,
        points: 12,
        icon: '🚗',
        estimatedTime: const Duration(minutes: 60),
        tags: ['transport', 'social', 'carbon-reduction'],
        difficulty: 'easy',
        instructions: 'Coordinate with friends, family, or use rideshare apps.',
      ),
      EcoActivity(
        id: 'transport_4',
        title: 'Plan Efficient Routes',
        description: 'Combine multiple errands into one trip to reduce driving',
        category: ActivityCategory.transport,
        points: 10,
        icon: '🗺️',
        estimatedTime: const Duration(minutes: 15),
        tags: ['transport', 'planning', 'efficiency'],
        difficulty: 'easy',
        instructions: 'Plan your route to visit multiple places in one trip.',
      ),

      // Energy Activities
      EcoActivity(
        id: 'energy_1',
        title: 'Switch to LED Bulbs',
        description:
            'Replace traditional bulbs with energy-efficient LED bulbs',
        category: ActivityCategory.energy,
        points: 25,
        icon: '💡',
        estimatedTime: const Duration(minutes: 15),
        tags: ['energy', 'home', 'savings'],
        difficulty: 'easy',
        instructions:
            'Replace one or more incandescent bulbs with LED alternatives.',
      ),
      EcoActivity(
        id: 'energy_2',
        title: 'Unplug Electronics When Not in Use',
        description: 'Reduce phantom energy consumption by unplugging devices',
        category: ActivityCategory.energy,
        points: 10,
        icon: '🔌',
        estimatedTime: const Duration(minutes: 10),
        tags: ['energy', 'home', 'savings'],
        difficulty: 'easy',
        instructions:
            'Unplug chargers, TVs, and other electronics when not actively using them.',
      ),
      EcoActivity(
        id: 'energy_3',
        title: 'Adjust Thermostat by 2 Degrees',
        description:
            'Lower heating or raise cooling by 2 degrees to save energy',
        category: ActivityCategory.energy,
        points: 15,
        icon: '🌡️',
        estimatedTime: const Duration(minutes: 2),
        tags: ['energy', 'home', 'comfort'],
        difficulty: 'easy',
        instructions:
            'Adjust your thermostat 2 degrees lower in winter, higher in summer.',
      ),
      EcoActivity(
        id: 'energy_4',
        title: 'Use Natural Light',
        description:
            'Open curtains and blinds to use natural light during the day',
        category: ActivityCategory.energy,
        points: 8,
        icon: '☀️',
        estimatedTime: const Duration(minutes: 5),
        tags: ['energy', 'natural', 'lighting'],
        difficulty: 'easy',
        instructions:
            'Open curtains and turn off artificial lights when possible.',
      ),
      EcoActivity(
        id: 'energy_5',
        title: 'Install Smart Power Strips',
        description: 'Use smart power strips to automatically turn off devices',
        category: ActivityCategory.energy,
        points: 30,
        icon: '🔋',
        estimatedTime: const Duration(minutes: 30),
        tags: ['energy', 'smart', 'automation'],
        difficulty: 'medium',
        instructions:
            'Install smart power strips that automatically turn off devices when not in use.',
      ),

      // Waste Activities
      EcoActivity(
        id: 'waste_1',
        title: 'Start Composting',
        description: 'Begin composting organic waste to reduce landfill impact',
        category: ActivityCategory.waste,
        points: 30,
        icon: '🍃',
        estimatedTime: const Duration(minutes: 20),
        tags: ['waste', 'composting', 'gardening'],
        difficulty: 'medium',
        instructions:
            'Set up a compost bin and start collecting organic waste.',
      ),
      EcoActivity(
        id: 'waste_2',
        title: 'Use Reusable Bags for Shopping',
        description: 'Bring reusable bags instead of using plastic bags',
        category: ActivityCategory.waste,
        points: 8,
        icon: '🛍️',
        estimatedTime: const Duration(minutes: 5),
        tags: ['waste', 'shopping', 'plastic-reduction'],
        difficulty: 'easy',
        instructions:
            'Remember to bring reusable bags for your next shopping trip.',
      ),
      EcoActivity(
        id: 'waste_3',
        title: 'Recycle Properly',
        description: 'Sort and recycle materials according to local guidelines',
        category: ActivityCategory.waste,
        points: 12,
        icon: '♻️',
        estimatedTime: const Duration(minutes: 15),
        tags: ['waste', 'recycling', 'sorting'],
        difficulty: 'easy',
        instructions:
            'Check local recycling guidelines and sort materials correctly.',
      ),
      EcoActivity(
        id: 'waste_4',
        title: 'Avoid Single-Use Items',
        description: 'Choose reusable alternatives to single-use products',
        category: ActivityCategory.waste,
        points: 15,
        icon: '🥤',
        estimatedTime: const Duration(minutes: 10),
        tags: ['waste', 'reusable', 'reduction'],
        difficulty: 'easy',
        instructions: 'Use reusable water bottles, coffee cups, and utensils.',
      ),
      EcoActivity(
        id: 'waste_5',
        title: 'Buy in Bulk',
        description: 'Purchase items in bulk to reduce packaging waste',
        category: ActivityCategory.waste,
        points: 18,
        icon: '📦',
        estimatedTime: const Duration(minutes: 45),
        tags: ['waste', 'shopping', 'bulk'],
        difficulty: 'easy',
        instructions: 'Shop at bulk stores and bring your own containers.',
      ),

      // Water Activities
      EcoActivity(
        id: 'water_1',
        title: 'Take Shorter Showers',
        description: 'Reduce shower time by 2-3 minutes to conserve water',
        category: ActivityCategory.water,
        points: 15,
        icon: '🚿',
        estimatedTime: const Duration(minutes: 10),
        tags: ['water', 'conservation', 'daily-habit'],
        difficulty: 'easy',
        instructions: 'Set a timer and aim to reduce your shower time.',
      ),
      EcoActivity(
        id: 'water_2',
        title: 'Fix Leaky Faucets',
        description: 'Repair dripping faucets to prevent water waste',
        category: ActivityCategory.water,
        points: 20,
        icon: '🔧',
        estimatedTime: const Duration(minutes: 30),
        tags: ['water', 'maintenance', 'home'],
        difficulty: 'medium',
        instructions: 'Check all faucets and repair any leaks you find.',
      ),
      EcoActivity(
        id: 'water_3',
        title: 'Collect Rainwater',
        description: 'Set up a rain collection system for garden watering',
        category: ActivityCategory.water,
        points: 25,
        icon: '☔',
        estimatedTime: const Duration(minutes: 45),
        tags: ['water', 'gardening', 'conservation'],
        difficulty: 'medium',
        instructions: 'Install a rain barrel or collection system.',
      ),
      EcoActivity(
        id: 'water_4',
        title: 'Use Water-Saving Appliances',
        description: 'Install low-flow showerheads and faucet aerators',
        category: ActivityCategory.water,
        points: 22,
        icon: '💧',
        estimatedTime: const Duration(minutes: 20),
        tags: ['water', 'appliances', 'efficiency'],
        difficulty: 'medium',
        instructions: 'Install water-saving devices in your home.',
      ),
      EcoActivity(
        id: 'water_5',
        title: 'Water Plants in the Morning',
        description: 'Water your garden early to reduce evaporation',
        category: ActivityCategory.water,
        points: 12,
        icon: '🌱',
        estimatedTime: const Duration(minutes: 15),
        tags: ['water', 'gardening', 'efficiency'],
        difficulty: 'easy',
        instructions:
            'Water your plants in the early morning for better absorption.',
      ),

      // Food Activities
      EcoActivity(
        id: 'food_1',
        title: 'Eat a Plant-Based Meal',
        description:
            'Choose a vegetarian or vegan meal to reduce carbon footprint',
        category: ActivityCategory.food,
        points: 18,
        icon: '🥗',
        estimatedTime: const Duration(minutes: 45),
        tags: ['food', 'plant-based', 'health'],
        difficulty: 'easy',
        instructions:
            'Try a delicious plant-based recipe for one of your meals today.',
      ),
      EcoActivity(
        id: 'food_2',
        title: 'Buy Local Produce',
        description:
            'Purchase fruits and vegetables from local farmers or markets',
        category: ActivityCategory.food,
        points: 22,
        icon: '🥕',
        estimatedTime: const Duration(minutes: 60),
        tags: ['food', 'local', 'community'],
        difficulty: 'easy',
        instructions: 'Visit a farmers market or buy locally-grown produce.',
      ),
      EcoActivity(
        id: 'food_3',
        title: 'Reduce Food Waste',
        description: 'Plan meals and use leftovers to minimize food waste',
        category: ActivityCategory.food,
        points: 16,
        icon: '🍽️',
        estimatedTime: const Duration(minutes: 30),
        tags: ['food', 'planning', 'waste-reduction'],
        difficulty: 'easy',
        instructions:
            'Plan your meals for the week and use up leftovers creatively.',
      ),
      EcoActivity(
        id: 'food_4',
        title: 'Grow Your Own Herbs',
        description:
            'Start a small herb garden to reduce packaging and transportation',
        category: ActivityCategory.food,
        points: 28,
        icon: '🌿',
        estimatedTime: const Duration(minutes: 30),
        tags: ['food', 'gardening', 'herbs'],
        difficulty: 'easy',
        instructions: 'Plant herbs in small pots or your garden.',
      ),
      EcoActivity(
        id: 'food_5',
        title: 'Choose Seasonal Foods',
        description: 'Select fruits and vegetables that are in season locally',
        category: ActivityCategory.food,
        points: 14,
        icon: '🍎',
        estimatedTime: const Duration(minutes: 20),
        tags: ['food', 'seasonal', 'local'],
        difficulty: 'easy',
        instructions: 'Research and choose seasonal produce for your meals.',
      ),

      // Shopping Activities
      EcoActivity(
        id: 'shopping_1',
        title: 'Buy Second-Hand Items',
        description: 'Purchase used items to reduce manufacturing impact',
        category: ActivityCategory.shopping,
        points: 20,
        icon: '👕',
        estimatedTime: const Duration(minutes: 60),
        tags: ['shopping', 'second-hand', 'reuse'],
        difficulty: 'easy',
        instructions:
            'Visit thrift stores or online marketplaces for used items.',
      ),
      EcoActivity(
        id: 'shopping_2',
        title: 'Choose Eco-Friendly Products',
        description:
            'Select products with minimal packaging and eco-friendly materials',
        category: ActivityCategory.shopping,
        points: 16,
        icon: '🌿',
        estimatedTime: const Duration(minutes: 30),
        tags: ['shopping', 'eco-friendly', 'packaging'],
        difficulty: 'easy',
        instructions:
            'Look for products with eco-friendly certifications and minimal packaging.',
      ),
      EcoActivity(
        id: 'shopping_3',
        title: 'Support Local Businesses',
        description:
            'Shop at local stores instead of large chains when possible',
        category: ActivityCategory.shopping,
        points: 14,
        icon: '🏪',
        estimatedTime: const Duration(minutes: 45),
        tags: ['shopping', 'local', 'community'],
        difficulty: 'easy',
        instructions: 'Choose local businesses over large chain stores.',
      ),
      EcoActivity(
        id: 'shopping_4',
        title: 'Repair Instead of Replace',
        description: 'Fix broken items instead of throwing them away',
        category: ActivityCategory.shopping,
        points: 24,
        icon: '🔨',
        estimatedTime: const Duration(minutes: 60),
        tags: ['shopping', 'repair', 'waste-reduction'],
        difficulty: 'medium',
        instructions:
            'Learn basic repair skills or take items to repair shops.',
      ),

      // Nature Activities
      EcoActivity(
        id: 'nature_1',
        title: 'Plant a Tree or Flower',
        description: 'Plant something green to help the environment',
        category: ActivityCategory.nature,
        points: 35,
        icon: '🌳',
        estimatedTime: const Duration(minutes: 60),
        tags: ['nature', 'planting', 'carbon-absorption'],
        difficulty: 'medium',
        instructions:
            'Plant a tree, flower, or herb in your garden or a suitable location.',
      ),
      EcoActivity(
        id: 'nature_2',
        title: 'Clean Up Litter',
        description: 'Pick up trash in your neighborhood or a natural area',
        category: ActivityCategory.nature,
        points: 20,
        icon: '🗑️',
        estimatedTime: const Duration(minutes: 30),
        tags: ['nature', 'cleanup', 'community'],
        difficulty: 'easy',
        instructions: 'Spend time cleaning up litter in your local area.',
      ),
      EcoActivity(
        id: 'nature_3',
        title: 'Create Wildlife Habitat',
        description: 'Set up bird feeders, bee houses, or plant native species',
        category: ActivityCategory.nature,
        points: 28,
        icon: '🐦',
        estimatedTime: const Duration(minutes: 45),
        tags: ['nature', 'wildlife', 'habitat'],
        difficulty: 'medium',
        instructions:
            'Create a small habitat for local wildlife in your yard or balcony.',
      ),
      EcoActivity(
        id: 'nature_4',
        title: 'Start a Vegetable Garden',
        description: 'Grow your own vegetables to reduce food miles',
        category: ActivityCategory.nature,
        points: 32,
        icon: '🥬',
        estimatedTime: const Duration(minutes: 90),
        tags: ['nature', 'gardening', 'food'],
        difficulty: 'medium',
        instructions: 'Plan and start a small vegetable garden.',
      ),
      EcoActivity(
        id: 'nature_5',
        title: 'Volunteer for Environmental Causes',
        description: 'Participate in local environmental volunteer activities',
        category: ActivityCategory.nature,
        points: 40,
        icon: '🤝',
        estimatedTime: const Duration(hours: 2),
        tags: ['nature', 'volunteer', 'community'],
        difficulty: 'medium',
        instructions:
            'Join local environmental organizations or cleanup events.',
      ),
    ];
  }

  // Time-based activity filters
  bool _isMorningActivity(EcoActivity activity) {
    return activity.tags.contains('morning') ||
        activity.category == ActivityCategory.transport ||
        activity.category == ActivityCategory.energy;
  }

  bool _isAfternoonActivity(EcoActivity activity) {
    return activity.tags.contains('afternoon') ||
        activity.category == ActivityCategory.shopping ||
        activity.category == ActivityCategory.food;
  }

  bool _isEveningActivity(EcoActivity activity) {
    return activity.tags.contains('evening') ||
        activity.category == ActivityCategory.waste ||
        activity.category == ActivityCategory.water;
  }

  bool _isNightActivity(EcoActivity activity) {
    return activity.tags.contains('night') ||
        activity.category == ActivityCategory.energy;
  }

  // Seasonal activity filters
  bool _isSpringActivity(EcoActivity activity) {
    return activity.tags.contains('spring') ||
        activity.category == ActivityCategory.nature ||
        activity.category == ActivityCategory.food;
  }

  bool _isSummerActivity(EcoActivity activity) {
    return activity.tags.contains('summer') ||
        activity.category == ActivityCategory.water ||
        activity.category == ActivityCategory.nature;
  }

  bool _isAutumnActivity(EcoActivity activity) {
    return activity.tags.contains('autumn') ||
        activity.category == ActivityCategory.food ||
        activity.category == ActivityCategory.nature;
  }

  bool _isWinterActivity(EcoActivity activity) {
    return activity.tags.contains('winter') ||
        activity.category == ActivityCategory.energy ||
        activity.category == ActivityCategory.transport;
  }

  // Intelligent filtering methods
  List<EcoActivity> _getLevelAppropriateActivities(
    List<EcoActivity> activities,
    int userLevel,
  ) {
    // Level-based difficulty progression
    if (userLevel <= 2) {
      return activities
          .where((activity) => activity.difficulty == 'easy')
          .toList();
    } else if (userLevel <= 5) {
      return activities
          .where(
            (activity) =>
                activity.difficulty == 'easy' ||
                activity.difficulty == 'medium',
          )
          .toList();
    } else {
      // High level users can handle all difficulties
      return activities;
    }
  }

  List<EcoActivity> _filterByWeather(
    List<EcoActivity> activities,
    String weatherCondition,
  ) {
    switch (weatherCondition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return activities
            .where(
              (activity) =>
                  activity.tags.contains('outdoor') ||
                  activity.category == ActivityCategory.nature ||
                  activity.category == ActivityCategory.transport,
            )
            .toList();
      case 'rainy':
      case 'stormy':
        return activities
            .where(
              (activity) =>
                  activity.tags.contains('indoor') ||
                  activity.category == ActivityCategory.energy ||
                  activity.category == ActivityCategory.waste,
            )
            .toList();
      case 'cold':
      case 'snowy':
        return activities
            .where(
              (activity) =>
                  activity.tags.contains('indoor') ||
                  activity.category == ActivityCategory.energy ||
                  activity.category == ActivityCategory.food,
            )
            .toList();
      default:
        return activities; // No weather filtering
    }
  }

  List<EcoActivity> _boostVariety(
    List<EcoActivity> activities,
    List<String> completedThisWeek,
  ) {
    // Give lower priority to recently completed activities
    final weightedActivities = <EcoActivity>[];

    for (final activity in activities) {
      final recentCompletions =
          completedThisWeek.where((id) => id == activity.id).length;
      final weight = recentCompletions > 0
          ? 0.3
          : 1.0; // Reduce weight for recent activities

      // Add activity multiple times based on weight
      for (int i = 0; i < (weight * 10).round(); i++) {
        weightedActivities.add(activity);
      }
    }

    return weightedActivities;
  }

  // Get personalized recommendations based on user behavior
  List<EcoActivity> getPersonalizedRecommendations({
    required List<String> completedActivities,
    required List<ActivityCategory> favoriteCategories,
    required int userLevel,
    String? weatherCondition,
    int count = 3,
  }) {
    final allActivities = getAllActivities();

    // Calculate category preferences based on completion history
    final categoryScores = <ActivityCategory, int>{};
    for (final category in ActivityCategory.values) {
      categoryScores[category] = 0;
    }

    // Score categories based on completed activities
    for (final activityId in completedActivities) {
      final activity = allActivities.firstWhere((a) => a.id == activityId);
      categoryScores[activity.category] =
          (categoryScores[activity.category] ?? 0) + 1;
    }

    // Find under-explored categories
    final underExploredCategories = categoryScores.entries
        .where((entry) => entry.value < 3)
        .map((entry) => entry.key)
        .toList();

    // Generate recommendations with variety
    List<EcoActivity> recommendations = [];

    // 1. Add activities from under-explored categories
    if (underExploredCategories.isNotEmpty) {
      final underExploredActivities = allActivities
          .where(
            (activity) => underExploredCategories.contains(activity.category),
          )
          .where((activity) => !completedActivities.contains(activity.id))
          .toList();
      recommendations.addAll(underExploredActivities.take(2));
    }

    // 2. Add activities from favorite categories
    if (favoriteCategories.isNotEmpty) {
      final favoriteActivities = allActivities
          .where(
            (activity) => favoriteCategories.contains(activity.category),
          )
          .where((activity) => !completedActivities.contains(activity.id))
          .toList();
      recommendations.addAll(favoriteActivities.take(2));
    }

    // 3. Add weather-appropriate activities
    if (weatherCondition != null) {
      final weatherActivities =
          _filterByWeather(allActivities, weatherCondition)
              .where((activity) => !completedActivities.contains(activity.id))
              .toList();
      recommendations.addAll(weatherActivities.take(1));
    }

    // Remove duplicates and return
    final uniqueRecommendations = <String, EcoActivity>{};
    for (final activity in recommendations) {
      uniqueRecommendations[activity.id] = activity;
    }

    return uniqueRecommendations.values.take(count).toList();
  }

  // Get daily challenge activities (higher points, special rewards)
  List<EcoActivity> getDailyChallengeActivities() {
    return getAllActivities()
        .where((activity) => activity.points >= 30)
        .where((activity) => activity.difficulty == 'hard')
        .toList();
  }

  // Get streak-building activities (quick wins to maintain streaks)
  List<EcoActivity> getStreakBuildingActivities() {
    return getAllActivities()
        .where((activity) => activity.estimatedTime.inMinutes <= 10)
        .where((activity) => activity.points >= 10)
        .toList();
  }
}

enum TimeOfDay { morning, afternoon, evening, night }
