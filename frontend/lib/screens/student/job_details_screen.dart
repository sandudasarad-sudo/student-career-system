import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../services/applications_service.dart';
import '../../services/resume_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'resume_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final ApplicationsService _appService = ApplicationsService();
  bool _isCheckingApplied = true;
  bool _hasApplied = false;
  ApplicationModel? _existingApplication;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    try {
      final myApps = await _appService.getApplications();
      final match = myApps.where((a) => a.jobId == widget.job.id).toList();
      if (mounted) {
        setState(() {
          _hasApplied = match.isNotEmpty;
          _existingApplication = match.isNotEmpty ? match.first : null;
          _isCheckingApplied = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingApplied = false);
    }
  }

  void _showApplyModal() async {
    // Verify student has a resume first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final resume = await ResumeService().getMyResume();
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    if (resume == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resume Required'),
          content: const Text(
            'You must create your career resume before applying for jobs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResumeScreen()),
                );
              },
              child: const Text('Build Resume'),
            ),
          ],
        ),
      );
      return;
    }

    final coverController = TextEditingController();
    bool isSubmitting = false;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apply for ${widget.job.title}',
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
              const SizedBox(height: 6),
              Text(
                'Company: ${widget.job.company}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: coverController,
                label: 'Cover Letter (Optional)',
                hint: 'Why are you a great fit for this opportunity?',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.statusSelected,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your active resume will be submitted',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Submit Application',
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setModalState(() => isSubmitting = true);
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await _appService.applyForJob(
                            jobId: widget.job.id,
                            coverLetter: coverController.text.trim(),
                          );
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Application submitted successfully!',
                              ),
                              backgroundColor: AppTheme.statusSelected,
                            ),
                          );
                          if (mounted) {
                            _checkExistingApplication();
                          }
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final deadlineFormatted = DateFormat('dd MMM yyyy')
        .format(widget.job.applicationDeadline);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: _isCheckingApplied
            ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              )
            : widget.job.isExpired
            ? AppButton(
                text: 'Application Deadline Passed',
                onPressed: null,
                variant: AppButtonVariant.outline,
              )
            : _hasApplied
            ? Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.statusSelected.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.statusSelected),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.statusSelected,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Applied (${_existingApplication?.status ?? "Applied"})',
                      style: const TextStyle(
                        color: AppTheme.statusSelected,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              )
            : AppButton(
                text: 'Apply for Job',
                icon: Icons.send,
                onPressed: _showApplyModal,
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Job Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.job.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.job.company,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 15,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.job.location ?? 'Remote',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn('Job Type', widget.job.jobType),
                        _buildInfoColumn('Salary', widget.job.salaryText),
                        _buildInfoColumn('Deadline', deadlineFormatted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.job.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Requirements
            if (widget.job.requirements.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requirements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...widget.job.requirements.map(
                        (req) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 8),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  req,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
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
            const SizedBox(height: 16),

            // Required Skills
            if (widget.job.skills.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skills Expected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.job.skills
                            .map(
                              (s) => Chip(
                                label: Text(s),
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.08),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
