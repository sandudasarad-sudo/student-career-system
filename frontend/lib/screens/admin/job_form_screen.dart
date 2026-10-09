import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/job_model.dart';
import '../../services/jobs_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class JobFormScreen extends StatefulWidget {
  final JobModel? job;

  const JobFormScreen({super.key, this.job});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobsService = JobsService();

  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _skillsController;
  late TextEditingController _salaryMinController;
  late TextEditingController _salaryMaxController;
  late TextEditingController _externalUrlController;

  late String _jobType;
  late DateTime _deadline;
  late bool _isActive;
  bool _isSaving = false;

  bool get isEditing => widget.job != null;

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _titleController = TextEditingController(text: j?.title ?? '');
    _companyController = TextEditingController(text: j?.company ?? '');
    _locationController = TextEditingController(text: j?.location ?? '');
    _descriptionController = TextEditingController(text: j?.description ?? '');
    _requirementsController = TextEditingController(
      text: j?.requirements.join('\n') ?? '',
    );
    _skillsController = TextEditingController(text: j?.skills.join(', ') ?? '');
    _salaryMinController = TextEditingController(
      text: j?.salaryMin != null ? j!.salaryMin.toString() : '',
    );
    _salaryMaxController = TextEditingController(
      text: j?.salaryMax != null ? j!.salaryMax.toString() : '',
    );
    _externalUrlController = TextEditingController(
      text: j?.externalApplyUrl ?? '',
    );

    _jobType = j?.jobType ?? 'Full-time';
    _deadline =
        j?.applicationDeadline ?? DateTime.now().add(const Duration(days: 30));
    _isActive = j?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _skillsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final reqList = _requirementsController.text
          .split(RegExp(r'[\n,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final skillsList = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final num? minSal = _salaryMinController.text.trim().isNotEmpty
          ? num.tryParse(_salaryMinController.text.trim())
          : null;

      final num? maxSal = _salaryMaxController.text.trim().isNotEmpty
          ? num.tryParse(_salaryMaxController.text.trim())
          : null;

      if (isEditing) {
        final updateMap = <String, dynamic>{
          'title': _titleController.text.trim(),
          'company': _companyController.text.trim(),
          'jobType': _jobType,
          'description': _descriptionController.text.trim(),
          'requirements': reqList,
          'skills': skillsList,
          'applicationDeadline': _deadline.toIso8601String(),
          'isActive': _isActive,
        };
        if (_locationController.text.trim().isNotEmpty) {
          updateMap['location'] = _locationController.text.trim();
        }
        if (minSal != null) updateMap['salaryMin'] = minSal;
        if (maxSal != null) updateMap['salaryMax'] = maxSal;
        if (_externalUrlController.text.trim().isNotEmpty) {
          updateMap['externalApplyUrl'] = _externalUrlController.text.trim();
        }

        await _jobsService.updateJob(widget.job!.id, updateMap);
      } else {
        final newJob = JobModel(
          id: '',
          createdBy: '',
          title: _titleController.text.trim(),
          company: _companyController.text.trim(),
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          jobType: _jobType,
          description: _descriptionController.text.trim(),
          requirements: reqList,
          skills: skillsList,
          salaryMin: minSal,
          salaryMax: maxSal,
          applicationDeadline: _deadline,
          externalApplyUrl: _externalUrlController.text.trim().isNotEmpty
              ? _externalUrlController.text.trim()
              : null,
          isActive: _isActive,
        );

        await _jobsService.createJob(newJob);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Job updated successfully!'
                  : 'Job created successfully!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Job Posting' : 'Post New Job'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _titleController,
                labelText: 'Job Title *',
                hintText: 'e.g. Senior Flutter Developer',
                prefixIcon: const Icon(Icons.work_outline),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Job title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _companyController,
                labelText: 'Company Name *',
                hintText: 'e.g. Google, Infosys, Tech Corp',
                prefixIcon: const Icon(Icons.business_outlined),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _locationController,
                labelText: 'Location',
                hintText: 'e.g. Bengaluru / Remote / Hybrid',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _jobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: JobModel.allowedJobTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _jobType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descriptionController,
                labelText: 'Job Description *',
                hintText:
                    'Describe role responsibilities and qualifications...',
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Job description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _requirementsController,
                labelText: 'Requirements (one per line)',
                hintText: 'e.g.\n3+ years Flutter experience\nStrong Dart knowledge\nRESTful API integration',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _skillsController,
                labelText: 'Required Skills (comma separated)',
                hintText: 'e.g. Flutter, Dart, Node.js, Git',
                prefixIcon: const Icon(Icons.bolt_outlined),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _salaryMinController,
                      labelText: 'Min Salary',
                      hintText: 'e.g. 500000',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _salaryMaxController,
                      labelText: 'Max Salary',
                      hintText: 'e.g. 1000000',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Application Deadline Picker
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Application Deadline *',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(_deadline),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_calendar,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _externalUrlController,
                labelText: 'External Apply URL (Optional)',
                hintText: 'https://company.com/careers/job-123',
                prefixIcon: const Icon(Icons.link_outlined),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isActive,
                title: const Text(
                  'Job Listing Active',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isActive
                      ? 'Students can see and apply for this job'
                      : 'Hidden from public student job feeds',
                  style: const TextStyle(fontSize: 12),
                ),
                activeThumbColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _isActive = val;
                  });
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                text: isEditing ? 'Update Job Posting' : 'Publish Job Posting',
                isLoading: _isSaving,
                icon: Icons.check_circle_outline,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
