import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class StudentDetailViewScreen extends StatefulWidget {
  final String userId;
  final String? studentName;

  const StudentDetailViewScreen({
    super.key,
    required this.userId,
    this.studentName,
  });

  @override
  State<StudentDetailViewScreen> createState() =>
      _StudentDetailViewScreenState();
}

class _StudentDetailViewScreenState extends State<StudentDetailViewScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  String? _errorMessage;
  ConsolidatedStudentDetails? _details;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadStudentDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _adminService.getStudentDetails(widget.userId);
      if (mounted) {
        setState(() {
          _details = data;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName ?? 'Student 360° Profile'),
        bottom: _details != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  const Tab(text: 'Overview'),
                  Tab(text: 'Skills (${_details?.skills.length ?? 0})'),
                  Tab(text: 'Education (${_details?.education.length ?? 0})'),
                  Tab(text: 'Projects (${_details?.projects.length ?? 0})'),
                  Tab(text: 'Certs (${_details?.certifications.length ?? 0})'),
                  Tab(
                    text:
                        'Applications (${_details?.applications.length ?? 0})',
                  ),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Loading full student record...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadStudentDetails);
    }

    final d = _details;
    if (d == null) {
      return const Center(child: Text('Student information unavailable.'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(d),
        _buildSkillsTab(d),
        _buildEducationTab(d),
        _buildProjectsTab(d),
        _buildCertificationsTab(d),
        _buildApplicationsTab(d),
      ],
    );
  }

  Widget _buildOverviewTab(ConsolidatedStudentDetails d) {
    final s = d.student;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    d.user.name.isNotEmpty ? d.user.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  d.user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  d.user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Role: ${d.user.role.toUpperCase()}',
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Academic details
        Card(
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
                const Text(
                  'Academic & Profile Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (s != null) ...[
                  _buildDetailRow(
                    'College / Institute',
                    s.college ?? 'N/A',
                    Icons.account_balance_outlined,
                  ),
                  _buildDetailRow(
                    'Branch / Stream',
                    s.branch ?? 'N/A',
                    Icons.domain_outlined,
                  ),
                  _buildDetailRow(
                    'Year',
                    s.year != null ? 'Year ${s.year}' : 'N/A',
                    Icons.calendar_today_outlined,
                  ),
                  _buildDetailRow(
                    'CGPA',
                    s.cgpa != null ? s.cgpa.toString() : 'N/A',
                    Icons.grade_outlined,
                  ),
                  _buildDetailRow(
                    'Phone',
                    s.phone ?? 'N/A',
                    Icons.phone_outlined,
                  ),
                  if (s.address != null && s.address!.isNotEmpty) ...[
                    _buildDetailRow(
                      'Address',
                      s.address!,
                      Icons.location_on_outlined,
                    ),
                  ],
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Student has not created their detailed student profile yet.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Resume Preview if built
        if (d.resume != null) ...[
          Card(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Resume',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d.resume!.templateName,
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (d.resume!.summary != null &&
                      d.resume!.summary!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      d.resume!.summary!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsTab(ConsolidatedStudentDetails d) {
    if (d.skills.isEmpty) {
      return const Center(child: Text('No skills recorded by student.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: d.skills.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final sk = d.skills[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Icon(Icons.bolt, color: AppTheme.primaryColor),
            ),
            title: Text(
              sk.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Category: ${sk.category}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sk.proficiency,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEducationTab(ConsolidatedStudentDetails d) {
    if (d.education.isEmpty) {
      return const Center(child: Text('No education history recorded.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: d.education.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final ed = d.education[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Icon(Icons.school, color: AppTheme.primaryColor),
            ),
            title: Text(
              ed.degree,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${ed.institution} (${ed.fieldOfStudy ?? ed.degree})',
            ),
            trailing: Text(
              '${ed.startYear} - ${ed.endYear ?? "Present"}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectsTab(ConsolidatedStudentDetails d) {
    if (d.projects.isEmpty) {
      return const Center(child: Text('No projects recorded.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: d.projects.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final p = d.projects[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (p.technologies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: p.technologies
                        .map(
                          (t) => Chip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCertificationsTab(ConsolidatedStudentDetails d) {
    if (d.certifications.isEmpty) {
      return const Center(child: Text('No certifications recorded.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: d.certifications.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final c = d.certifications[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Icon(
                Icons.workspace_premium,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              c.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Issued by: ${c.issuingOrganization}'),
          ),
        );
      },
    );
  }

  Widget _buildApplicationsTab(ConsolidatedStudentDetails d) {
    if (d.applications.isEmpty) {
      return const Center(child: Text('No job applications submitted yet.'));
    }
    final dateFormat = DateFormat('dd MMM yyyy');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: d.applications.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final a = d.applications[index];
        final statusColor = AppTheme.getStatusColor(a.status);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(
              a.job?.title ?? 'Job Posting',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${a.job?.company ?? "Company"} • Applied ${dateFormat.format(a.appliedAt)}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                a.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
