// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/auth_prefs.dart';
import 'edit_profile_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart';
import 'member_feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String memberPhone;
  final String gymId;

  const SettingsScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.memberPhone,
    required this.gymId,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _red = Color(0xFFB3261E);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);

  Map<String, dynamic>? _member;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final member = await AttendanceService.getMember(widget.memberId);
    if (mounted) {
      setState(() {
        _member = member;
        _loading = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final m = _member;
    if (m == null) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          memberId: widget.memberId,
          initialName: m['name'] ?? '',
          initialEmergency: m['emergencyContact'] ?? '',
          initialMembership: m['membershipType'] ?? 'Basic',
        ),
      ),
    );
    if (result != null) {
      setState(() => _member = {...?_member, ...result});
      await AuthPrefs.save(
        memberId: widget.memberId,
        memberName: result['name'],
        gymId: widget.gymId,
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Log Out',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AttendanceService.logout();
    await AuthPrefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: const Color(0xFFC3C8C6)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildProfileCard(),
                const SizedBox(height: 24),
                _sectionLabel('Quick Actions'),
                _actionTile(
                  icon: Icons.bar_chart_outlined,
                  label: 'My Stats & Analytics',
                  color: _blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatsScreen(memberId: widget.memberId),
                    ),
                  ),
                ),
                _actionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  color: const Color(0xFF535E62),
                  onTap: _openEditProfile,
                ),
                _actionTile(
                  icon: Icons.feedback_outlined,
                  label: 'Send Feedback / Report Issue',
                  color: const Color(0xFFC7A66A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberFeedbackScreen(
                        memberId: widget.memberId,
                        gymId: widget.gymId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_outlined, size: 18),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildProfileCard() {
    final name = _member?['name'] as String? ?? widget.memberName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, Color(0xFF02473A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.memberPhone.isEmpty ? 'No phone' : widget.memberPhone,
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: _muted, size: 20),
            onPressed: _openEditProfile,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _blue,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
  );

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }
}
