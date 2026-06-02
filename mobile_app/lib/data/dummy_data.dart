import '../models/shot_model.dart';
import '../models/session_model.dart';

/// 3 dummy training sessions, each with its own shots.
final List<SessionModel> dummySessions = [
  SessionModel(
    id: 'session-1',
    date: DateTime(2026, 5, 9),
    shots: const [
      ShotModel(id: 1, imagePath: 'assets/images/shot_1.jpg', score: 9),
      ShotModel(id: 2, imagePath: 'assets/images/shot_2.jpg', score: 8),
      ShotModel(id: 3, imagePath: 'assets/images/shot_3.jpg', score: 10),
      ShotModel(id: 4, imagePath: 'assets/images/shot_4.jpg', score: 7),
    ],
  ),
  SessionModel(
    id: 'session-2',
    date: DateTime(2026, 5, 7),
    shots: const [
      ShotModel(id: 5, imagePath: 'assets/images/shot_5.jpg', score: 9),
      ShotModel(id: 6, imagePath: 'assets/images/shot_6.jpg', score: 8),
      ShotModel(id: 7, imagePath: 'assets/images/shot_7.jpg', score: 10),
    ],
  ),
  SessionModel(
    id: 'session-3',
    date: DateTime(2026, 5, 5),
    shots: const [
      ShotModel(id: 8, imagePath: 'assets/images/shot_8.jpg', score: 6),
      ShotModel(id: 9, imagePath: 'assets/images/shot_9.jpg', score: 9),
      ShotModel(id: 10, imagePath: 'assets/images/shot_10.jpg', score: 9),
    ],
  ),
];

/// Current live shot data.
final ShotModel dummyLiveShot = const ShotModel(
  id: 11,
  imagePath: 'assets/images/live_shot.jpg',
  score: 9,
);

/// Global totals across all sessions
int get totalShots =>
    dummySessions.fold(0, (sum, s) => sum + s.totalShots);
int get totalScore =>
    dummySessions.fold(0, (sum, s) => sum + s.totalScore);
