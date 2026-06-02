// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class RewardsScreen extends StatefulWidget {
  final String memberId;
  final bool embedded;
  const RewardsScreen({
    super.key,
    required this.memberId,
    this.embedded = false,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _accent = Color(0xFF035C4A);
  static const _accentDk = Color(0xFF02473A);
  static const _surface = Color(0xFFE0E4E2);
  static const _gold = Color(0xFFC7A66A);
  static const _goldLight = Color(0xFFFFF3DC);
  static const _silver = Color(0xFF9EAAB5);
  static const _bronze = Color(0xFFB07C5B);

  Map<String, dynamic> _stats = {};
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = AttendanceService.statsStream(widget.memberId).listen((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  int get _xp {
    final visits = (_stats['visitsLast30'] as int? ?? 0);
    final streak = (_stats['streak'] as int? ?? 0);
    final minutes = (_stats['totalMinutes'] as int? ?? 0);
    return (visits * 50) + (streak * 30) + (minutes ~/ 10);
  }

  int get _level => (_xp / 300).floor() + 1;
  double get _levelProgress {
    final xpInLevel = _xp % 300;
    return (xpInLevel / 300).clamp(0.0, 1.0);
  }

  int get _xpToNext => 300 - (_xp % 300);

  String get _tier {
    if (_level >= 20) return 'Elite';
    if (_level >= 10) return 'Dedicated';
    if (_level >= 5) return 'Regular';
    return 'Beginner';
  }

  Color get _tierColor {
    if (_level >= 20) return const Color(0xFF9B59B6);
    if (_level >= 10) return _gold;
    if (_level >= 5) return _silver;
    return _bronze;
  }

  String get _tierEmoji {
    if (_level >= 20) return '💎';
    if (_level >= 10) return '🥇';
    if (_level >= 5) return '🥈';
    return '🥉';
  }

  List<_Badge> get _badges {
    final streak = _stats['streak'] as int? ?? 0;
    final weekVisits = _stats['weekVisits'] as int? ?? 0;
    final monthVisits = _stats['monthVisits'] as int? ?? 0;
    final totalMinutes = _stats['totalMinutes'] as int? ?? 0;
    final visitsLast30 = _stats['visitsLast30'] as int? ?? 0;

    return [
      _Badge(
        emoji: '🏋️',
        label: 'First Step',
        desc: 'Complete your first visit',
        unlocked: visitsLast30 >= 1,
        color: _bronze,
      ),
      _Badge(
        emoji: '🔥',
        label: '3-Day Streak',
        desc: '3 consecutive days',
        unlocked: streak >= 3,
        color: const Color(0xFFE85D04),
      ),
      _Badge(
        emoji: '💪',
        label: 'Week Warrior',
        desc: '5 visits in a week',
        unlocked: weekVisits >= 5,
        color: _accent,
      ),
      _Badge(
        emoji: '⚡',
        label: 'On Fire',
        desc: '7-day streak',
        unlocked: streak >= 7,
        color: const Color(0xFFF77F00),
      ),
      _Badge(
        emoji: '🌟',
        label: 'Unstoppable',
        desc: '14-day streak',
        unlocked: streak >= 14,
        color: _gold,
      ),
      _Badge(
        emoji: '📅',
        label: 'Monthly Master',
        desc: '20 visits this month',
        unlocked: monthVisits >= 20,
        color: const Color(0xFF3A86FF),
      ),
      _Badge(
        emoji: '⏱️',
        label: 'Iron Hour',
        desc: '60+ min avg session',
        unlocked: (_stats['avgMinutes'] as int? ?? 0) >= 60,
        color: _silver,
      ),
      _Badge(
        emoji: '🔱',
        label: 'Legend',
        desc: '30-day streak',
        unlocked: streak >= 30,
        color: const Color(0xFF9B59B6),
      ),
      _Badge(
        emoji: '👑',
        label: 'Century Club',
        desc: '300+ XP earned',
        unlocked: _xp >= 300,
        color: _gold,
      ),
      _Badge(
        emoji: '🏆',
        label: 'Elite Athlete',
        desc: 'Reach level 20',
        unlocked: _level >= 20,
        color: const Color(0xFF9B59B6),
      ),
      _Badge(
        emoji: '🌅',
        label: 'Early Bird',
        desc: 'Check in before 7am',
        unlocked: false, // requires time-of-day tracking
        color: const Color(0xFFF4A261),
      ),
      _Badge(
        emoji: '🦉',
        label: 'Night Owl',
        desc: 'Check in after 8pm',
        unlocked: (_stats['peakHour'] as int? ?? -1) >= 20,
        color: const Color(0xFF457B9D),
      ),
    ];
  }

  List<_Challenge> get _weeklyChallenges {
    final weekVisits = _stats['weekVisits'] as int? ?? 0;
    final streak = _stats['streak'] as int? ?? 0;
    final weekMinutes = _stats['weekMinutes'] as int? ?? 0;

    return [
      _Challenge(
        icon: Icons.calendar_today_rounded,
        label: 'Visit 3x this week',
        current: weekVisits.clamp(0, 3),
        goal: 3,
        xpReward: 150,
        color: _accent,
      ),
      _Challenge(
        icon: Icons.local_fire_department_rounded,
        label: 'Maintain a 5-day streak',
        current: streak.clamp(0, 5),
        goal: 5,
        xpReward: 200,
        color: const Color(0xFFE85D04),
      ),
      _Challenge(
        icon: Icons.timer_rounded,
        label: 'Log 3h of gym time',
        current: (weekMinutes / 60).clamp(0, 3).toInt(),
        goal: 3,
        xpReward: 180,
        color: const Color(0xFF3A86FF),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Rewards',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _buildXpCard(),
          const SizedBox(height: 16),
          _buildWeeklyChallenges(),
          const SizedBox(height: 16),
          _buildBadgesSection(),
        ],
      ),
    );
  }

  Widget _buildXpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accentDk, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_tierEmoji  $_tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$_xp XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Level $_level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_xpToNext XP to Level ${_level + 1}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _levelProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _xpSource('👟', '${_stats['visitsLast30'] ?? 0}', 'Visits'),
              const SizedBox(width: 10),
              _xpSource('🔥', '${_stats['streak'] ?? 0}', 'Streak'),
              const SizedBox(width: 10),
              _xpSource(
                '⏱️',
                '${((_stats['totalMinutes'] as int? ?? 0) / 60).toStringAsFixed(1)}h',
                'Gym Time',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _xpSource(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChallenges() {
    final challenges = _weeklyChallenges;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Challenges',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...challenges.map((c) => _buildChallengeCard(c)),
      ],
    );
  }

  Widget _buildChallengeCard(_Challenge c) {
    final done = c.current >= c.goal;
    final progress = (c.current / c.goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? c.color.withOpacity(0.4) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c.icon, color: c.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.label,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.current}/${c.goal} completed',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: done
                      ? c.color.withOpacity(0.12)
                      : _surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  done ? '✓ Done' : '+${c.xpReward} XP',
                  style: TextStyle(
                    color: done ? c.color : _muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: _surface,
              valueColor: AlwaysStoppedAnimation<Color>(c.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final badges = _badges;
    final unlocked = badges.where((b) => b.unlocked).toList();
    final locked = badges.where((b) => !b.unlocked).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Badges',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${unlocked.length}/${badges.length}',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            ...unlocked.map((b) => _buildBadgeTile(b)),
            ...locked.map((b) => _buildBadgeTile(b)),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeTile(_Badge b) {
    return Container(
      decoration: BoxDecoration(
        color: b.unlocked ? _goldLight : _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: b.unlocked ? b.color.withOpacity(0.35) : _surface,
        ),
        boxShadow: b.unlocked
            ? [
                BoxShadow(
                  color: b.color.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                b.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: b.unlocked ? null : Colors.transparent,
                ),
              ),
              if (!b.unlocked)
                const Icon(Icons.lock_rounded, color: _surface, size: 28),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            b.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: b.unlocked ? _ink : _muted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              b.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: b.unlocked ? _muted : _surface,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final String emoji;
  final String label;
  final String desc;
  final bool unlocked;
  final Color color;
  const _Badge({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.unlocked,
    required this.color,
  });
}

class _Challenge {
  final IconData icon;
  final String label;
  final int current;
  final int goal;
  final int xpReward;
  final Color color;
  const _Challenge({
    required this.icon,
    required this.label,
    required this.current,
    required this.goal,
    required this.xpReward,
    required this.color,
  });
}
