import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/session_model.dart';
import '../models/shot_model.dart';

class HistoryDetailScreen extends StatelessWidget {
  final SessionModel session;

  const HistoryDetailScreen({Key? key, required this.session}) : super(key: key);

  String _formatDate(DateTime d) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(session.date)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Session Summary ─────────────────────────
          _SessionSummary(session: session),

          // ── Shot List ───────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: session.shots.length,
              itemBuilder: (context, index) {
                return _ShotCard(
                  shot: session.shots[index],
                  displayIndex: index + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Session Summary Header
// ─────────────────────────────────────────────────────────
class _SessionSummary extends StatelessWidget {
  final SessionModel session;

  const _SessionSummary({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceLight, AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              icon: Icons.track_changes_rounded,
              label: 'Tembakan',
              value: '${session.totalShots}',
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.border),
          Expanded(
            child: _StatColumn(
              icon: Icons.star_rounded,
              label: 'Total Skor',
              value: '${session.totalScore}',
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.border),
          Expanded(
            child: _StatColumn(
              icon: Icons.speed_rounded,
              label: 'Rata-rata',
              value: session.totalShots > 0
                  ? (session.totalScore / session.totalShots)
                      .toStringAsFixed(1)
                  : '-',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Shot Card Widget (moved from history_screen.dart)
// ─────────────────────────────────────────────────────────
class _ShotCard extends StatelessWidget {
  final ShotModel shot;
  final int displayIndex;

  const _ShotCard({required this.shot, required this.displayIndex});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image Section ────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                shot.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 48, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),

          // ── Info Section ────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shot label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gps_fixed_rounded,
                          color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tembakan ke-$displayIndex',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sesi Latihan',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),

                // Score badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _scoreColor(shot.score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _scoreColor(shot.score).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${shot.score}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(shot.score),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 9) return AppColors.accent;
    if (score >= 7) return AppColors.warning;
    return AppColors.danger;
  }
}
