import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'student_detail_view_screen.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<UserModel> _studentUsers = [];
  List<StudentModel> _studentProfiles = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userResult = await _adminService.getUsers(
        role: 'student',
        limit: 50,
      );
      final profileResult = await _adminService.getStudents(limit: 50);

      if (mounted) {
        setState(() {
          _studentUsers = (userResult['users'] as List<UserModel>?) ?? [];
          _studentProfiles =
              (profileResult['students'] as List<StudentModel>?) ?? [];
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

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _studentUsers;
    final q = _searchQuery.toLowerCase();
    return _studentUsers.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  List<StudentModel> get _filteredProfiles {
    if (_searchQuery.isEmpty) return _studentProfiles;
    final q = _searchQuery.toLowerCase();
    return _studentProfiles.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.branch != null && s.branch!.toLowerCase().contains(q)) ||
          (s.college != null && s.college!.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by student name, email, branch, college...',
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
          ),

          // Tabs: All Students vs Profiles Created
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'All Students (${_studentUsers.length})'),
              Tab(text: 'With Profiles (${_studentProfiles.length})'),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const LoadingView(message: 'Loading student directory...')
                : _errorMessage != null
                ? ErrorView(message: _errorMessage!, onRetry: _loadData)
                : TabBarView(
                    controller: _tabController,
                    children: [_buildUsersList(), _buildProfilesList()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    final list = _filteredUsers;
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                icon: Icons.person_search_outlined,
                title: 'No Students Found',
                message: _searchQuery.isNotEmpty
                    ? 'No registered students match "$_searchQuery".'
                    : 'No student accounts registered yet.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final u = list[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                u.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                u.email,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentDetailViewScreen(
                      userId: u.id,
                      studentName: u.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilesList() {
    final list = _filteredProfiles;
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                icon: Icons.badge_outlined,
                title: 'No Student Profiles Found',
                message: _searchQuery.isNotEmpty
                    ? 'No profiles match "$_searchQuery".'
                    : 'No student career profiles created yet.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = list[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.accentColor.withValues(alpha: 0.15),
                child: const Icon(Icons.school, color: AppTheme.accentColor),
              ),
              title: Text(
                s.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    'Branch: ${s.branch ?? "N/A"} • ${s.college ?? "College N/A"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (s.cgpa != null)
                    Text(
                      'CGPA: ${s.cgpa}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              onTap: () {
                final targetUserId = s.userId.isNotEmpty ? s.userId : s.id;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentDetailViewScreen(
                      userId: targetUserId,
                      studentName: s.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
