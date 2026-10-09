import '../config/api_config.dart';
import '../models/certification_model.dart';
import 'api_service.dart';

class CertificationsService {
  Future<List<CertificationModel>> getCertifications() async {
    final response = await ApiService.get(ApiConfig.certifications);
    if (response is Map &&
        response['data'] != null &&
        response['data'] is List) {
      return (response['data'] as List)
          .map(
            (item) => CertificationModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<CertificationModel> addCertification(CertificationModel cert) async {
    final response = await ApiService.post(
      ApiConfig.certifications,
      body: cert.toJson(),
    );
    if (response is Map && response['data'] != null) {
      return CertificationModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to add certification.');
  }

  Future<CertificationModel> updateCertification(
    String id,
    CertificationModel cert,
  ) async {
    final response = await ApiService.put(
      ApiConfig.certificationById(id),
      body: cert.toJson(),
    );
    if (response is Map && response['data'] != null) {
      return CertificationModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to update certification.');
  }

  Future<void> deleteCertification(String id) async {
    await ApiService.delete(ApiConfig.certificationById(id));
  }
}
