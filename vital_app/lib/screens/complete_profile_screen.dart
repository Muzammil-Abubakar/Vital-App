import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'patient_profile_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? existingProfile;

  const CompleteProfileScreen({super.key, this.existingProfile});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Basic Health Metrics
  final _restingHeartRateController = TextEditingController();
  String? _activityLevel;

  // Goals/Preferences
  String? _weightGoal;
  final _dailyStepGoalController = TextEditingController();
  final _dailyCalorieGoalController = TextEditingController();
  final _sleepTargetController = TextEditingController();

  // Health Conditions (Optional) - Now using lists
  List<String> _allergies = [];
  List<String> _chronicConditions = [];
  List<String> _medications = [];
  final _allergyInputController = TextEditingController();
  final _conditionInputController = TextEditingController();
  final _medicationInputController = TextEditingController();

  // Lifestyle Info (Optional)
  String? _dietType;
  String? _smokingStatus;
  final _waterIntakeController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    if (widget.existingProfile != null) {
      _isEditing = true;
      final profile = widget.existingProfile!;

      // Load existing values
      _activityLevel = profile['activityLevel'] as String?;
      _weightGoal = profile['weightGoal'] as String?;
      _dietType = profile['dietType'] as String?;
      _smokingStatus = profile['smokingStatus'] as String?;

      if (profile['restingHeartRate'] != null) {
        _restingHeartRateController.text = profile['restingHeartRate']
            .toString();
      }
      if (profile['dailyStepGoal'] != null) {
        _dailyStepGoalController.text = profile['dailyStepGoal'].toString();
      }
      if (profile['dailyCalorieGoal'] != null) {
        _dailyCalorieGoalController.text = profile['dailyCalorieGoal']
            .toString();
      }
      if (profile['sleepTarget'] != null) {
        _sleepTargetController.text = profile['sleepTarget'].toString();
      }
      if (profile['waterIntake'] != null) {
        _waterIntakeController.text = profile['waterIntake'].toString();
      }

      // Load lists
      if (profile['allergies'] != null) {
        if (profile['allergies'] is List) {
          _allergies = List<String>.from(profile['allergies']);
        } else if (profile['allergies'] is String) {
          _allergies = (profile['allergies'] as String)
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      if (profile['chronicConditions'] != null) {
        if (profile['chronicConditions'] is List) {
          _chronicConditions = List<String>.from(profile['chronicConditions']);
        } else if (profile['chronicConditions'] is String) {
          _chronicConditions = (profile['chronicConditions'] as String)
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      if (profile['medications'] != null) {
        if (profile['medications'] is List) {
          _medications = List<String>.from(profile['medications']);
        } else if (profile['medications'] is String) {
          _medications = (profile['medications'] as String)
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }
  }

  @override
  void dispose() {
    _restingHeartRateController.dispose();
    _dailyStepGoalController.dispose();
    _dailyCalorieGoalController.dispose();
    _sleepTargetController.dispose();
    _allergyInputController.dispose();
    _conditionInputController.dispose();
    _medicationInputController.dispose();
    _waterIntakeController.dispose();
    super.dispose();
  }

  void _addAllergy() {
    final allergy = _allergyInputController.text.trim();
    if (allergy.isNotEmpty && !_allergies.contains(allergy)) {
      setState(() {
        _allergies.add(allergy);
        _allergyInputController.clear();
      });
    }
  }

  void _removeAllergy(int index) {
    setState(() {
      _allergies.removeAt(index);
    });
  }

  void _addCondition() {
    final condition = _conditionInputController.text.trim();
    if (condition.isNotEmpty && !_chronicConditions.contains(condition)) {
      setState(() {
        _chronicConditions.add(condition);
        _conditionInputController.clear();
      });
    }
  }

  void _removeCondition(int index) {
    setState(() {
      _chronicConditions.removeAt(index);
    });
  }

  void _addMedication() {
    final medication = _medicationInputController.text.trim();
    if (medication.isNotEmpty && !_medications.contains(medication)) {
      setState(() {
        _medications.add(medication);
        _medicationInputController.clear();
      });
    }
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields - check for null values
    if (_activityLevel == null || _activityLevel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your activity level')),
      );
      return;
    }

    if (_weightGoal == null || _weightGoal!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your weight goal')),
      );
      return;
    }

    // Check for null values in numeric fields
    if (_dailyStepGoalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your daily step goal')),
      );
      return;
    }

    if (_dailyCalorieGoalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your daily calorie goal')),
      );
      return;
    }

    if (_sleepTargetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your sleep target')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      final profileData = <String, dynamic>{
        'activityLevel': _activityLevel,
        'weightGoal': _weightGoal,
        'dailyStepGoal': int.parse(_dailyStepGoalController.text.trim()),
        'dailyCalorieGoal': int.parse(_dailyCalorieGoalController.text.trim()),
        'sleepTarget': double.parse(_sleepTargetController.text.trim()),
        'allergies': _allergies.isEmpty ? null : _allergies,
        'chronicConditions': _chronicConditions.isEmpty
            ? null
            : _chronicConditions,
        'medications': _medications.isEmpty ? null : _medications,
        'dietType': _dietType,
        'smokingStatus': _smokingStatus,
        'waterIntake': _waterIntakeController.text.trim().isEmpty
            ? null
            : double.tryParse(_waterIntakeController.text.trim()),
        'profiled': true,
      };

      if (_restingHeartRateController.text.trim().isNotEmpty) {
        profileData['restingHeartRate'] = int.tryParse(
          _restingHeartRateController.text.trim(),
        );
      }

      await _authService.updatePatientProfile(
        uid: user.uid,
        profileData: profileData,
      );

      await _authService.markPatientAsProfiled(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Profile updated successfully!'
                  : 'Profile completed successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PatientProfileScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Complete Your Profile'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  _isEditing
                      ? 'Edit Your Health Profile'
                      : 'Complete Your Health Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Help us provide better health recommendations',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Basic Health Metrics Section
                _buildSectionHeader('❤️ Basic Health Metrics'),
                const SizedBox(height: 16),

                // Resting Heart Rate (Optional)
                TextFormField(
                  controller: _restingHeartRateController,
                  decoration: const InputDecoration(
                    labelText: 'Resting Heart Rate (bpm) - Optional',
                    hintText: 'e.g., 70',
                    prefixIcon: Icon(Icons.favorite),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        int.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Activity Level
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _activityLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Activity Level *',
                    prefixIcon: Icon(Icons.directions_run),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'sedentary',
                      child: Text(
                        'Sedentary',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text(
                        'Moderate',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text(
                        'Active',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'very_active',
                      child: Text(
                        'Very Active',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _activityLevel = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your activity level';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Goals/Preferences Section
                _buildSectionHeader('🎯 Goals / Preferences'),
                const SizedBox(height: 16),

                // Weight Goal
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _weightGoal,
                  decoration: const InputDecoration(
                    labelText: 'Weight Goal *',
                    prefixIcon: Icon(Icons.track_changes),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'lose', child: Text('Lose Weight')),
                    DropdownMenuItem(
                      value: 'maintain',
                      child: Text('Maintain Weight'),
                    ),
                    DropdownMenuItem(value: 'gain', child: Text('Gain Weight')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _weightGoal = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your weight goal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Daily Step Goal
                TextFormField(
                  controller: _dailyStepGoalController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Step Goal *',
                    hintText: 'e.g., 10000',
                    prefixIcon: Icon(Icons.directions_walk),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your daily step goal';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Daily Calorie Goal
                TextFormField(
                  controller: _dailyCalorieGoalController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Calorie Goal *',
                    hintText: 'e.g., 2000',
                    prefixIcon: Icon(Icons.local_dining),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your daily calorie goal';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Sleep Target
                TextFormField(
                  controller: _sleepTargetController,
                  decoration: const InputDecoration(
                    labelText: 'Sleep Target (hours) *',
                    hintText: 'e.g., 7.5',
                    prefixIcon: Icon(Icons.bedtime),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your sleep target';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Health Conditions Section (Optional)
                _buildSectionHeader('🩺 Health Conditions (Optional)'),
                const SizedBox(height: 16),

                // Allergies List
                _buildListInputSection(
                  'Allergies',
                  Icons.warning,
                  _allergyInputController,
                  _allergies,
                  _addAllergy,
                  _removeAllergy,
                ),
                const SizedBox(height: 16),

                // Chronic Conditions List
                _buildListInputSection(
                  'Chronic Conditions',
                  Icons.medical_services,
                  _conditionInputController,
                  _chronicConditions,
                  _addCondition,
                  _removeCondition,
                ),
                const SizedBox(height: 16),

                // Medications List
                _buildListInputSection(
                  'Current Medications',
                  Icons.medication,
                  _medicationInputController,
                  _medications,
                  _addMedication,
                  _removeMedication,
                ),
                const SizedBox(height: 32),

                // Lifestyle Info Section (Optional)
                _buildSectionHeader('🍎 Lifestyle Info (Optional)'),
                const SizedBox(height: 16),

                // Diet Type
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _dietType,
                  decoration: const InputDecoration(
                    labelText: 'Diet Type',
                    prefixIcon: Icon(Icons.restaurant),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'vegetarian',
                      child: Text('Vegetarian'),
                    ),
                    DropdownMenuItem(
                      value: 'non_vegetarian',
                      child: Text('Non-Vegetarian'),
                    ),
                    DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                    DropdownMenuItem(value: 'keto', child: Text('Keto')),
                    DropdownMenuItem(value: 'paleo', child: Text('Paleo')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _dietType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Smoking Status
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _smokingStatus,
                  decoration: const InputDecoration(
                    labelText: 'Smoking Status',
                    prefixIcon: Icon(Icons.smoking_rooms),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'never', child: Text('Never')),
                    DropdownMenuItem(
                      value: 'former',
                      child: Text('Former Smoker'),
                    ),
                    DropdownMenuItem(
                      value: 'current',
                      child: Text('Current Smoker'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _smokingStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Water Intake Preference
                TextFormField(
                  controller: _waterIntakeController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Water Intake (liters)',
                    hintText: 'e.g., 2.5',
                    prefixIcon: Icon(Icons.water_drop),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Profile' : 'Complete Profile',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 16),
                  // Skip for now button (only when creating new profile)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const PatientProfileScreen(),
                        ),
                      );
                    },
                    child: const Text('Skip for now'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListInputSection(
    String label,
    IconData icon,
    TextEditingController controller,
    List<String> items,
    VoidCallback onAdd,
    Function(int) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  prefixIcon: Icon(icon),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle),
              color: Colors.green,
              iconSize: 32,
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (index) {
              return Chip(
                label: Text(items[index]),
                onDeleted: () => onRemove(index),
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.green[700],
      ),
    );
  }
}
