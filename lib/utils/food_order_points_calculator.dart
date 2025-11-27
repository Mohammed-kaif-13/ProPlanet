import '../models/order_model.dart';
import '../models/food_item_model.dart';

/// Utility class for calculating points and environmental impact for food orders
class FoodOrderPointsCalculator {
  /// Calculate points earned/lost for an order based on checkout options
  static int calculateOrderPoints(List<OrderItem> items) {
    int totalPoints = 0;

    for (var item in items) {
      for (var option in item.selectedOptions) {
        // If option is NOT selected (eco-friendly choice) - earn points
        if (!option.isSelected && option.isHarmful) {
          // Find the original checkout option to get points reward
          // This would typically come from the FoodItem
          // For now, we'll use a default calculation
          totalPoints += _getPointsRewardForOption(option);
        }
        // If option IS selected (plastic choice) - lose points (if penalty enabled)
        else if (option.isSelected && option.isHarmful) {
          totalPoints -= _getPointsPenaltyForOption(option);
        }
      }
    }

    return totalPoints;
  }

  /// Calculate points based on checkout options from FoodItem
  static int calculatePointsFromFoodItem(
    FoodItem foodItem,
    List<SelectedCheckoutOption> selectedOptions,
  ) {
    int totalPoints = 0;

    for (var checkoutOption in foodItem.checkoutOptions) {
      final selectedOption = selectedOptions.firstWhere(
        (opt) => opt.optionId == checkoutOption.id,
        orElse: () => SelectedCheckoutOption(
          optionId: checkoutOption.id,
          optionName: checkoutOption.name,
          optionType: checkoutOption.type,
          environmentalImpact: checkoutOption.environmentalImpact,
          isSelected: false,
        ),
      );

      // PLASTIC OPTIONS (Harmful to environment)
      if (checkoutOption.isHarmful) {
        // If NOT selected (user declined plastic) → EARN points (reward for eco-friendly choice)
        if (!selectedOption.isSelected) {
          totalPoints += checkoutOption.pointsReward;
        }
        // If IS selected (user chose plastic) → LOSE points (penalty for harmful choice)
        else if (selectedOption.isSelected) {
          totalPoints -= (checkoutOption.pointsPenalty ?? 0);
        }
      }
      // PAPER/ECO-FRIENDLY OPTIONS (Good for environment)
      else if (checkoutOption.isEcoFriendly) {
        // If SELECTED (user chose eco-friendly) → EARN points (reward for good choice)
        if (selectedOption.isSelected) {
          totalPoints += checkoutOption.pointsReward;
        }
        // If NOT selected (user declined eco-friendly) → No points change (neutral)
      }
    }

    return totalPoints;
  }

  /// Calculate environmental impact metrics
  static Map<String, double> calculateEnvironmentalImpact(List<OrderItem> items) {
    double plasticWasteAvoided = 0.0; // in grams
    double co2Saved = 0.0; // in kg
    int plasticItemsAvoided = 0;

    for (var item in items) {
      for (var option in item.selectedOptions) {
        if (!option.isSelected && option.isHarmful) {
          // User declined plastic - calculate environmental benefit
          final impact = _getEnvironmentalImpact(option);
          plasticWasteAvoided += impact['plasticWaste'] ?? 0.0;
          co2Saved += impact['co2'] ?? 0.0;
          plasticItemsAvoided++;
        }
      }
    }

    return {
      'plasticWasteAvoided': plasticWasteAvoided,
      'co2Saved': co2Saved,
      'treesEquivalent': co2Saved / 0.02, // 1 tree = 0.02 kg CO2
      'plasticItemsAvoided': plasticItemsAvoided.toDouble(),
    };
  }

  /// Get points reward for a specific option
  static int _getPointsRewardForOption(SelectedCheckoutOption option) {
    // Default points based on option type and impact
    switch (option.optionName.toLowerCase()) {
      case 'cutlery':
        return 10;
      case 'plastic cover':
        return 15;
      case 'plastic box':
        return 20;
      default:
        return option.environmentalImpact == 'high' ? 15 : 5;
    }
  }

  /// Get points penalty for a specific option
  static int _getPointsPenaltyForOption(SelectedCheckoutOption option) {
    // Default penalty (can be customized per option)
    if (option.environmentalImpact == 'high') {
      return 5; // Small penalty to discourage but not punish heavily
    }
    return 0;
  }

  /// Get environmental impact metrics for a specific option
  static Map<String, double> _getEnvironmentalImpact(
    SelectedCheckoutOption option,
  ) {
    switch (option.optionName.toLowerCase()) {
      case 'cutlery':
        return {
          'plasticWaste': 15.0, // grams
          'co2': 0.05, // kg CO2
        };
      case 'plastic cover':
        return {
          'plasticWaste': 10.0,
          'co2': 0.03,
        };
      case 'plastic box':
        return {
          'plasticWaste': 25.0,
          'co2': 0.08,
        };
      default:
        return {
          'plasticWaste': 12.0,
          'co2': 0.04,
        };
    }
  }

  /// Calculate breakdown of points for display
  /// This version works with OrderItems that don't have the original CheckoutOption
  static Map<String, dynamic> calculatePointsBreakdown(List<OrderItem> items) {
    int pointsEarned = 0;
    int pointsLost = 0;
    List<String> ecoFriendlyChoices = [];
    List<String> plasticChoices = [];

    for (var item in items) {
      for (var selectedOption in item.selectedOptions) {
        // PLASTIC OPTIONS (Harmful to environment)
        if (selectedOption.isHarmful) {
          // If NOT selected (user declined plastic) → EARN points (reward for eco-friendly choice)
          if (!selectedOption.isSelected) {
            final reward = _getPointsRewardForHarmfulOption(selectedOption);
            pointsEarned += reward;
            ecoFriendlyChoices.add(
              'Declined ${selectedOption.optionName} (+$reward pts)',
            );
          }
          // If SELECTED (user chose plastic) → LOSE points (penalty for harmful choice)
          else if (selectedOption.isSelected) {
            final penalty = _getPointsPenaltyForOption(selectedOption);
            if (penalty > 0) {
              pointsLost += penalty;
              plasticChoices.add(
                'Selected ${selectedOption.optionName} (-$penalty pts)',
              );
            } else {
              plasticChoices.add('Selected ${selectedOption.optionName}');
            }
          }
        }
        // PAPER/ECO-FRIENDLY OPTIONS (Good for environment)
        else if (selectedOption.optionType == 'paper' || selectedOption.optionType == 'eco-friendly') {
          // If SELECTED (user chose eco-friendly) → EARN points (reward for good choice)
          if (selectedOption.isSelected) {
            final reward = _getPointsRewardForEcoFriendlyOption(selectedOption);
            if (reward > 0) {
              pointsEarned += reward;
              ecoFriendlyChoices.add(
                'Selected ${selectedOption.optionName} (+$reward pts)',
              );
            }
          }
          // If NOT selected (user declined eco-friendly) → No points change (neutral)
          // We don't penalize for not selecting eco-friendly options
        }
      }
    }

    return {
      'pointsEarned': pointsEarned,
      'pointsLost': pointsLost,
      'netPoints': pointsEarned - pointsLost,
      'ecoFriendlyChoices': ecoFriendlyChoices,
      'plasticChoices': plasticChoices,
    };
  }

  /// Get points reward for declining harmful (plastic) options
  static int _getPointsRewardForHarmfulOption(SelectedCheckoutOption option) {
    // Default points based on option type and impact
    final name = option.optionName.toLowerCase();
    if (name == 'cutlery') {
      return 10;
    } else if (name.contains('plastic cover') || name.contains('plasticcover')) {
      return 15;
    } else if (name.contains('plastic box')) {
      return 20;
    } else {
      return option.environmentalImpact == 'high' ? 15 : 10;
    }
  }

  /// Get points reward for selecting eco-friendly (paper/eco-friendly) options
  static int _getPointsRewardForEcoFriendlyOption(SelectedCheckoutOption option) {
    // Reward for choosing eco-friendly options
    final name = option.optionName.toLowerCase();
    if (name.contains('paper cover') || name.contains('papercover')) {
      return 5;
    } else if (name.contains('paper box')) {
      return 8;
    } else if (name.contains('eco-friendly') || name.contains('ecofriendly')) {
      return 10;
    } else {
      // Paper and eco-friendly types get points
      if (option.optionType == 'paper' || option.optionType == 'eco-friendly') {
        return option.environmentalImpact == 'low' ? 5 : 8;
      }
      return 0;
    }
  }

  /// Get environmental warning message for plastic selections
  static String getEnvironmentalWarningMessage(FoodOrder order) {
    final plasticItems = order.items
        .expand((item) => item.selectedOptions)
        .where((opt) => opt.isSelected && opt.isHarmful)
        .toList();

    if (plasticItems.isEmpty) {
      return '';
    }

    return '''
⚠️ Environmental Impact Alert!

You selected ${plasticItems.length} plastic item(s) in your order:
${plasticItems.map((item) => '• ${item.optionName}').join('\n')}

🌍 Did you know?
• Plastic takes 450+ years to decompose
• Millions of marine animals die from plastic pollution annually
• Plastic production contributes to climate change

💚 Next time, consider eco-friendly alternatives to earn points and protect our planet!
    ''';
  }

  /// Get eco-friendly reward message
  static String getEcoFriendlyRewardMessage(int points) {
    return '''
🌱 Great Choice!

You declined plastic items and earned +$points points! 
Your eco-friendly choice helps protect our planet!

Keep making sustainable choices to earn more points and level up! 🎉
    ''';
  }
}

