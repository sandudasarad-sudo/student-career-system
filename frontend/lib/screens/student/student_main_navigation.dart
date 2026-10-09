import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/login_screen.dart';
import 'student_dashboard_screen.dart';
import 'jobs_screen.dart';
import 'applications_screen.dart';
import 'profile_screen.dart';

class StudentMainNavigation extends StatefulWidget {
  final int initialIndex;

  const StudentMainNavigation({super.key, this.initialIndex = 0});

  @override
  State<StudentMainNavigation> createState() => _StudentMainNavigationState();
}

class _StudentMainNavigationState extends State<StudentMainNavigation> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    StudentDashboardScreen(),
    JobsScreen(),
    ApplicationsScreen(),
    ProfileScreen(),
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
      message: 'Are you sure you want to sign out of your account?',
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
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _currentIndex == 0
                  ? 'Career Portal'
                  : _currentIndex == 1
                  ? 'Browse Jobs'
                  : _currentIndex == 2
                  ? 'My Applications'
                  : 'Student Profile',
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryColor),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              accountName: Text(
                user?.name ?? 'Student',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.of(context).pop();
                _onTabSelected(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_rounded),
              title: const Text('Jobs & Internships'),
              selected: _currentIndex == 1,
              onTap: () {
                Navigator.of(context).pop();
                _onTabSelected(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in_rounded),
              title: const Text('Applications'),
              selected: _currentIndex == 2,
              onTap: () {
                Navigator.of(context).pop();
                _onTabSelected(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Profile'),
              selected: _currentIndex == 3,
              onTap: () {
                Navigator.of(context).pop();
                _onTabSelected(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppTheme.statusRejected,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.statusRejected),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
            ),
          ],
        ),
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
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(
              Icons.work_rounded,
              color: AppTheme.primaryColor,
            ),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(
              Icons.assignment_turned_in_rounded,
              color: AppTheme.primaryColor,
            ),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: AppTheme.primaryColor,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
