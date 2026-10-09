import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/certification_model.dart';
import '../../services/certifications_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  final CertificationsService _certService = CertificationsService();
  List<CertificationModel> _certifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCertifications();
  }

  Future<void> _loadCertifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _certService.getCertifications();
      setState(() {
        _certifications = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddEditCertDialog({CertificationModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final issuerController = TextEditingController(
      text: existing?.issuer ?? '',
    );
    final credIdController = TextEditingController(
      text: existing?.credentialId ?? '',
    );
    final credUrlController = TextEditingController(
      text: existing?.credentialUrl ?? '',
    );
    final descController = TextEditingController(
      text: existing?.description ?? '',
    );
    DateTime issueDate = existing?.issueDate ?? DateTime.now();
    DateTime? expiryDate = existing?.expiryDate;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing != null
                            ? 'Edit Certification'
                            : 'Add Certification',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: titleController,
                    label: 'Certification Title *',
                    hint: 'e.g. AWS Certified Solutions Architect',
                    prefixIcon: Icons.verified_user,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: issuerController,
                    label: 'Issuing Organization *',
                    hint: 'e.g. Amazon Web Services, Google, Coursera',
                    prefixIcon: Icons.business,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Issuer is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            'Issued: ${DateFormat('MM/yyyy').format(issueDate)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: issueDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => issueDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(
                            expiryDate != null
                                ? 'Exp: ${DateFormat('MM/yyyy').format(expiryDate!)}'
                                : 'No Expiry',
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  expiryDate ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: issueDate,
                              lastDate: DateTime(2040),
                            );
                            if (picked != null) {
                              setModalState(() => expiryDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: credIdController,
                    label: 'Credential ID',
                    hint: 'License or Verification ID',
                    prefixIcon: Icons.badge,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: credUrlController,
                    label: 'Credential URL',
                    hint: 'https://verify.cert.com/id',
                    prefixIcon: Icons.link,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: descController,
                    label: 'Description',
                    hint: 'Key topics covered or competencies demonstrated',
                    prefixIcon: Icons.description,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: existing != null
                        ? 'Update Certification'
                        : 'Save Certification',
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSaving = true);
                            final nav = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              final model = CertificationModel(
                                id: existing?.id ?? '',
                                userId: '',
                                title: titleController.text.trim(),
                                issuer: issuerController.text.trim(),
                                issueDate: issueDate,
                                expiryDate: expiryDate,
                                credentialId: credIdController.text.trim(),
                                credentialUrl: credUrlController.text.trim(),
                                description: descController.text.trim(),
                              );

                              if (existing != null) {
                                await _certService.updateCertification(
                                  existing.id,
                                  model,
                                );
                              } else {
                                await _certService.addCertification(model);
                              }

                              nav.pop();
                              if (mounted) {
                                _loadCertifications();
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppTheme.statusRejected,
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCert(CertificationModel cert) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Certification',
      message:
          'Are you sure you want to remove "${cert.title}" from your certifications?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _certService.deleteCertification(cert.id);
        _loadCertifications();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certifications')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Certification'),
        onPressed: () => _showAddEditCertDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCertifications,
        child: _isLoading
            ? const LoadingView(message: 'Loading certifications...')
            : _errorMessage != null
            ? ErrorView(message: _errorMessage!, onRetry: _loadCertifications)
            : _certifications.isEmpty
            ? EmptyState(
                icon: Icons.verified_user_outlined,
                title: 'No Certifications Added',
                description: 'Add your professional, technical, and course certifications.',
                actionText: 'Add First Certification',
                onAction: () => _showAddEditCertDialog(),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _certifications.length,
                itemBuilder: (context, index) {
                  final cert = _certifications[index];
                  final formattedIssue = DateFormat('MMM yyyy')
                      .format(cert.issueDate);
                  final formattedExp = cert.expiryDate != null
                      ? DateFormat('MMM yyyy').format(cert.expiryDate!)
                      : 'No Expiry';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.secondaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cert.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      cert.issuer,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showAddEditCertDialog(existing: cert),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: AppTheme.statusRejected,
                                    ),
                                    onPressed: () => _deleteCert(cert),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (cert.description != null &&
                              cert.description!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              cert.description!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Issued: $formattedIssue • Exp: $formattedExp',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (cert.credentialUrl != null &&
                                  cert.credentialUrl!.isNotEmpty)
                                Tooltip(
                                  message: cert.credentialUrl!,
                                  child: const Icon(
                                    Icons.launch,
                                    size: 18,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
