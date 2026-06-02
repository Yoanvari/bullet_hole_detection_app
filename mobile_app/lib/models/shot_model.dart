/// Data model representing a single shot record.
class ShotModel {
  final int id;
  final String imagePath;
  final int score;

  const ShotModel({
    required this.id,
    required this.imagePath,
    required this.score,
  });
}
