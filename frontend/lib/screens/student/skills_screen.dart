import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/skill_model.dart';
import '../../services/skills_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final SkillsService _skillsService = SkillsService();
  List<SkillModel> _skills = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skills = await _skillsService.getSkills();
      setState(() {
        _skills = skills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddEditSkillDialog({SkillModel? existingSkill}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: existingSkill?.skillName ?? '',
    );
    String selectedLevel = existingSkill?.level ?? 'Beginner';
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
                      existingSkill != null ? 'Edit Skill' : 'Add New Skill',
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
                  controller: nameController,
                  label: 'Skill Name',
                  hint: 'e.g. Flutter, Node.js, Python',
                  prefixIcon: Icons.code,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Skill name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Proficiency Level',
                    prefixIcon: Icon(Icons.star_outline, size: 20),
                  ),
                  items: SkillModel.allowedLevels
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedLevel = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: existingSkill != null ? 'Update Skill' : 'Save Skill',
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isSaving = true);

                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            if (existingSkill != null) {
                              await _skillsService.updateSkill(
                                existingSkill.id,
                                skillName: nameController.text.trim(),
                                level: selectedLevel,
                              );
                            } else {
                              await _skillsService.addSkill(
                                skillName: nameController.text.trim(),
                                level: selectedLevel,
                              );
                            }
                            nav.pop();
                            if (mounted) {
                              _loadSkills();
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

  Future<void> _deleteSkill(SkillModel skill) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Skill',
      message:
          'Are you sure you want to remove "${skill.skillName}" from your skills?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _skillsService.deleteSkill(skill.id);
        _loadSkills();
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

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Expert':
        return const Color(0xFF10B981); // Emerald
      case 'Advanced':
        return AppTheme.primaryLight;
      case 'Intermediate':
        return const Color(0xFFF59E0B); // Amber
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Skills')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
        onPressed: () => _showAddEditSkillDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSkills,
        child: _isLoading
            ? const LoadingView(message: 'Loading your skills...')
            : _errorMessage != null
            ? ErrorView(message: _errorMessage!, onRetry: _loadSkills)
            : _skills.isEmpty
            ? EmptyState(
                icon: Icons.lightbulb_outline,
                title: 'No Skills Added Yet',
                description: 'Showcase your technical and soft skills to prospective employers.',
                actionText: 'Add First Skill',
                onAction: () => _showAddEditSkillDialog(),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _skills.length,
                itemBuilder: (context, index) {
                  final skill = _skills[index];
                  final color = _getLevelColor(skill.level);

                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.code, color: color, size: 22),
                      ),
                      title: Text(
                        skill.skillName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Proficiency: ${skill.level}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                _showAddEditSkillDialog(existingSkill: skill),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppTheme.statusRejected,
                            ),
                            onPressed: () => _deleteSkill(skill),
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
