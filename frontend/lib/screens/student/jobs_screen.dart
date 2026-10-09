import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/job_model.dart';
import '../../services/jobs_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'job_details_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobsService _jobsService = JobsService();
  List<JobModel> _allJobs = [];
  List<JobModel> _filteredJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedJobType = 'All';

  final List<String> _filterTypes = [
    'All',
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
    'Remote',
  ];

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
      final jobs = await _jobsService.getJobs();
      setState(() {
        _allJobs = jobs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _allJobs.where((job) {
        final matchesQuery =
            _searchQuery.isEmpty ||
            job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            job.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (job.location != null &&
                job.location!.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                )) ||
            job.skills.any(
              (s) => s.toLowerCase().contains(_searchQuery.toLowerCase()),
            );

        final matchesType =
            _selectedJobType == 'All' || job.jobType == _selectedJobType;

        return matchesQuery && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search jobs, companies, skills...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterTypes.map((type) {
                      final isSelected = _selectedJobType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedJobType = type;
                                _applyFilters();
                              });
                            }
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(
                            0.12,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
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

          // Job list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadJobs,
              child: _isLoading
                  ? const LoadingView(message: 'Loading active job listings...')
                  : _errorMessage != null
                  ? ErrorView(message: _errorMessage!, onRetry: _loadJobs)
                  : _filteredJobs.isEmpty
                  ? EmptyState(
                      icon: Icons.work_off_outlined,
                      title: 'No Jobs Found',
                      description: _allJobs.isEmpty
                          ? 'No active job opportunities posted yet. Please check back later!'
                          : 'No jobs match your current search or filter criteria.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _filteredJobs.length,
                      itemBuilder: (context, index) {
                        final job = _filteredJobs[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobDetailsScreen(job: job),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.business,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              job.company,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor
                                              .withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          job.jobType,
                                          style: const TextStyle(
                                            color: AppTheme.secondaryColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    job.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (job.skills.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: job.skills
                                          .take(4)
                                          .map(
                                            (s) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                s,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 15,
                                            color: AppTheme.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            job.location ?? 'Remote',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        job.salaryText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
