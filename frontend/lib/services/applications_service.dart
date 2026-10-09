import '../config/api_config.dart';
import '../models/application_model.dart';
import 'api_service.dart';

class ApplicationsService {
  Future<ApplicationModel> applyForJob({
    required String jobId,
    String? resumeId,
    String? coverLetter,
  }) async {
    final Map<String, dynamic> body = {'jobId': jobId};
    if (resumeId != null && resumeId.isNotEmpty) {
      body['resumeId'] = resumeId;
    }
    if (coverLetter != null && coverLetter.isNotEmpty) {
      body['coverLetter'] = coverLetter;
    }

    final response = await ApiService.post(ApiConfig.applications, body: body);
    if (response is Map && response['data'] != null) {
      return ApplicationModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to submit application.');
  }

  Future<List<ApplicationModel>> getApplications() async {
    final response = await ApiService.get(ApiConfig.applications);
    if (response is Map &&
        response['data'] != null &&
        response['data'] is List) {
      return (response['data'] as List)
          .map(
            (item) => ApplicationModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<List<ApplicationModel>> getApplicationsByJob(String jobId) async {
    final response = await ApiService.get(ApiConfig.applicationsByJob(jobId));
    if (response is Map &&
        response['data'] != null &&
        response['data'] is List) {
      return (response['data'] as List)
          .map(
            (item) => ApplicationModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<ApplicationModel> getApplicationById(String id) async {
    final response = await ApiService.get(ApiConfig.applicationById(id));
    if (response is Map && response['data'] != null) {
      return ApplicationModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Application not found.');
  }

  // Student withdraw
  Future<ApplicationModel> withdrawApplication(String id) async {
    final response = await ApiService.put(
      ApiConfig.applicationById(id),
      body: {'status': 'Withdrawn'},
    );
    if (response is Map && response['data'] != null) {
      return ApplicationModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to withdraw application.');
  }

  // Admin status update
  Future<ApplicationModel> updateStatusAdmin(
    String id, {
    required String status,
    String? adminNotes,
  }) async {
    final Map<String, dynamic> body = {'status': status};
    if (adminNotes != null) body['adminNotes'] = adminNotes;

    final response = await ApiService.put(
      ApiConfig.applicationById(id),
      body: body,
    );
    if (response is Map && response['data'] != null) {
      return ApplicationModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to update application status.');
  }

  Future<void> deleteApplication(String id) async {
    await ApiService.delete(ApiConfig.applicationById(id));
  }
}
