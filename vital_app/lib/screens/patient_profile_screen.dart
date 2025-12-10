import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/patient_migration_service.dart';
import 'user_type_selection_screen.dart';
import 'complete_profile_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  final void Function(String?)? onNavigateToHealth;
  final void Function(String?)? onNavigateToCare;
  final VoidCallback? onNavigateToDocuments;

  const PatientProfileScreen({
    super.key,
    this.onNavigateToHealth,
    this.onNavigateToCare,
    this.onNavigateToDocuments,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _authService = AuthService();
  final _migrationService = PatientMigrationService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  // Professional wellness color palette
  static const Color _primaryColor = Color(0xFF4CAF50); // Green
  static const Color _accentColor = Color(0xFF81C784); // Light Green
  static const Color _secondaryColor = Color(0xFF2196F3); // Blue
  static const Color _surfaceColor = Color(0xFFF5F7FA);

  // Mock gamification data (frontend only)
  final Map<String, dynamic> _gamificationData = {
    'wellnessScore': 78, // Out of 100
    'level': 5,
    'xp': 2450,
    'xpToNextLevel': 3000,
    'streaks': {'medication': 12, 'healthTracking': 8, 'exercise': 5},
    'badges': [
      {'name': 'Medication Master', 'icon': Icons.medication, 'earned': true},
      {'name': 'Health Tracker', 'icon': Icons.favorite, 'earned': true},
      {
        'name': 'Exercise Enthusiast',
        'icon': Icons.fitness_center,
        'earned': false,
      },
      {
        'name': 'Consistency Champion',
        'icon': Icons.trending_up,
        'earned': true,
      },
    ],
    'weeklyGoals': {
      'medicationAdherence': 85,
      'healthLogging': 90,
      'exerciseMinutes': 65,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No user logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final needsMigration = await _migrationService
          .currentPatientNeedsMigration();
      if (needsMigration) {
        await _migrationService.migrateCurrentPatient();
      }

      if (!mounted) return;
      final profile = await _authService.getUserProfile(user.uid, 'patient');
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const UserTypeSelectionScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _userProfile == null
          ? _buildEmptyState()
          : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No profile data found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final isProfiled = _userProfile!['profiled'] == true;

    return CustomScrollView(
      slivers: [
        // App Bar with Gradient
        SliverAppBar(
          expandedHeight: 220,
          floating: false,
          pinned: true,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleSignOut,
              tooltip: 'Sign Out',
            ),
          ],
          flexibleSpace: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final isCollapsed = constraints.biggest.height <= 120;
              return FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(
                  left: isCollapsed ? 16 : 0,
                  bottom: isCollapsed ? 16 : 0,
                ),
                centerTitle: false,
                title: isCollapsed
                    ? Text(
                        _userProfile!['name'] ?? 'Profile',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox.shrink(),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryColor, _accentColor],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50, bottom: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Avatar with Stack
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 41,
                                  backgroundColor: _primaryColor,
                                  child: Text(
                                    (_userProfile!['name']?[0] ?? 'P')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (isProfiled)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _secondaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name - centered below avatar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _userProfile!['name'] ?? 'Patient',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Email - centered below name
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _userProfile!['email'] ??
                                  _authService.currentUser?.email ??
                                  '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wellness Score Card (Gamification)
                    _buildWellnessScoreCard(),
                    const SizedBox(height: 20),

                    // Profile Completion Banner
                    if (!isProfiled) ...[
                      _buildProfileCompletionBanner(),
                      const SizedBox(height: 20),
                    ],

                    // Quick Stats Cards
                    _buildQuickStatsRow(),
                    const SizedBox(height: 20),

                    // Profile Information Card
                    _buildProfileInfoCard(),
                    const SizedBox(height: 20),

                    // Action Buttons Grid
                    _buildActionButtonsGrid(),
                    const SizedBox(height: 20),

                    // Achievements Section (Gamification)
                    if (isProfiled) ...[
                      _buildAchievementsSection(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessScoreCard() {
    final score = _gamificationData['wellnessScore'] as int;
    final level = _gamificationData['level'] as int;
    final xp = _gamificationData['xp'] as int;
    final xpToNext = _gamificationData['xpToNextLevel'] as int;
    final progress = xp / xpToNext;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withValues(alpha: 0.1),
              _secondaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wellness Score',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _secondaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: _secondaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Level $level',
                        style: TextStyle(
                          color: _secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // XP Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to Level ${level + 1}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '$xp / $xpToNext XP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionBanner() {
    return Card(
      elevation: 0,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock AI Adherence and personalized recommendations',
                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CompleteProfileScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    final streaks = _gamificationData['streaks'] as Map<String, dynamic>;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.medication,
            label: 'Medication',
            value: '${streaks['medication']} days',
            color: _secondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            label: 'Tracking',
            value: '${streaks['healthTracking']} days',
            color: Colors.pink[300]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center,
            label: 'Exercise',
            value: '${streaks['exercise']} days',
            color: Colors.purple[300]!,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person, color: _primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Age',
              value: _userProfile!['age']?.toString() ?? 'Not set',
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value:
                  _userProfile!['email'] ??
                  _authService.currentUser?.email ??
                  'Not set',
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.badge,
              label: 'Role',
              value: 'Patient',
              valueColor: _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              icon: Icons.auto_awesome,
              label: 'AI Adherence',
              color: Colors.purple,
              enabled: _userProfile!['profiled'] == true,
              onTap: () {
                if (_userProfile!['profiled'] == true) {
                  Navigator.of(context).pushNamed('/ai-adherence');
                }
              },
            ),
            _buildActionCard(
              icon: Icons.edit,
              label: 'Edit Profile',
              color: _secondaryColor,
              onTap: () async {
                await _loadUserProfile();
                if (!mounted) return;
                final profile = _userProfile;
                if (profile != null) {
                  if (!mounted) return;
                  Navigator.of(context)
                      .pushNamed('/complete-profile', arguments: profile)
                      .then((_) {
                        if (mounted) {
                          _loadUserProfile();
                        }
                      });
                }
              },
            ),
            _buildActionCard(
              icon: Icons.favorite,
              label: 'Health Metrics',
              color: Colors.pink[300]!,
              onTap: () {
                widget.onNavigateToHealth?.call(null);
              },
            ),
            _buildActionCard(
              icon: Icons.restaurant,
              label: 'Food Tracking',
              color: Colors.orange[400]!,
              onTap: () {
                widget.onNavigateToHealth?.call('/food-tracking');
              },
            ),
            _buildActionCard(
              icon: Icons.fitness_center,
              label: 'Exercise',
              color: Colors.purple[400]!,
              onTap: () {
                widget.onNavigateToHealth?.call('/exercise-tracking');
              },
            ),
            _buildActionCard(
              icon: Icons.checklist,
              label: 'Medications',
              color: Colors.indigo[400]!,
              onTap: () {
                widget.onNavigateToCare?.call(null);
              },
            ),
            _buildActionCard(
              icon: Icons.calendar_today,
              label: 'Appointments',
              color: Colors.teal[400]!,
              onTap: () {
                widget.onNavigateToCare?.call('/appointments-calendar');
              },
            ),
            _buildActionCard(
              icon: Icons.medical_services,
              label: 'Prescriptions',
              color: _primaryColor,
              onTap: () {
                widget.onNavigateToCare?.call('/prescription-hub');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: enabled ? null : Colors.grey[100],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withValues(alpha: 0.15)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.black87 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final badges = _gamificationData['badges'] as List<dynamic>;
    final earnedBadges = badges.where((b) => b['earned'] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${earnedBadges.length}/${badges.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              final isEarned = badge['earned'] == true;
              return Container(
                width: 90,
                margin: EdgeInsets.only(
                  right: index < badges.length - 1 ? 12 : 0,
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isEarned ? Colors.amber[200]! : Colors.grey[200]!,
                      width: isEarned ? 2 : 1,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isEarned
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.amber[50]!, Colors.amber[100]!],
                            )
                          : null,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          badge['icon'] as IconData,
                          color: isEarned
                              ? Colors.amber[700]
                              : Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge['name'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isEarned
                                ? Colors.amber[900]
                                : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
