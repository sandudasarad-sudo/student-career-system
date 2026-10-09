import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import 'student_detail_view_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  String? _errorMessage;
  AdminDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _adminService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingView(message: 'Loading admin metrics...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadStats);
    }

    final stats = _stats;
    if (stats == null) {
      return const Center(child: Text('No dashboard statistics available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Welcome Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Admin Control Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Overview of user accounts, student career readiness, jobs, and recruitment applications.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // User Breakdown
          _buildSectionTitle('Users & Accounts', Icons.people_alt_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Users',
                  value: stats.totalUsers.toString(),
                  icon: Icons.group,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Students',
                  value: stats.totalStudents.toString(),
                  icon: Icons.school,
                  color: AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Admins',
                  value: stats.totalAdmins.toString(),
                  icon: Icons.security,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Academic & Profile Metrics
          _buildSectionTitle(
            'Student Profiles & Academics',
            Icons.school_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'With Profile',
                  value: stats.studentsWithProfile.toString(),
                  icon: Icons.account_box_outlined,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Resumes Built',
                  value: stats.totalResumes.toString(),
                  icon: Icons.description_outlined,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Average CGPA',
                  value: stats.averageCgpa.toStringAsFixed(2),
                  icon: Icons.grade_outlined,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Career Portfolio Data
          _buildSectionTitle(
            'Career Portfolio Aggregate',
            Icons.folder_shared_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInlineStat('Skills', stats.totalSkills, Icons.bolt),
                  _buildDivider(),
                  _buildInlineStat(
                    'Education',
                    stats.totalEducationRecords,
                    Icons.history_edu,
                  ),
                  _buildDivider(),
                  _buildInlineStat('Projects', stats.totalProjects, Icons.code),
                  _buildDivider(),
                  _buildInlineStat(
                    'Certs',
                    stats.totalCertifications,
                    Icons.workspace_premium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Job Statistics
          _buildSectionTitle('Job Postings', Icons.business_center_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Jobs',
                  value: stats.totalJobs.toString(),
                  icon: Icons.work_outline,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Active',
                  value: stats.activeJobs.toString(),
                  icon: Icons.check_circle_outline,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Expired',
                  value: stats.expiredJobs.toString(),
                  icon: Icons.timer_off_outlined,
                  color: AppTheme.dangerColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Applications Pipeline
          _buildSectionTitle(
            'Applications Pipeline (${stats.totalApplications})',
            Icons.assignment_turned_in_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: stats.applicationStatusCounts.entries.map((
                      entry,
                    ) {
                      final color = AppTheme.getStatusColor(entry.key);
                      return Chip(
                        backgroundColor: color.withOpacity(0.12),
                        avatar: CircleAvatar(
                          backgroundColor: color,
                          radius: 10,
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          entry.key,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Applications
          if (stats.recentApplications.isNotEmpty) ...[
            _buildSectionTitle('Recent Applications', Icons.history),
            const SizedBox(height: 12),
            ...stats.recentApplications.map((app) {
              final statusColor = AppTheme.getStatusColor(app.status);
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.4),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    app.applicantName ?? 'Student Applicant',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    app.job?.title != null
                        ? '${app.job!.title} (${app.job!.company})'
                        : 'Job #${app.jobId}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
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
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Recent Students Registered
          if (stats.recentStudents.isNotEmpty) ...[
            _buildSectionTitle(
              'Recently Joined Students',
              Icons.person_add_alt,
            ),
            const SizedBox(height: 12),
            ...stats.recentStudents.map((stud) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentColor.withOpacity(0.15),
                    child: Text(
                      stud.name.isNotEmpty ? stud.name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    stud.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    stud.email,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentDetailViewScreen(
                          userId: stud.id,
                          studentName: stud.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            radius: 16,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 36, width: 1, color: Colors.grey.shade200);
  }
}
