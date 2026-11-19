import '../models/cardio_activity.dart';
import '../models/user_profile.dart';

abstract final class CardioAssets {
  static String group(IllustrationStyle style) =>
      'assets/images/cardio/groups/${style.assetFolder}.webp';

  static String execution(CardioKind kind, IllustrationStyle style) {
    final filename = switch (kind) {
      CardioKind.outdoorRun => 'outdoor_run.webp',
      CardioKind.treadmill => 'treadmill.webp',
      CardioKind.walk => 'walk.webp',
      CardioKind.cycling => 'cycling.webp',
      CardioKind.stationaryBike => 'stationary_bike.webp',
      CardioKind.elliptical => 'elliptical.webp',
      CardioKind.stairClimber => 'stair_climber.webp',
      CardioKind.rowing => 'rowing.webp',
      CardioKind.jumpRope => 'jump_rope.webp',
    };
    return 'assets/images/cardio/${style.assetFolder}/$filename';
  }

  /// Independent full-body, front/rear activation anatomy for each cardio kind
  /// and profile. Never reuse a tinted execution photograph.
  static String activation(CardioKind kind, IllustrationStyle style) {
    final filename = switch (kind) {
      CardioKind.outdoorRun => 'outdoor_run.webp',
      CardioKind.treadmill => 'treadmill.webp',
      CardioKind.walk => 'walk.webp',
      CardioKind.cycling => 'cycling.webp',
      CardioKind.stationaryBike => 'stationary_bike.webp',
      CardioKind.elliptical => 'elliptical.webp',
      CardioKind.stairClimber => 'stair_climber.webp',
      CardioKind.rowing => 'rowing.webp',
      CardioKind.jumpRope => 'jump_rope.webp',
    };
    return 'assets/images/cardio_activation/${style.assetFolder}/$filename';
  }
}
