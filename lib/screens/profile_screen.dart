import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/loading_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = FirestoreService();
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: FutureBuilder<UserModel?>(
        future: firestoreService.getUserData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1A1F2E),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF22C55E),
                          Color(0xFF16A34A),
                          Color(0xFF0EA5E9),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _showLogoutDialog(context, authService),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0F1419),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF22C55E),
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Text(
                                user.initial,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Member since 2024',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            'Total Points',
                            user.points.toString(),
                            Icons.star,
                            const Color(0xFFEAB308),
                          ),
                          _buildStatCard(
                            'Global Rank',
                            user.rank != null ? '#${user.rank}' : 'Unranked',
                            Icons.emoji_events,
                            const Color(0xFFFFD700),
                          ),
                          _buildStatCard(
                            'Reports',
                            user.totalReports.toString(),
                            Icons.report,
                            const Color(0xFF3B82F6),
                          ),
                          _buildStatCard(
                            'Badges',
                            '${user.badgesEarned}/12',
                            Icons.military_tech,
                            const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSection(
                      context,
                      'Achievements',
                      'Unlock badges by completing challenges',
                      Icons.emoji_events,
                      _buildBadgesGrid(user),
                    ),

                    const SizedBox(height: 24),

                    _buildSection(
                      context,
                      'My Reports',
                      'Sites you\'ve reported',
                      Icons.assignment,
                      _buildReportsList(userId, firestoreService),
                    ),

                    const SizedBox(height: 24),

                    _buildSection(
                      context,
                      'Settings',
                      'Manage your preferences',
                      Icons.settings,
                      _buildSettingsList(),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget content,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF22C55E), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(UserModel user) {
    final badges = [
      {'name': 'First Steps', 'icon': Icons.flag, 'earned': user.totalReports >= 1, 'progress': user.totalReports, 'total': 1},
      {'name': 'Carbon Detective', 'icon': Icons.search, 'earned': user.totalReports >= 10, 'progress': user.totalReports, 'total': 10},
      {'name': 'Eco Warrior', 'icon': Icons.eco, 'earned': user.totalReports >= 50, 'progress': user.totalReports, 'total': 50},
      {'name': 'Rising Star', 'icon': Icons.star, 'earned': user.points >= 500, 'progress': user.points, 'total': 500},
      {'name': 'Top Contributor', 'icon': Icons.emoji_events, 'earned': user.points >= 1000, 'progress': user.points, 'total': 1000},
      {'name': 'Legend', 'icon': Icons.workspace_premium, 'earned': user.points >= 5000, 'progress': user.points, 'total': 5000},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9, // Further increased from 0.85
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final earned = badge['earned'] as bool;
          final progress = badge['progress'] as int;
          final total = badge['total'] as int;
          final percentage = (progress / total * 100).clamp(0, 100);

          return Container(
            decoration: BoxDecoration(
              color: earned
                  ? const Color(0xFF22C55E).withOpacity(0.15)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: earned
                    ? const Color(0xFF22C55E).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 2,
              ),
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(6), // Reduced from 8
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45, // Reduced from 50
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: earned
                          ? const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                            )
                          : null,
                      color: earned ? null : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: earned
                          ? [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      badge['icon'] as IconData,
                      color: earned ? Colors.white : Colors.grey[600],
                      size: 22, // Reduced from 24
                    ),
                  ),
                  const SizedBox(height: 4), // Reduced from 6
                  Text(
                    badge['name'] as String,
                    style: TextStyle(
                      color: earned ? Colors.white : Colors.grey[600],
                      fontSize: 8.5, // Reduced from 9
                      fontWeight: FontWeight.w600,
                      height: 1.0, // Tighter line height
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3), // Reduced from 4
                  if (!earned) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 2.5, // Reduced from 3
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 7.5, // Reduced from 8
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5), // Reduced padding
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '✓ Earned',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 7.5, // Reduced from 8
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportsList(String userId, FirestoreService firestoreService) {
    return StreamBuilder(
      stream: firestoreService.getSites(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text(
                    'No reports yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final site = snapshot.data![index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: site.emissionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      site.facilityIcon,
                      color: site.emissionColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          site.facilityType.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${site.carbonEstimate.toStringAsFixed(0)} tCO₂',
                    style: TextStyle(
                      color: site.emissionColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingItem(
            Icons.notifications,
            'Email Notifications',
            'Receive updates via email',
            true,
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            Icons.public,
            'Public Profile',
            'Show your profile to others',
            true,
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            Icons.emoji_events,
            'Show on Leaderboard',
            'Appear in global rankings',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, bool value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF22C55E), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: (val) {},
            activeColor: const Color(0xFF22C55E),
          ),
        ),
      ],
    );
  }

  static void _showEditDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.displayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFF0F1419),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
