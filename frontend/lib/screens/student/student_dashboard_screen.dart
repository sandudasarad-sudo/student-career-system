import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/skills_service.dart';
import '../../services/education_service.dart';
import '../../services/projects_service.dart';
import '../../services/certifications_service.dart';
import '../../services/resume_service.dart';
import '../../services/applications_service.dart';
import '../../services/jobs_service.dart';
import '../../widgets/loading_view.dart';
import 'skills_screen.dart';
import 'education_screen.dart';
import 'projects_screen.dart';
import 'certifications_screen.dart';
import 'resume_screen.dart';
import 'job_details_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isLoading = true;
  int _skillsCount = 0;
  int _educationCount = 0;
  int _projectsCount = 0;
  int _certsCount = 0;
  bool _hasResume = false;
  int _applicationsCount = 0;
  List<JobModel> _recentJobs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        SkillsService().getSkills(),
        EducationService().getEducations(),
        ProjectsService().getProjects(),
        CertificationsService().getCertifications(),
        ResumeService().getMyResume(),
        ApplicationsService().getApplications(),
        JobsService().getJobs(),
      ]);

      if (!mounted) return;

      setState(() {
        _skillsCount = (results[0] as List).length;
        _educationCount = (results[1] as List).length;
        _projectsCount = (results[2] as List).length;
        _certsCount = (results[3] as List).length;
        _hasResume = results[4] != null;
        _applicationsCount = (results[5] as List).length;
        final allJobs = results[6] as List<JobModel>;
        _recentJobs = allJobs.take(3).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateCompleteness() {
    int score = 0;
    if (_skillsCount > 0) score += 20;
    if (_educationCount > 0) score += 20;
    if (_projectsCount > 0) score += 20;
    if (_certsCount > 0) score += 20;
    if (_hasResume) score += 20;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final completeness = _calculateCompleteness();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: _isLoading
          ? const LoadingView(message: 'Loading your career overview...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Header Card
                  Card(
                    color: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                radius: 24,
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${user?.name ?? 'Student'} 👋',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Ready to take your career to the next level?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Completeness bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profile Completeness',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$completeness%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: completeness / 100,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981), // Emerald
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Career Modules Grid
                  const Text(
                    'Career Portfolio',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _buildMetricCard(
                        icon: Icons.code,
                        color: AppTheme.primaryLight,
                        title: 'Skills',
                        value: '$_skillsCount Added',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SkillsScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),
                      _buildMetricCard(
                        icon: Icons.school,
                        color: const Color(0xFF8B5CF6),
                        title: 'Education',
                        value: '$_educationCount Records',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EducationScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),
                      _buildMetricCard(
                        icon: Icons.folder,
                        color: const Color(0xFFF59E0B),
                        title: 'Projects',
                        value: '$_projectsCount Projects',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProjectsScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),
                      _buildMetricCard(
                        icon: Icons.verified,
                        color: AppTheme.secondaryColor,
                        title: 'Certifications',
                        value: '$_certsCount Certs',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CertificationsScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),
                      _buildMetricCard(
                        icon: Icons.description,
                        color: const Color(0xFF0284C7),
                        title: 'Resume',
                        value: _hasResume ? 'Active' : 'Not Created',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResumeScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),
                      _buildMetricCard(
                        icon: Icons.assignment_turned_in,
                        color: const Color(0xFF10B981),
                        title: 'Applications',
                        value: '$_applicationsCount Submitted',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Job Openings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Job Openings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_recentJobs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No active job postings at the moment.\nCheck back soon!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._recentJobs.map(
                      (job) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.work,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            job.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                '${job.company} • ${job.location ?? 'Remote'}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      job.jobType,
                                      style: const TextStyle(
                                        color: AppTheme.secondaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    job.salaryText,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailsScreen(job: job),
                              ),
                            ).then((_) => _loadDashboardData());
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
