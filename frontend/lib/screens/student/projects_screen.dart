import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/project_model.dart';
import '../../services/projects_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ProjectsService _projectsService = ProjectsService();
  List<ProjectModel> _projects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _projectsService.getProjects();
      setState(() {
        _projects = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddEditProjectDialog({ProjectModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final techController = TextEditingController(
      text: existing?.technologies.join(', ') ?? '',
    );
    final roleController = TextEditingController(text: existing?.role ?? '');
    final githubController = TextEditingController(
      text: existing?.githubUrl ?? '',
    );
    final liveController = TextEditingController(text: existing?.liveUrl ?? '');
    String selectedStatus = existing?.status ?? 'In Progress';
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
                        existing != null ? 'Edit Project' : 'Add New Project',
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
                    label: 'Project Title *',
                    hint: 'e.g. E-Commerce Platform, Chat App',
                    prefixIcon: Icons.folder_open,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: descriptionController,
                    label: 'Description *',
                    hint:
                        'Explain what the project does, problems it solved...',
                    prefixIcon: Icons.description,
                    maxLines: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: techController,
                    label: 'Technologies (comma separated)',
                    hint: 'Flutter, Node.js, MongoDB, Docker',
                    prefixIcon: Icons.settings,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: roleController,
                          label: 'Role',
                          hint: 'Frontend / Lead',
                          prefixIcon: Icons.badge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.flag, size: 20),
                          ),
                          items: ProjectModel.allowedStatuses
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedStatus = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: githubController,
                    label: 'GitHub URL',
                    hint: 'https://github.com/user/project',
                    prefixIcon: Icons.link,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: liveController,
                    label: 'Live Demo URL',
                    hint: 'https://myproject.com',
                    prefixIcon: Icons.open_in_browser,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: existing != null ? 'Update Project' : 'Save Project',
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSaving = true);

                            final techList = techController.text
                                .split(',')
                                .map((t) => t.trim())
                                .where((t) => t.isNotEmpty)
                                .toList();

                            final nav = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              final model = ProjectModel(
                                id: existing?.id ?? '',
                                userId: '',
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim(),
                                technologies: techList,
                                role: roleController.text.trim(),
                                githubUrl: githubController.text.trim(),
                                liveUrl: liveController.text.trim(),
                                status: selectedStatus,
                              );

                              if (existing != null) {
                                await _projectsService.updateProject(
                                  existing.id,
                                  model,
                                );
                              } else {
                                await _projectsService.addProject(model);
                              }

                              nav.pop();
                              if (mounted) {
                                _loadProjects();
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

  Future<void> _deleteProject(ProjectModel proj) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Project',
      message:
          'Are you sure you want to remove "${proj.title}" from your projects?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _projectsService.deleteProject(proj.id);
        _loadProjects();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF10B981); // Emerald
      case 'In Progress':
        return AppTheme.primaryLight;
      default:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
        onPressed: () => _showAddEditProjectDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        child: _isLoading
            ? const LoadingView(message: 'Loading projects...')
            : _errorMessage != null
            ? ErrorView(message: _errorMessage!, onRetry: _loadProjects)
            : _projects.isEmpty
            ? EmptyState(
                icon: Icons.folder_open,
                title: 'No Projects Added',
                description:
                    'Showcase your engineering work, apps, and repositories.',
                actionText: 'Add First Project',
                onAction: () => _showAddEditProjectDialog(),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final proj = _projects[index];
                  final statusColor = _getStatusColor(proj.status);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      proj.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (proj.role != null &&
                                        proj.role!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Role: ${proj.role}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  proj.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            proj.description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          if (proj.technologies.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: proj.technologies
                                  .map(
                                    (t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.15),
                                        ),
                                      ),
                                      child: Text(
                                        t,
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (proj.githubUrl != null &&
                                      proj.githubUrl!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Tooltip(
                                        message: proj.githubUrl!,
                                        child: const Icon(
                                          Icons.code,
                                          size: 20,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  if (proj.liveUrl != null &&
                                      proj.liveUrl!.isNotEmpty)
                                    Tooltip(
                                      message: proj.liveUrl!,
                                      child: const Icon(
                                        Icons.launch,
                                        size: 20,
                                        color: AppTheme.primaryLight,
                                      ),
                                    ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _showAddEditProjectDialog(
                                      existing: proj,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: AppTheme.statusRejected,
                                    ),
                                    onPressed: () => _deleteProject(proj),
                                  ),
                                ],
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
