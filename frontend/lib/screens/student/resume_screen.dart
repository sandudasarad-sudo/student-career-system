import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/resume_model.dart';
import '../../models/education_model.dart';
import '../../models/skill_model.dart';
import '../../models/project_model.dart';
import '../../models/certification_model.dart';
import '../../services/resume_service.dart';
import '../../services/education_service.dart';
import '../../services/skills_service.dart';
import '../../services/projects_service.dart';
import '../../services/certifications_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final ResumeService _resumeService = ResumeService();
  ResumeModel? _resume;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  Future<void> _loadResume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resume = await _resumeService.getMyResume();
      setState(() {
        _resume = resume;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openResumeEditor() async {
    // Load student's saved items so they can select them
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<EducationModel> allEdus = [];
    List<SkillModel> allSkills = [];
    List<ProjectModel> allProjects = [];
    List<CertificationModel> allCerts = [];

    try {
      final results = await Future.wait([
        EducationService().getEducations(),
        SkillsService().getSkills(),
        ProjectsService().getProjects(),
        CertificationsService().getCertifications(),
      ]);
      allEdus = results[0] as List<EducationModel>;
      allSkills = results[1] as List<SkillModel>;
      allProjects = results[2] as List<ProjectModel>;
      allCerts = results[3] as List<CertificationModel>;
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load portfolio items: $e')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    final objController = TextEditingController(
      text: _resume?.careerObjective ?? '',
    );
    final sumController = TextEditingController(text: _resume?.summary ?? '');
    final urlController = TextEditingController(text: _resume?.resumeUrl ?? '');
    final achController = TextEditingController(
      text: _resume?.achievements.join(', ') ?? '',
    );
    final langController = TextEditingController(
      text: _resume?.languages.join(', ') ?? '',
    );

    final selectedEduIds =
        (_resume?.educations.map((e) => e.id).toSet() ??
        allEdus.map((e) => e.id).toSet());
    final selectedSkillIds =
        (_resume?.skills.map((s) => s.id).toSet() ??
        allSkills.map((s) => s.id).toSet());
    final selectedProjIds =
        (_resume?.projects.map((p) => p.id).toSet() ??
        allProjects.map((p) => p.id).toSet());
    final selectedCertIds =
        (_resume?.certifications.map((c) => c.id).toSet() ??
        allCerts.map((c) => c.id).toSet());

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
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _resume != null ? 'Edit Resume' : 'Build Resume',
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
                const SizedBox(height: 14),
                AppTextField(
                  controller: objController,
                  label: 'Career Objective',
                  hint: 'State your career aspiration and goals...',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: sumController,
                  label: 'Professional Summary',
                  hint: 'Brief overview of skills and achievements...',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: urlController,
                  label: 'Online Resume / PDF Link',
                  hint: 'https://drive.google.com/... or hosted PDF',
                  prefixIcon: Icons.link,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: achController,
                  label: 'Key Achievements (comma separated)',
                  hint: '1st in Hackathon, Dean\'s Honor List, Open Source Contributor',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: langController,
                  label: 'Languages (comma separated)',
                  hint: 'English, Hindi, Spanish',
                ),
                const SizedBox(height: 16),

                // Education selection
                if (allEdus.isNotEmpty) ...[
                  const Text(
                    'Select Education Records:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Wrap(
                    spacing: 6,
                    children: allEdus
                        .map(
                          (edu) => FilterChip(
                            label: Text(edu.degree),
                            selected: selectedEduIds.contains(edu.id),
                            onSelected: (val) {
                              setModalState(() {
                                val
                                    ? selectedEduIds.add(edu.id)
                                    : selectedEduIds.remove(edu.id);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Skills selection
                if (allSkills.isNotEmpty) ...[
                  const Text(
                    'Select Skills:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Wrap(
                    spacing: 6,
                    children: allSkills
                        .map(
                          (sk) => FilterChip(
                            label: Text(sk.skillName),
                            selected: selectedSkillIds.contains(sk.id),
                            onSelected: (val) {
                              setModalState(() {
                                val
                                    ? selectedSkillIds.add(sk.id)
                                    : selectedSkillIds.remove(sk.id);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Projects selection
                if (allProjects.isNotEmpty) ...[
                  const Text(
                    'Select Projects:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Wrap(
                    spacing: 6,
                    children: allProjects
                        .map(
                          (pr) => FilterChip(
                            label: Text(pr.title),
                            selected: selectedProjIds.contains(pr.id),
                            onSelected: (val) {
                              setModalState(() {
                                val
                                    ? selectedProjIds.add(pr.id)
                                    : selectedProjIds.remove(pr.id);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Certifications selection
                if (allCerts.isNotEmpty) ...[
                  const Text(
                    'Select Certifications:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Wrap(
                    spacing: 6,
                    children: allCerts
                        .map(
                          (cr) => FilterChip(
                            label: Text(cr.title),
                            selected: selectedCertIds.contains(cr.id),
                            onSelected: (val) {
                              setModalState(() {
                                val
                                    ? selectedCertIds.add(cr.id)
                                    : selectedCertIds.remove(cr.id);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                AppButton(
                  text: _resume != null ? 'Update Resume' : 'Save Resume',
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);

                          final achievements = achController.text
                              .split(',')
                              .map((a) => a.trim())
                              .where((a) => a.isNotEmpty)
                              .toList();

                          final languages = langController.text
                              .split(',')
                              .map((l) => l.trim())
                              .where((l) => l.isNotEmpty)
                              .toList();

                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            if (_resume != null) {
                              await _resumeService.updateResume(
                                _resume!.id,
                                careerObjective: objController.text.trim(),
                                summary: sumController.text.trim(),
                                resumeUrl: urlController.text.trim(),
                                achievements: achievements,
                                languages: languages,
                                educationIds: selectedEduIds.toList(),
                                skillIds: selectedSkillIds.toList(),
                                projectIds: selectedProjIds.toList(),
                                certificationIds: selectedCertIds.toList(),
                              );
                            } else {
                              await _resumeService.createResume(
                                careerObjective: objController.text.trim(),
                                summary: sumController.text.trim(),
                                resumeUrl: urlController.text.trim(),
                                achievements: achievements,
                                languages: languages,
                                educationIds: selectedEduIds.toList(),
                                skillIds: selectedSkillIds.toList(),
                                projectIds: selectedProjIds.toList(),
                                certificationIds: selectedCertIds.toList(),
                              );
                            }

                            nav.pop();
                            if (mounted) {
                              _loadResume();
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
    );
  }

  Future<void> _deleteResume() async {
    if (_resume == null) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Resume',
      message: 'Are you sure you want to delete your career resume? This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _resumeService.deleteResume(_resume!.id);
        _loadResume();
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
      appBar: AppBar(
        title: const Text('My Resume'),
        actions: [
          if (_resume != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.statusRejected,
              ),
              tooltip: 'Delete Resume',
              onPressed: _deleteResume,
            ),
        ],
      ),
      floatingActionButton: _resume != null
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Resume'),
              onPressed: _openResumeEditor,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadResume,
        child: _isLoading
            ? const LoadingView(message: 'Loading your resume...')
            : _errorMessage != null
            ? ErrorView(message: _errorMessage!, onRetry: _loadResume)
            : _resume == null
            ? EmptyState(
                icon: Icons.description_outlined,
                title: 'No Resume Created Yet',
                description: 'Assemble your skills, education, projects, and career objective into a unified profile.',
                actionText: 'Build My Resume',
                onAction: _openResumeEditor,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Objective Card
                    if (_resume!.careerObjective?.isNotEmpty == true)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Career Objective',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resume!.careerObjective!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Summary Card
                    if (_resume!.summary?.isNotEmpty == true)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.notes,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resume!.summary!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Education Section
                    if (_resume!.educations.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Education',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              ..._resume!.educations.map(
                                (edu) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        edu.degree,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${edu.institution} (${edu.startYear ?? ''} - ${edu.endYear ?? 'Present'})',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (edu.cgpa != null)
                                        Text(
                                          'CGPA: ${edu.cgpa}',
                                          style: const TextStyle(
                                            color: AppTheme.secondaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Skills Section
                    if (_resume!.skills.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.code,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Skills',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _resume!.skills
                                    .map(
                                      (s) => Chip(
                                        label: Text(
                                          '${s.skillName} (${s.level})',
                                        ),
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.06),
                                        labelStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Projects Section
                    if (_resume!.projects.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Projects',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              ..._resume!.projects.map(
                                (proj) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        proj.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        proj.description,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (proj.technologies.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tech: ${proj.technologies.join(', ')}',
                                          style: const TextStyle(
                                            color: AppTheme.primaryLight,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Certifications Section
                    if (_resume!.certifications.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 20,
                                    color: AppTheme.secondaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Certifications',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              ..._resume!.certifications.map(
                                (cert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '• ${cert.title} — ${cert.issuer}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Achievements & Languages
                    if (_resume!.achievements.isNotEmpty ||
                        _resume!.languages.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_resume!.achievements.isNotEmpty) ...[
                                const Text(
                                  'Key Achievements',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ..._resume!.achievements.map(
                                  (ach) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '✓ $ach',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (_resume!.languages.isNotEmpty) ...[
                                const Text(
                                  'Languages',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _resume!.languages.join(', '),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 80), // spacing for FAB
                  ],
                ),
              ),
      ),
    );
  }
}
