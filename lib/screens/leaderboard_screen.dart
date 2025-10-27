import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/loading_widget.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 12),
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getLeaderboard(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final users = snapshot.data!;
          final top3 = users.take(3).toList();
          final rest = users.skip(3).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Podium
                if (top3.isNotEmpty) _buildPodium(top3, currentUserId),

                // Leaderboard Table
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        ...rest.asMap().entries.map((entry) {
                          final index = entry.key;
                          final user = entry.value;
                          final rank = index + 4;
                          return _buildLeaderboardItem(
                            user,
                            rank,
                            currentUserId,
                            isLast: index == rest.length - 1,
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildPodium(List<UserModel> top3, String? currentUserId) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Top Contributors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              if (top3.length > 1)
                Expanded(
                  child: _buildPodiumCard(
                    top3[1],
                    2,
                    currentUserId,
                    const Color(0xFFC0C0C0),
                    marginTop: 32,
                  ),
                ),
              const SizedBox(width: 12),
              // 1st Place
              if (top3.isNotEmpty)
                Expanded(
                  child: _buildPodiumCard(
                    top3[0],
                    1,
                    currentUserId,
                    const Color(0xFFFFD700),
                    marginTop: 0,
                  ),
                ),
              const SizedBox(width: 12),
              // 3rd Place
              if (top3.length > 2)
                Expanded(
                  child: _buildPodiumCard(
                    top3[2],
                    3,
                    currentUserId,
                    const Color(0xFFCD7F32),
                    marginTop: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildPodiumCard(
    UserModel user,
    int rank,
    String? currentUserId,
    Color medalColor,
    {required double marginTop}
  ) {
    final isCurrentUser = user.uid == currentUserId;

    return Container(
      margin: EdgeInsets.only(top: marginTop),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: medalColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: medalColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: rank == 1 ? 5 : 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Medal
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: rank == 1 ? 56 : 48,
            height: rank == 1 ? 56 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank == 1
                    ? [const Color(0xFFFFD700), const Color(0xFFFFED4E)]
                    : rank == 2
                        ? [const Color(0xFFC0C0C0), const Color(0xFFE8E8E8)]
                        : [const Color(0xFFCD7F32), const Color(0xFFE59B5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: medalColor.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                ['🥇', '🥈', '🥉'][rank - 1],
                style: TextStyle(fontSize: rank == 1 ? 28 : 24),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Avatar
          CircleAvatar(
            radius: rank == 1 ? 36 : 32,
            backgroundColor: const Color(0xFF22C55E).withOpacity(0.2),
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(
                    user.initial,
                    style: TextStyle(
                      color: const Color(0xFF22C55E),
                      fontWeight: FontWeight.bold,
                      fontSize: rank == 1 ? 20 : 16,
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 8),

          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              user.displayName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                fontSize: rank == 1 ? 15 : 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 4),

          // Points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFF22C55E),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                user.points.toString(),
                style: TextStyle(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                  fontSize: rank == 1 ? 20 : 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPodiumStat(
                  user.totalReports.toString(),
                  'Reports',
                ),
                _buildPodiumStat(
                  user.badgesEarned.toString(),
                  'Badges',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPodiumStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  static Widget _buildLeaderboardItem(
    UserModel user,
    int rank,
    String? currentUserId, {
    required bool isLast,
  }) {
    final isCurrentUser = user.uid == currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF22C55E).withOpacity(0.1)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 40,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF22C55E).withOpacity(0.2),
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          user.initial,
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isCurrentUser
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${user.totalReports} reports',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          if (user.badgesEarned > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.military_tech,
                                    size: 10,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${user.badgesEarned}',
                                    style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Points
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${user.points}',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No users yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to earn points!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  static void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFF22C55E)),
            SizedBox(width: 12),
            Text(
              'How Points Work',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPointItem('Add new sites', '+50 points', Icons.add_location),
            const SizedBox(height: 12),
            _buildPointItem('Report violations', '+30 points', Icons.warning),
            const SizedBox(height: 12),
            _buildPointItem('Verify sites', '+20 points', Icons.check_circle),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.3),
                ),
              ),
              child: Text(
                'Compete with others and climb the leaderboard!',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: Color(0xFF22C55E)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPointItem(String action, String points, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF22C55E),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            action,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          points,
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
