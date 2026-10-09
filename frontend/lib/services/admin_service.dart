import '../config/api_config.dart';
import '../models/admin_models.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import 'api_service.dart';

class AdminService {
  Future<AdminDashboardStats> getDashboardStats() async {
    final response = await ApiService.get(ApiConfig.adminDashboard);
    if (response is Map && response['data'] != null) {
      return AdminDashboardStats.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to load admin dashboard stats.');
  }

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (role != null && role.isNotEmpty) params['role'] = role;

    final uri = Uri.parse(ApiConfig.adminUsers)
        .replace(queryParameters: params);
    final response = await ApiService.get(uri.toString());

    if (response is Map && response['data'] is List) {
      final users = (response['data'] as List)
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return {
        'users': users,
        'total': response['total'] ?? users.length,
        'page': response['page'] ?? page,
        'totalPages': response['totalPages'] ?? 1,
      };
    }
    return {'users': <UserModel>[], 'total': 0, 'page': page, 'totalPages': 1};
  }

  Future<Map<String, dynamic>> getStudents({
    int page = 1,
    int limit = 10,
    String? search,
    String? branch,
    int? year,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (branch != null && branch.isNotEmpty) params['branch'] = branch;
    if (year != null) params['year'] = year.toString();

    final uri = Uri.parse(ApiConfig.adminStudents)
        .replace(queryParameters: params);
    final response = await ApiService.get(uri.toString());

    if (response is Map && response['data'] is List) {
      final students = (response['data'] as List)
          .map((item) => StudentModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return {
        'students': students,
        'total': response['total'] ?? students.length,
        'page': response['page'] ?? page,
        'totalPages': response['totalPages'] ?? 1,
      };
    }
    return {
      'students': <StudentModel>[],
      'total': 0,
      'page': page,
      'totalPages': 1,
    };
  }

  Future<ConsolidatedStudentDetails> getStudentDetails(String userId) async {
    final response = await ApiService.get(
      ApiConfig.adminStudentDetails(userId),
    );
    if (response is Map && response['data'] != null) {
      return ConsolidatedStudentDetails.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to retrieve student details.');
  }
}
