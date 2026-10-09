import 'package:flutter/foundation.dart';

import 'dart:io' show Platform;

class ApiConfig {
  // Allow passing --dart-define=API_BASE_URL=http://your-server:5000
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      // Flutter Web in Chrome connects directly to localhost:5000
      return 'http://localhost:5000/api';
    }

    try {
      if (Platform.isAndroid) {
        // Android emulator loopback to host machine
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {
      // In case Platform is not supported on some platforms
    }

    // Default for Desktop/iOS simulator
    return 'http://localhost:5000/api';
  }

  // Auth endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get profile => '$baseUrl/auth/profile';

  // Student Profile endpoints
  static String get students => '$baseUrl/students';
  static String studentById(String id) => '$baseUrl/students/$id';

  // Skills endpoints
  static String get skills => '$baseUrl/skills';
  static String skillById(String id) => '$baseUrl/skills/$id';

  // Education endpoints
  static String get education => '$baseUrl/education';
  static String educationById(String id) => '$baseUrl/education/$id';

  // Projects endpoints
  static String get projects => '$baseUrl/projects';
  static String projectById(String id) => '$baseUrl/projects/$id';

  // Certifications endpoints
  static String get certifications => '$baseUrl/certifications';
  static String certificationById(String id) => '$baseUrl/certifications/$id';

  // Resume endpoints
  static String get resume => '$baseUrl/resume';
  static String get resumeMy => '$baseUrl/resume/my';
  static String resumeById(String id) => '$baseUrl/resume/$id';

  // Jobs endpoints
  static String get jobs => '$baseUrl/jobs';
  static String jobById(String id) => '$baseUrl/jobs/$id';

  // Applications endpoints
  static String get applications => '$baseUrl/applications';
  static String applicationById(String id) => '$baseUrl/applications/$id';
  static String applicationsByJob(String jobId) =>
      '$baseUrl/applications/job/$jobId';

  // Admin endpoints
  static String get adminDashboard => '$baseUrl/admin/dashboard';
  static String get adminUsers => '$baseUrl/admin/users';
  static String adminUserById(String id) => '$baseUrl/admin/users/$id';
  static String get adminStudents => '$baseUrl/admin/students';
  static String adminStudentDetails(String userId) =>
      '$baseUrl/admin/students/$userId';
  static String get adminAnalyticsApplications =>
      '$baseUrl/admin/analytics/applications';
  static String get adminAnalyticsJobs => '$baseUrl/admin/analytics/jobs';

  // Timeouts
  static const Duration timeoutDuration = Duration(seconds: 15);
}
