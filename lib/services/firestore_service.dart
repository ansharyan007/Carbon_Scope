import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/site_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all sites
  Stream<List<SiteModel>> getSites({int limit = 500}) {
    return _firestore
        .collection('sites')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SiteModel.fromFirestore(doc))
            .toList());
  }

  // Get sites by emission level
  Stream<List<SiteModel>> getSitesByEmission(String level) {
    Query query = _firestore.collection('sites');

    if (level == 'low') {
      query = query.where('carbonEstimate', isLessThan: 100);
    } else if (level == 'medium') {
      query = query
          .where('carbonEstimate', isGreaterThanOrEqualTo: 100)
          .where('carbonEstimate', isLessThan: 300);
    } else if (level == 'high') {
      query = query.where('carbonEstimate', isGreaterThanOrEqualTo: 300);
    }

    return query.limit(100).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SiteModel.fromFirestore(doc)).toList());
  }

  // Get single site
  Future<SiteModel?> getSite(String siteId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('sites').doc(siteId).get();
      if (doc.exists) {
        return SiteModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting site: $e');
    }
    return null;
  }

  // Add new site
  Future<String?> addSite(SiteModel site, String userId) async {
    try {
      DocumentReference docRef = await _firestore.collection('sites').add(site.toMap());
      
      // Add report
      await _firestore.collection('reports').add({
        'siteId': docRef.id,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(site.latitude, site.longitude),
        'carbonEstimate': site.carbonEstimate,
        'facilityType': site.facilityType,
        'verified': false,
        'platform': 'mobile',
      });

      // Update user points
      await updateUserPoints(userId, 50);
      
      return docRef.id;
    } catch (e) {
      print('Error adding site: $e');
      return null;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Get leaderboard
  Stream<List<UserModel>> getLeaderboard({int limit = 50}) {
    return _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // Update user points
  Future<void> updateUserPoints(String uid, int pointsToAdd) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);
        
        if (userDoc.exists) {
          int currentPoints = (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;
          transaction.update(userRef, {
            'points': currentPoints + pointsToAdd,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error updating user points: $e');
    }
  }

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    try {
      // Get total sites count
      QuerySnapshot sitesSnapshot = await _firestore.collection('sites').get();
      int totalSites = sitesSnapshot.size;

      // Get user's reports
      QuerySnapshot userReportsSnapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .get();
      int userReports = userReportsSnapshot.size;

      // Get violations count
      QuerySnapshot violationsSnapshot = await _firestore
          .collection('sites')
          .where('verifiedViolation', isEqualTo: true)
          .get();
      int violations = violationsSnapshot.size;

      // Get user's rank
      QuerySnapshot leaderboardSnapshot = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .get();
      
      int rank = 1;
      for (var doc in leaderboardSnapshot.docs) {
        if (doc.id == userId) break;
        rank++;
      }

      return {
        'totalSites': totalSites,
        'userReports': userReports,
        'violations': violations,
        'rank': rank,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalSites': 0,
        'userReports': 0,
        'violations': 0,
        'rank': 0,
      };
    }
  }
}
