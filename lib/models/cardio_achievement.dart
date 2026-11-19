enum CardioAchievementType { distance, pace, duration, speed }

class CardioAchievementMetric {
  const CardioAchievementMetric({
    required this.type,
    required this.previousValue,
    required this.newValue,
  });

  final CardioAchievementType type;
  final double previousValue;
  final double newValue;
}

class CardioAchievement {
  const CardioAchievement(this.metrics);

  final List<CardioAchievementMetric> metrics;

  CardioAchievementMetric get primary => metrics.first;
  int get count => metrics.length;
}
