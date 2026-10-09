import '../config/api_config.dart';
import '../models/project_model.dart';
import 'api_service.dart';

class ProjectsService {
  Future<List<ProjectModel>> getProjects() async {
    final response = await ApiService.get(ApiConfig.projects);
    if (response is Map &&
        response['data'] != null &&
        response['data'] is List) {
      return (response['data'] as List)
          .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ProjectModel> addProject(ProjectModel project) async {
    final response = await ApiService.post(
      ApiConfig.projects,
      body: project.toJson(),
    );
    if (response is Map && response['data'] != null) {
      return ProjectModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to create project.');
  }

  Future<ProjectModel> updateProject(String id, ProjectModel project) async {
    final response = await ApiService.put(
      ApiConfig.projectById(id),
      body: project.toJson(),
    );
    if (response is Map && response['data'] != null) {
      return ProjectModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update project.');
  }

  Future<void> deleteProject(String id) async {
    await ApiService.delete(ApiConfig.projectById(id));
  }
}
