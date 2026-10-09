import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_jobs_screen.dart';
import 'applications_review_screen.dart';
import 'student_management_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  final int initialIndex;

  const AdminMainNavigation({super.key, this.initialIndex = 0});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    ManageJobsScreen(),
    ApplicationsReviewScreen(),
    StudentManagementScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of the Admin portal?',
      confirmText: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _currentIndex == 0
                  ? 'Admin Dashboard'
                  : _currentIndex == 1
                  ? 'Job Postings'
                  : _currentIndex == 2
                  ? 'Review Applications'
                  : 'Student Directory',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: AppTheme.primaryColor,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_center_outlined),
            selectedIcon: Icon(
              Icons.business_center_rounded,
              color: AppTheme.primaryColor,
            ),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(
              Icons.fact_check_rounded,
              color: AppTheme.primaryColor,
            ),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(
              Icons.groups_rounded,
              color: AppTheme.primaryColor,
            ),
            label: 'Students',
          ),
        ],
      ),
    );
  }
}
