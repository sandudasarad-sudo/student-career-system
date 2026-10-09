import '../config/api_config.dart';
import '../models/job_model.dart';
import 'api_service.dart';

class JobsService {
  Future<List<JobModel>> getJobs() async {
    final response = await ApiService.get(ApiConfig.jobs);
    if (response is Map &&
        response['data'] != null &&
        response['data'] is List) {
      return (response['data'] as List)
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<JobModel> getJobById(String id) async {
    final response = await ApiService.get(ApiConfig.jobById(id));
    if (response is Map && response['data'] != null) {
      return JobModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Job details not found.');
  }

  // Admin methods
  Future<JobModel> createJob(JobModel job) async {
    final response = await ApiService.post(ApiConfig.jobs, body: job.toJson());
    if (response is Map && response['data'] != null) {
      return JobModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to create job posting.');
  }

  Future<JobModel> updateJob(String id, Map<String, dynamic> fields) async {
    final response = await ApiService.put(ApiConfig.jobById(id), body: fields);
    if (response is Map && response['data'] != null) {
      return JobModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update job posting.');
  }

  Future<void> deleteJob(String id) async {
    await ApiService.delete(ApiConfig.jobById(id));
  }
}
