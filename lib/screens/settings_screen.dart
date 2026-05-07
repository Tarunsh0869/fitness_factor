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
  static const _blue  = Color(0xFF2563EB);
  static const _red   = Color(0xFFEF4444);
  static const _bg    = Color(0xFFF0F4FF);
  static const _card  = Colors.white;
  static const _ink   = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);

  Map<String, dynamic>? _gym;
  Map<String, dynamic>? _member;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final results = await Future.wait([
      AttendanceService.getGym(widget.gymId),
      AttendanceService.getMember(widget.memberId),
    ]);
    if (mounted) {
      setState(() {
        _gym     = results[0];
        _member  = results[1];
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
          memberId:          widget.memberId,
          initialName:       m['name']            ?? '',
          initialEmergency:  m['emergencyContact'] ?? '',
          initialMembership: m['membershipType']   ?? 'Basic',
        ),
      ),
    );
    if (result != null) {
      setState(() => _member = {...?_member, ...result});
      await AuthPrefs.save(
        memberId:   widget.memberId,
        memberName: result['name'],
        gymId:      widget.gymId,
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Log Out',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?',
            style: TextStyle(color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out',
                style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AuthPrefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StatsScreen(memberId: widget.memberId),
                  )),
                ),
                _actionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  color: const Color(0xFF7C3AED),
                  onTap: _openEditProfile,
                ),
                _actionTile(
                  icon: Icons.feedback_outlined,
                  label: 'Send Feedback / Report Issue',
                  color: const Color(0xFFD97706),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MemberFeedbackScreen(
                      memberId: widget.memberId,
                      gymId:    widget.gymId,
                    ),
                  )),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Member'),
                _infoTile(Icons.badge_outlined,  'Member ID', widget.memberId),
                _infoTile(Icons.phone_outlined,  'Phone',
                    widget.memberPhone.isEmpty ? '\u2014' : widget.memberPhone),
                if (_member != null) ...[
                  _infoTile(Icons.emergency_outlined, 'Emergency',
                      _member!['emergencyContact'] as String? ?? '\u2014'),
                  _membershipBadgeTile(
                      _member!['membershipType'] as String? ?? 'Basic'),
                ],
                const SizedBox(height: 24),
                _sectionLabel('Gym'),
                if (_gym != null) ...[
                  _infoTile(Icons.store_outlined, 'Gym Name',
                      _gym!['name'] as String? ?? widget.gymId),
                  _infoTile(Icons.my_location_outlined, 'Latitude',
                      (_gym!['latitude'] as num?)?.toStringAsFixed(6) ?? '\u2014'),
                  _infoTile(Icons.my_location_outlined, 'Longitude',
                      (_gym!['longitude'] as num?)?.toStringAsFixed(6) ?? '\u2014'),
                  _radiusTile((_gym!['radiusMeters'] as num?)?.toInt() ?? 50),
                ] else
                  _infoTile(Icons.error_outline, 'Status',
                      'Could not load gym data'),
                const SizedBox(height: 24),
                _sectionLabel('App'),
                _infoTile(Icons.info_outline,         'Version',       '1.0.0'),
                _infoTile(Icons.location_on_outlined,  'Geo Mode',
                    'Auto (30s debounce)'),
                _infoTile(Icons.timer_outlined,        'Auto Checkout',
                    '5 min after exit'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_outlined, size: 18),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildProfileCard() {
    final name       = _member?['name']           as String? ?? widget.memberName;
    final membership = _member?['membershipType'] as String? ?? 'Basic';
    final membershipColors = {
      'Basic':   _blue,
      'Premium': const Color(0xFFD97706),
      'VIP':     const Color(0xFF7C3AED),
    };
    final color = membershipColors[membership] ?? _blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: _ink, fontSize: 18,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.memberPhone.isEmpty ? 'No phone' : widget.memberPhone,
                    style: TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(membership,
                      style: TextStyle(color: color, fontSize: 12,
                          fontWeight: FontWeight.w700)),
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
    child: Text(label.toUpperCase(),
        style: const TextStyle(color: _blue, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.4)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label,
                style: const TextStyle(color: _ink, fontSize: 14,
                    fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: _blue, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: _muted, fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: _ink, fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _membershipBadgeTile(String type) {
    final colors = {
      'Basic':   _blue,
      'Premium': const Color(0xFFD97706),
      'VIP':     const Color(0xFF7C3AED),
    };
    final color = colors[type] ?? _blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.card_membership_outlined, color: color, size: 20),
          const SizedBox(width: 12),
          Text('Membership', style: TextStyle(color: _muted, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(type,
                style: TextStyle(color: color, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _radiusTile(int radius) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.radar_outlined, color: _blue, size: 20),
          const SizedBox(width: 12),
          Text('Geofence Radius', style: TextStyle(color: _muted, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${radius}m',
                style: const TextStyle(color: _blue, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
