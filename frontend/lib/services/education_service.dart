import '../config/api_config.dart';
import '../models/education_model.dart';
import 'api_service.dart';

class EducationService {
  Future<List<EducationModel>> getEducations() async {
    final response = await ApiService.get(ApiConfig.education);
    if (response is Map &&
        response['data'] != null &&
        response['data'] is List) {
      return (response['data'] as List)
          .map((item) => EducationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<EducationModel> addEducation(EducationModel education) async {
    final response = await ApiService.post(
      ApiConfig.education,
      body: education.toJson(),
    );
    if (response is Map && response['data'] != null) {
      return EducationModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to add education record.');
  }

  Future<EducationModel> updateEducation(
    String id,
    EducationModel education,
  ) async {
    final response = await ApiService.put(
      ApiConfig.educationById(id),
      body: education.toJson(),
    );
    if (response is Map && response['data'] != null) {
      return EducationModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update education record.');
  }

  Future<void> deleteEducation(String id) async {
    await ApiService.delete(ApiConfig.educationById(id));
  }
}
