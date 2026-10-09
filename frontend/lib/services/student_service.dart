import '../config/api_config.dart';
import '../models/student_model.dart';
import 'api_service.dart';

class StudentService {
  Future<StudentModel> createProfile(StudentModel profile) async {
    final response = await ApiService.post(
      ApiConfig.students,
      body: profile.toJson(),
    );
    if (response is Map && response['student'] != null) {
      return StudentModel.fromJson(response['student'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to create student profile.');
  }

  Future<StudentModel?> getProfileById(String id) async {
    try {
      final response = await ApiService.get(ApiConfig.studentById(id));
      if (response is Map && response['student'] != null) {
        return StudentModel.fromJson(
          response['student'] as Map<String, dynamic>,
        );
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<StudentModel> updateProfile(String id, StudentModel profile) async {
    final response = await ApiService.put(
      ApiConfig.studentById(id),
      body: profile.toJson(),
    );
    if (response is Map && response['student'] != null) {
      return StudentModel.fromJson(response['student'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update student profile.');
  }

  Future<void> deleteProfile(String id) async {
    await ApiService.delete(ApiConfig.studentById(id));
  }

  Future<List<StudentModel>> getAllStudentsAdmin() async {
    final response = await ApiService.get(ApiConfig.students);
    if (response is Map &&
        response['students'] != null &&
        response['students'] is List) {
      return (response['students'] as List)
          .map((item) => StudentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
