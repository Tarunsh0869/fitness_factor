// UI Enhancements Demo Screen
// This screen demonstrates the UI enhancements made to the admin verification screen

import 'package:flutter/material.dart';

class UIEnhancementsDemo extends StatelessWidget {
  const UIEnhancementsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        foregroundColor: const Color(0xFF111827),
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
              description: 'Real-time search by name, phone, membership type, or gender',
              color: const Color(0xFF2563EB),
            ),
            
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              icon: Icons.verified_outlined,
              title: 'Bulk Actions',
              description: 'Verify or reject multiple members at once with confirmation dialogs',
              color: const Color(0xFF16A34A),
            ),
            
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              icon: Icons.refresh_outlined,
              title: 'Pull-to-Refresh',
              description: 'Swipe down to refresh member lists with visual feedback',
              color: const Color(0xFFD97706),
            ),
            
            const SizedBox(height: 12),
            
            _buildFeatureCard(
              icon: Icons.notifications_active_outlined,
              title: 'Visual Feedback',
              description: 'Snackbars, loading states, and success/error notifications',
              color: const Color(0xFF7C3AED),
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
                _buildColorSwatch('Primary Blue', const Color(0xFF2563EB)),
                const SizedBox(width: 12),
                _buildColorSwatch('Success Green', const Color(0xFF16A34A)),
                const SizedBox(width: 12),
                _buildColorSwatch('Error Red', const Color(0xFFEF4444)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                _buildColorSwatch('Warning Amber', const Color(0xFFD97706)),
                const SizedBox(width: 12),
                _buildColorSwatch('Purple', const Color(0xFF7C3AED)),
                const SizedBox(width: 12),
                _buildColorSwatch('Muted Gray', const Color(0xFF6B7280)),
              ],
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
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
                      color: const Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Navigate to Admin Dashboard → Verification to see the enhanced UI in action.',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
      style: TextStyle(
        color: const Color(0xFF111827),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: color.withOpacity(0.1),
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
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                  ),
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
          Icon(
            Icons.check_circle_outlined,
            color: const Color(0xFF16A34A),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                  ),
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
                  color: color.withOpacity(0.3),
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
              color: const Color(0xFF111827),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}