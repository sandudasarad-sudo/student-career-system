import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/student_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_view.dart';
import 'skills_screen.dart';
import 'education_screen.dart';
import 'projects_screen.dart';
import 'certifications_screen.dart';
import 'resume_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StudentService _studentService = StudentService();
  StudentModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _skillsController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedGender = 'Male';

  static const String _keyProfileId = 'saved_student_profile_id';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _cgpaController.dispose();
    _skillsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';

    final prefs = await SharedPreferences.getInstance();
    final profileId = prefs.getString(_keyProfileId);

    if (profileId != null && profileId.isNotEmpty) {
      try {
        final profile = await _studentService.getProfileById(profileId);
        if (profile != null) {
          _profile = profile;
          _populateControllers(profile);
        }
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  void _populateControllers(StudentModel profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone ?? '';
    _collegeController.text = profile.college ?? '';
    _branchController.text = profile.branch ?? '';
    _yearController.text = profile.year?.toString() ?? '';
    _cgpaController.text = profile.cgpa?.toString() ?? '';
    _skillsController.text = profile.skills.join(', ');
    _addressController.text = profile.address ?? '';
    if (profile.gender != null &&
        ['Male', 'Female', 'Other'].contains(profile.gender)) {
      _selectedGender = profile.gender!;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final skillsList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final model = StudentModel(
      id: _profile?.id ?? '',
      userId: '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _selectedGender,
      college: _collegeController.text.trim(),
      branch: _branchController.text.trim(),
      year: int.tryParse(_yearController.text),
      cgpa: double.tryParse(_cgpaController.text),
      skills: skillsList,
      address: _addressController.text.trim(),
    );

    try {
      StudentModel saved;
      if (_profile != null && _profile!.id.isNotEmpty) {
        saved = await _studentService.updateProfile(_profile!.id, model);
      } else {
        saved = await _studentService.createProfile(model);
      }

      // Save ID locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfileId, saved.id);

      setState(() {
        _profile = saved;
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: AppTheme.statusSelected,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingView(message: 'Loading student profile...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Portfolio Shortcuts Card
          Card(
            color: AppTheme.primaryColor.withOpacity(0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Career Modules',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickNav(
                        icon: Icons.code,
                        label: 'Skills',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SkillsScreen(),
                          ),
                        ),
                      ),
                      _buildQuickNav(
                        icon: Icons.school,
                        label: 'Education',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EducationScreen(),
                          ),
                        ),
                      ),
                      _buildQuickNav(
                        icon: Icons.folder,
                        label: 'Projects',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProjectsScreen(),
                          ),
                        ),
                      ),
                      _buildQuickNav(
                        icon: Icons.verified,
                        label: 'Certs',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CertificationsScreen(),
                          ),
                        ),
                      ),
                      _buildQuickNav(
                        icon: Icons.description,
                        label: 'Resume',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResumeScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Profile Form Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          _profile != null
                              ? 'Edit Student Profile'
                              : 'Create Student Profile',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _emailController,
                      label: 'Email *',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v?.trim().isEmpty == true
                          ? 'Email is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc, size: 20),
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedGender = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _collegeController,
                      label: 'College / University',
                      prefixIcon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _branchController,
                            label: 'Branch / Major',
                            prefixIcon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _yearController,
                            label: 'Year of Study',
                            hint: '1 - 4',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _cgpaController,
                      label: 'Current CGPA',
                      hint: 'e.g. 8.4',
                      prefixIcon: Icons.grade_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _skillsController,
                      label: 'Key Skills (comma separated)',
                      hint: 'Python, Flutter, React, SQL',
                      prefixIcon: Icons.star_border,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _addressController,
                      label: 'Address / City',
                      prefixIcon: Icons.home_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    AppButton(
                      text: _profile != null
                          ? 'Update Profile'
                          : 'Create Profile',
                      isLoading: _isSaving,
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNav({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
