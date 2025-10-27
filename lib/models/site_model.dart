import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SiteModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String facilityType;
  final double carbonEstimate;
  final bool verifiedViolation;
  final int reportCount;
  final DateTime? lastUpdated;
  final String? createdBy;
  final double? aiConfidence;

  SiteModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.facilityType,
    required this.carbonEstimate,
    required this.verifiedViolation,
    required this.reportCount,
    this.lastUpdated,
    this.createdBy,
    this.aiConfidence,
  });

  factory SiteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return SiteModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Site',
      address: data['address'] ?? 'Unknown Location',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      facilityType: data['facilityType'] ?? 'other',
      carbonEstimate: (data['carbonEstimate'] ?? 0.0).toDouble(),
      verifiedViolation: data['verifiedViolation'] ?? false,
      reportCount: data['reportCount'] ?? 0,
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'],
      aiConfidence: data['aiConfidence'] != null 
          ? (data['aiConfidence'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'location': GeoPoint(latitude, longitude),
      'facilityType': facilityType,
      'carbonEstimate': carbonEstimate,
      'verifiedViolation': verifiedViolation,
      'reportCount': reportCount,
      'lastUpdated': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'aiConfidence': aiConfidence ?? 0.85,
    };
  }

  String get emissionLevel {
    if (carbonEstimate < 100) return 'Low';
    if (carbonEstimate < 300) return 'Medium';
    return 'High';
  }

  Color get emissionColor {
    if (carbonEstimate < 100) return const Color(0xFF22C55E);
    if (carbonEstimate < 300) return const Color(0xFFEAB308);
    return const Color(0xFFEF4444);
  }

  IconData get facilityIcon {
    switch (facilityType) {
      case 'cement':
        return Icons.factory;
      case 'steel':
        return Icons.construction;
      case 'power':
        return Icons.bolt;
      case 'refinery':
        return Icons.oil_barrel;
      case 'chemical':
        return Icons.science;
      default:
        return Icons.business;
    }
  }
}
