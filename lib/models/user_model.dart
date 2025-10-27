import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String bio;
  final int points;
  final int? rank;
  final int totalReports;
  final int verifiedReports;
  final int rejectedReports;
  final int pendingReports;
  final List<String> badges;
  final int badgesEarned;
  final int totalBadges;
  final List<ActivityModel> recentActivity;
  final UserSettings settings;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final DateTime? memberSince;
  final DateTime? lastLogin;
  final String? country;
  final String? city;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReportDate;
  final Map<String, int> achievementProgress;
  final bool profileComplete;
  final int completionPercentage;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.bio,
    required this.points,
    this.rank,
    required this.totalReports,
    required this.verifiedReports,
    required this.rejectedReports,
    required this.pendingReports,
    required this.badges,
    required this.badgesEarned,
    required this.totalBadges,
    required this.recentActivity,
    required this.settings,
    this.createdAt,
    this.lastActive,
    this.memberSince,
    this.lastLogin,
    this.country,
    this.city,
    required this.currentStreak,
    required this.longestStreak,
    this.lastReportDate,
    required this.achievementProgress,
    required this.profileComplete,
    required this.completionPercentage,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? 'User',
      email: data['email'] ?? '',
      photoURL: data['photoURL'],
      bio: data['bio'] ?? 'New member of EcoLens AI community',
      points: data['points'] ?? 0,
      rank: data['rank'],
      totalReports: data['totalReports'] ?? 0,
      verifiedReports: data['verifiedReports'] ?? 0,
      rejectedReports: data['rejectedReports'] ?? 0,
      pendingReports: data['pendingReports'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      badgesEarned: data['badgesEarned'] ?? 0,
      totalBadges: data['totalBadges'] ?? 12,
      recentActivity: (data['recentActivity'] as List<dynamic>?)
              ?.map((item) => ActivityModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      settings: UserSettings.fromMap(data['settings'] as Map<String, dynamic>? ?? {}),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      lastActive: data['lastActive'] != null ? (data['lastActive'] as Timestamp).toDate() : null,
      memberSince: data['memberSince'] != null ? (data['memberSince'] as Timestamp).toDate() : null,
      lastLogin: data['lastLogin'] != null ? (data['lastLogin'] as Timestamp).toDate() : null,
      country: data['country'],
      city: data['city'],
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastReportDate: data['lastReportDate'] != null ? (data['lastReportDate'] as Timestamp).toDate() : null,
      achievementProgress: Map<String, int>.from(data['achievementProgress'] ?? {}),
      profileComplete: data['profileComplete'] ?? false,
      completionPercentage: data['completionPercentage'] ?? 30,
    );
  }

  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
}

// Activity Model
class ActivityModel {
  final String type;
  final String message;
  final DateTime timestamp;
  final int points;
  final String icon;

  ActivityModel({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.points,
    required this.icon,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      type: map['type'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      points: map['points'] ?? 0,
      icon: map['icon'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'points': points,
      'icon': icon,
    };
  }
}

// User Settings Model
class UserSettings {
  final bool emailNotifications;
  final bool publicProfile;
  final bool showOnLeaderboard;
  final String language;
  final String theme;

  UserSettings({
    required this.emailNotifications,
    required this.publicProfile,
    required this.showOnLeaderboard,
    required this.language,
    required this.theme,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      emailNotifications: map['emailNotifications'] ?? true,
      publicProfile: map['publicProfile'] ?? true,
      showOnLeaderboard: map['showOnLeaderboard'] ?? true,
      language: map['language'] ?? 'en',
      theme: map['theme'] ?? 'dark',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailNotifications': emailNotifications,
      'publicProfile': publicProfile,
      'showOnLeaderboard': showOnLeaderboard,
      'language': language,
      'theme': theme,
    };
  }
}
