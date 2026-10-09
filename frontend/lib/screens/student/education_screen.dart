import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/education_model.dart';
import '../../services/education_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final EducationService _educationService = EducationService();
  List<EducationModel> _educations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEducations();
  }

  Future<void> _loadEducations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _educationService.getEducations();
      setState(() {
        _educations = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddEditEducationDialog({EducationModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final degreeController = TextEditingController(
      text: existing?.degree ?? '',
    );
    final institutionController = TextEditingController(
      text: existing?.institution ?? '',
    );
    final branchController = TextEditingController(
      text: existing?.branch ?? '',
    );
    final startYearController = TextEditingController(
      text: existing?.startYear?.toString() ?? '',
    );
    final endYearController = TextEditingController(
      text: existing?.endYear?.toString() ?? '',
    );
    final cgpaController = TextEditingController(
      text: existing?.cgpa?.toString() ?? '',
    );
    String selectedLevel = existing?.educationLevel ?? "Bachelor's";
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
                            ? 'Edit Education'
                            : 'Add Education Record',
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
                    controller: degreeController,
                    label: 'Degree / Program *',
                    hint: 'e.g. B.Tech Computer Science, Higher Secondary',
                    prefixIcon: Icons.school,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Degree is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: institutionController,
                    label: 'Institution / College *',
                    hint: 'e.g. ABC Institute of Technology',
                    prefixIcon: Icons.account_balance,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Institution is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: branchController,
                    label: 'Specialization / Branch',
                    hint: 'e.g. Computer Science & Engineering',
                    prefixIcon: Icons.category,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Education Level',
                      prefixIcon: Icon(Icons.layers, size: 20),
                    ),
                    items: EducationModel.allowedEducationLevels
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedLevel = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: startYearController,
                          label: 'Start Year',
                          hint: 'YYYY',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: endYearController,
                          label: 'End Year',
                          hint: 'YYYY',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: cgpaController,
                          label: 'CGPA (0-10)',
                          hint: 'e.g. 8.5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              final numVal = double.tryParse(val);
                              if (numVal == null || numVal < 0 || numVal > 10) {
                                return '0 to 10';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: existing != null ? 'Update Record' : 'Save Record',
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            final startYr = int.tryParse(
                              startYearController.text,
                            );
                            final endYr = int.tryParse(endYearController.text);
                            if (startYr != null &&
                                endYr != null &&
                                endYr < startYr) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'End year cannot be before start year',
                                  ),
                                  backgroundColor: AppTheme.statusRejected,
                                ),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final nav = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              final model = EducationModel(
                                id: existing?.id ?? '',
                                userId: '',
                                degree: degreeController.text.trim(),
                                institution: institutionController.text.trim(),
                                branch: branchController.text.trim(),
                                startYear: startYr,
                                endYear: endYr,
                                cgpa: double.tryParse(cgpaController.text),
                                educationLevel: selectedLevel,
                              );

                              if (existing != null) {
                                await _educationService.updateEducation(
                                  existing.id,
                                  model,
                                );
                              } else {
                                await _educationService.addEducation(model);
                              }

                              nav.pop();
                              if (mounted) {
                                _loadEducations();
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

  Future<void> _deleteEducation(EducationModel edu) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Education Record',
      message:
          'Are you sure you want to remove "${edu.degree}" from your education records?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _educationService.deleteEducation(edu.id);
        _loadEducations();
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
      appBar: AppBar(title: const Text('Education')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Education'),
        onPressed: () => _showAddEditEducationDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEducations,
        child: _isLoading
            ? const LoadingView(message: 'Loading education records...')
            : _errorMessage != null
            ? ErrorView(message: _errorMessage!, onRetry: _loadEducations)
            : _educations.isEmpty
            ? EmptyState(
                icon: Icons.school_outlined,
                title: 'No Education Records',
                description:
                    'Add your degrees, colleges, and academic achievements.',
                actionText: 'Add First Record',
                onAction: () => _showAddEditEducationDialog(),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _educations.length,
                itemBuilder: (context, index) {
                  final edu = _educations[index];

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
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      edu.degree,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      edu.institution,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (edu.branch != null &&
                                        edu.branch!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        edu.branch!,
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
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
                                        _showAddEditEducationDialog(
                                          existing: edu,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: AppTheme.statusRejected,
                                    ),
                                    onPressed: () => _deleteEducation(edu),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (edu.startYear != null || edu.endYear != null)
                                Text(
                                  '${edu.startYear ?? ''} - ${edu.endYear ?? 'Present'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (edu.cgpa != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withOpacity(
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'CGPA: ${edu.cgpa}',
                                    style: const TextStyle(
                                      color: AppTheme.secondaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
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
