// UI Enhancements Demo Screen
// This screen demonstrates the UI enhancements made to the admin verification screen

import 'package:flutter/material.dart';

class UIEnhancementsDemo extends StatelessWidget {
  const UIEnhancementsDemo({super.key});

  static const _primary = Color(0xFF035C4A);
  static const _primaryDeep = Color(0xFF02473A);
  static const _success = Color(0xFF0A8F69);
  static const _danger = Color(0xFFB3261E);
  static const _warning = Color(0xFFC7A66A);
  static const _muted = Color(0xFF535E62);
  static const _bg = Color(0xFFF9F7F2);
  static const _surface = Color(0xFFF3F2ED);
  static const _outline = Color(0xFFC3C8C6);
  static const _ink = Color(0xFF2A323E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'UI Enhancements Demo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Enhanced Features'),
            const SizedBox(height: 16),

            _buildFeatureCard(
              icon: Icons.search_outlined,
              title: 'Search Functionality',
              description:
                  'Real-time search by name, phone, membership type, or gender',
              color: _primary,
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.verified_outlined,
              title: 'Bulk Actions',
              description:
                  'Verify or reject multiple members at once with confirmation dialogs',
              color: _success,
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.refresh_outlined,
              title: 'Pull-to-Refresh',
              description:
                  'Swipe down to refresh member lists with visual feedback',
              color: _warning,
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.notifications_active_outlined,
              title: 'Visual Feedback',
              description:
                  'Snackbars, loading states, and success/error notifications',
              color: _primaryDeep,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('UI Improvements'),
            const SizedBox(height: 16),

            _buildImprovementItem(
              'Enhanced Card Design',
              'Gradients, shadows, and better visual hierarchy',
            ),

            _buildImprovementItem(
              'Better Empty States',
              'Contextual illustrations and helpful messages',
            ),

            _buildImprovementItem(
              'Loading States',
              'Skeleton screens and progress indicators',
            ),

            _buildImprovementItem(
              'Accessibility',
              'Better contrast, larger touch targets, screen reader support',
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Color Scheme'),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildColorSwatch('Primary', _primary),
                const SizedBox(width: 12),
                _buildColorSwatch('Success', _success),
                const SizedBox(width: 12),
                _buildColorSwatch('Error', _danger),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildColorSwatch('Warning', _warning),
                const SizedBox(width: 12),
                _buildColorSwatch('Secondary', _muted),
                const SizedBox(width: 12),
                _buildColorSwatch('Surface', _surface),
              ],
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Try It Out',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Navigate to Admin Dashboard → Verification to see the enhanced UI in action.',
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to App',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outlined, color: _success, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(77),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '#${(color.toARGB32() >> 16).toRadixString(16).toUpperCase()}',
            style: TextStyle(color: _muted, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
