import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/application_model.dart';
import '../../services/applications_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'student_detail_view_screen.dart';

class ApplicationsReviewScreen extends StatefulWidget {
  const ApplicationsReviewScreen({super.key});

  @override
  State<ApplicationsReviewScreen> createState() =>
      _ApplicationsReviewScreenState();
}

class _ApplicationsReviewScreenState extends State<ApplicationsReviewScreen> {
  final ApplicationsService _applicationsService = ApplicationsService();
  bool _isLoading = true;
  String? _errorMessage;
  List<ApplicationModel> _applications = [];
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _applicationsService.getApplications();
      if (mounted) {
        setState(() {
          _applications = list;
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

  List<ApplicationModel> get _filteredApplications {
    return _applications.where((app) {
      final matchesStatus =
          _selectedStatus == 'All' || app.status == _selectedStatus;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (app.applicantName != null &&
              app.applicantName!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) ||
          (app.applicantEmail != null &&
              app.applicantEmail!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) ||
          (app.job?.title != null &&
              app.job!.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) ||
          (app.job?.company != null &&
              app.job!.company.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ));

      return matchesStatus && matchesSearch;
    }).toList();
  }

  void _showReviewDialog(ApplicationModel app) {
    String currentStatus = app.status;
    final notesController = TextEditingController(text: app.adminNotes ?? '');
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Review Application',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Applicant: ${app.applicantName ?? "Unknown"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Job: ${app.job?.title ?? "Job"} @ ${app.job?.company ?? "Company"}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: currentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Application Status *',
                        prefixIcon: Icon(Icons.rule),
                      ),
                      items: ApplicationModel.adminAllowedStatuses
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            currentStatus = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: notesController,
                      labelText: 'Admin Evaluation Notes',
                      hintText: 'Add interview notes, feedback, or internal comments...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    if (app.userId.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: const Icon(Icons.badge_outlined, size: 18),
                        label: const Text('View Full Student Portfolio (360°)'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentDetailViewScreen(
                                userId: app.userId,
                                studentName: app.applicantName,
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Save Status Update',
                      isLoading: isUpdating,
                      icon: Icons.check,
                      onPressed: () async {
                        setSheetState(() {
                          isUpdating = true;
                        });
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        try {
                          await _applicationsService.updateStatusAdmin(
                            app.id,
                            status: currentStatus,
                            adminNotes: notesController.text.trim().isNotEmpty
                                ? notesController.text.trim()
                                : null,
                          );
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Application updated successfully.',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                          if (mounted) {
                            _loadApplications();
                          }
                        } catch (e) {
                          setSheetState(() {
                            isUpdating = false;
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: AppTheme.dangerColor,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search applicant, role, or company...',
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
                    children: ['All', ...ApplicationModel.adminAllowedStatuses]
                        .map((status) {
                          final isSelected = _selectedStatus == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedStatus = status;
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
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(child: _buildList(dateFormat)),
        ],
      ),
    );
  }

  Widget _buildList(DateFormat dateFormat) {
    if (_isLoading) {
      return const LoadingView(message: 'Loading submitted applications...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadApplications);
    }

    final displayed = _filteredApplications;

    if (displayed.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadApplications,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No Applications Found',
                message: _searchQuery.isNotEmpty || _selectedStatus != 'All'
                    ? 'No applications match your selected filter criteria.'
                    : 'There are currently no job applications in the system.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: displayed.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final app = displayed[index];
          final statusColor = AppTheme.getStatusColor(app.status);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryLight.withOpacity(0.5),
                        child: Text(
                          app.applicantName != null &&
                                  app.applicantName!.isNotEmpty
                              ? app.applicantName![0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.applicantName ?? 'Applicant',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (app.applicantEmail != null)
                              Text(
                                app.applicantEmail!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          app.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.job?.title ?? 'Job Posting',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          app.job?.company ?? 'Company',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Applied on: ${dateFormat.format(app.appliedAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cover letter snippet
                  if (app.coverLetter != null &&
                      app.coverLetter!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Cover Letter: "${app.coverLetter}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Admin notes
                  if (app.adminNotes != null && app.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notes,
                            size: 14,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Notes: ${app.adminNotes}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (app.userId.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text(
                            'View Profile',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentDetailViewScreen(
                                  userId: app.userId,
                                  studentName: app.applicantName,
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text(
                          'Review',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _showReviewDialog(app),
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
}
