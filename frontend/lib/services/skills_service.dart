import '../config/api_config.dart';
import '../models/skill_model.dart';
import 'api_service.dart';

class SkillsService {
  Future<List<SkillModel>> getSkills() async {
    final response = await ApiService.get(ApiConfig.skills);
    if (response is Map &&
        response['skills'] != null &&
        response['skills'] is List) {
      return (response['skills'] as List)
          .map((item) => SkillModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SkillModel> addSkill({
    required String skillName,
    required String level,
  }) async {
    final response = await ApiService.post(
      ApiConfig.skills,
      body: {'skillName': skillName.trim(), 'level': level},
    );
    if (response is Map && response['skill'] != null) {
      return SkillModel.fromJson(response['skill'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to add skill.');
  }

  Future<SkillModel> updateSkill(
    String id, {
    required String skillName,
    required String level,
  }) async {
    final response = await ApiService.put(
      ApiConfig.skillById(id),
      body: {'skillName': skillName.trim(), 'level': level},
    );
    if (response is Map && response['skill'] != null) {
      return SkillModel.fromJson(response['skill'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to update skill.');
  }

  Future<void> deleteSkill(String id) async {
    await ApiService.delete(ApiConfig.skillById(id));
  }
}
