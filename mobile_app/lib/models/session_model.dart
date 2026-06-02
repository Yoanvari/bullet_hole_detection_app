import 'shot_model.dart';

/// A training session grouped by date, containing multiple shots.
class SessionModel {
  final String id;
  final DateTime date;
  final List<ShotModel> shots;

  const SessionModel({
    required this.id,
    required this.date,
    required this.shots,
  });

  int get totalShots => shots.length;
  int get totalScore => shots.fold(0, (sum, s) => sum + s.score);
}
