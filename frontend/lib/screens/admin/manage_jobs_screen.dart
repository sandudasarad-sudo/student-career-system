import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/job_model.dart';
import '../../services/jobs_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'job_form_screen.dart';

class ManageJobsScreen extends StatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  State<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen> {
  final JobsService _jobsService = JobsService();
  bool _isLoading = true;
  String? _errorMessage;
  List<JobModel> _jobs = [];
  String _searchQuery = '';
  String _filter = 'All'; // 'All', 'Active', 'Inactive', 'Expired'

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _jobsService.getJobs();
      if (mounted) {
        setState(() {
          _jobs = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteJob(JobModel job) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Job Posting',
      message:
          'Are you sure you want to permanently delete "${job.title}" at "${job.company}"?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await _jobsService.deleteJob(job.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job posting deleted.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _loadJobs();
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
      }
    }
  }

  Future<void> _toggleJobStatus(JobModel job) async {
    try {
      await _jobsService.updateJob(job.id, {'isActive': !job.isActive});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !job.isActive
                  ? 'Job "${job.title}" is now active.'
                  : 'Job "${job.title}" is now deactivated.',
            ),
            backgroundColor: AppTheme.infoColor,
          ),
        );
        _loadJobs();
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
    }
  }

  List<JobModel> get _filteredJobs {
    return _jobs.where((j) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          j.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          j.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (j.location != null &&
              j.location!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_filter == 'Active') return j.isActive && !j.isExpired;
      if (_filter == 'Inactive') return !j.isActive;
      if (_filter == 'Expired') return j.isExpired;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Job', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final result = await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const JobFormScreen()));
          if (result == true) {
            _loadJobs();
          }
        },
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by title, company, or location...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Inactive', 'Expired'].map((
                      filter,
                    ) {
                      final isSelected = _filter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _filter = filter;
                            });
                          },
                          selectedColor: AppTheme.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryDark
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Loading job postings...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadJobs);
    }

    final displayed = _filteredJobs;

    if (displayed.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadJobs,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: EmptyState(
                icon: Icons.work_off_outlined,
                title: 'No Job Postings Found',
                message: _searchQuery.isNotEmpty
                    ? 'No jobs match your query "$_searchQuery".'
                    : 'Create your first job posting using the button below.',
                actionText: 'Post New Job',
                onAction: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JobFormScreen()),
                  );
                  if (result == true) {
                    _loadJobs();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: displayed.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = displayed[index];
          final isExpired = job.isExpired;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isExpired
                    ? Colors.red.shade200
                    : !job.isActive
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                              job.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.company,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      _buildStatusBadge(job),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildMetaChip(Icons.category_outlined, job.jobType),
                      if (job.location != null && job.location!.isNotEmpty)
                        _buildMetaChip(
                          Icons.location_on_outlined,
                          job.location!,
                        ),
                      _buildMetaChip(Icons.currency_rupee, job.salaryText),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: isExpired
                            ? AppTheme.dangerColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Deadline: ${dateFormat.format(job.applicationDeadline)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired
                              ? AppTheme.dangerColor
                              : AppTheme.textSecondary,
                          fontWeight: isExpired
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          job.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        label: Text(
                          job.isActive ? 'Deactivate' : 'Activate',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onPressed: () => _toggleJobStatus(job),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobFormScreen(job: job),
                            ),
                          );
                          if (result == true) {
                            _loadJobs();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.dangerColor,
                        ),
                        tooltip: 'Delete Job',
                        onPressed: () => _deleteJob(job),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(JobModel job) {
    if (job.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.dangerColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'EXPIRED',
          style: TextStyle(
            color: AppTheme.dangerColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (!job.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'INACTIVE',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(
          color: AppTheme.successColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
