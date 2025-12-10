import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/exercise_data_service.dart';
import '../services/prescription_service.dart';
import '../theme/patient_theme.dart';

class ExerciseTrackingScreen extends StatefulWidget {
  const ExerciseTrackingScreen({super.key});

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  final _exerciseDataService = ExerciseDataService();
  final _prescriptionService = PrescriptionService();

  bool _isLoading = true;

  // Exercise data
  List<Map<String, dynamic>> _exercises = [];

  // Recommended exercises from prescriptions
  List<String> _recommendedExercises = [];

  // Controllers for adding new exercise
  final _exerciseTypeController = TextEditingController();
  String _exerciseMode = 'duration'; // 'duration' or 'reps'
  final _durationController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
    _loadRecommendedExercises();
  }

  @override
  void dispose() {
    _exerciseTypeController.dispose();
    _durationController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  Future<void> _loadExerciseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exerciseData = await _exerciseDataService.getTodayExerciseData();

      if (exerciseData != null) {
        setState(() {
          _exercises = List<Map<String, dynamic>>.from(
            exerciseData['exercises'] ?? [],
          );
        });
      } else {
        setState(() {
          _exercises = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercise data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendedExercises() async {
    final user = _prescriptionService.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _prescriptionService
          .getPrescriptionsForPatient(user.uid)
          .first;
      final Set<String> allRecommendedExercises = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final recommendedExercises = List<String>.from(
          data['recommendedExercises'] ?? [],
        );
        allRecommendedExercises.addAll(recommendedExercises);
      }

      if (mounted) {
        setState(() {
          _recommendedExercises = allRecommendedExercises.toList()..sort();
        });
      }
    } catch (e) {
      // Silently fail - recommended exercises are optional
      if (mounted) {
        setState(() {
          _recommendedExercises = [];
        });
      }
    }
  }

  Future<void> _addExercise() async {
    final exerciseType = _exerciseTypeController.text.trim();

    if (exerciseType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an exercise type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic> exerciseData = {
      'type': exerciseType,
      'mode': _exerciseMode,
    };

    if (_exerciseMode == 'duration') {
      final duration = _durationController.text.trim();
      if (duration.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter duration'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final durationValue = int.tryParse(duration);
      if (durationValue == null || durationValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid duration'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      exerciseData['duration'] = durationValue; // in minutes
    } else {
      final reps = _repsController.text.trim();
      final sets = _setsController.text.trim();

      if (reps.isEmpty || sets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both reps and sets'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final repsValue = int.tryParse(reps);
      final setsValue = int.tryParse(sets);

      if (repsValue == null ||
          repsValue <= 0 ||
          setsValue == null ||
          setsValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid reps and sets'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      exerciseData['reps'] = repsValue;
      exerciseData['sets'] = setsValue;
    }

    setState(() {
      _exercises.add(exerciseData);
    });

    _exerciseTypeController.clear();
    _durationController.clear();
    _repsController.clear();
    _setsController.clear();
    _exerciseMode = 'duration';

    // Save to Firestore
    await _saveExerciseData();
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
    _saveExerciseData();
  }

  Future<void> _saveExerciseData() async {
    try {
      await _exerciseDataService.storeDailyExerciseData(exercises: _exercises);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise data saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving exercise data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAddExerciseDialog() {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              PatientTheme.borderRadiusMedium,
            ),
          ),
          title: const Text('Add Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _exerciseTypeController,
                  decoration: InputDecoration(
                    labelText: 'Exercise Type',
                    prefixIcon: const Icon(Icons.fitness_center),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        PatientTheme.borderRadiusSmall,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'duration',
                      label: Text('Duration'),
                      icon: Icon(Icons.timer),
                    ),
                    ButtonSegment(
                      value: 'reps',
                      label: Text('Reps/Sets'),
                      icon: Icon(Icons.repeat),
                    ),
                  ],
                  selected: {_exerciseMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      _exerciseMode = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_exerciseMode == 'duration')
                  TextField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PatientTheme.borderRadiusSmall,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _repsController,
                          decoration: InputDecoration(
                            labelText: 'Reps',
                            prefixIcon: const Icon(Icons.repeat),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                PatientTheme.borderRadiusSmall,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _setsController,
                          decoration: InputDecoration(
                            labelText: 'Sets',
                            prefixIcon: const Icon(Icons.layers),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                PatientTheme.borderRadiusSmall,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exerciseTypeController.clear();
                _durationController.clear();
                _repsController.clear();
                _setsController.clear();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addExercise();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    PatientTheme.borderRadiusSmall,
                  ),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  String _formatExerciseData(Map<String, dynamic> exercise) {
    if (exercise['mode'] == 'duration') {
      return '${exercise['duration']} minutes';
    } else {
      return '${exercise['sets']} sets × ${exercise['reps']} reps';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: PatientTheme.surfaceColor,
        appBar: PatientTheme.buildAppBar(
          title: 'Exercise Tracking',
          backgroundColor: Colors.purple[700]!,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: PatientTheme.surfaceColor,
      appBar: PatientTheme.buildAppBar(
        title: 'Exercise Tracking',
        backgroundColor: Colors.purple[700]!,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExerciseData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadExerciseData();
          await _loadRecommendedExercises();
        },
        color: Colors.purple[700],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Recommended Exercises Section
              if (_recommendedExercises.isNotEmpty) ...[
                PatientTheme.buildCard(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  gradientColors: [
                    PatientTheme.primaryColor.withValues(alpha: 0.1),
                    PatientTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PatientTheme.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                PatientTheme.borderRadiusSmall,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: PatientTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Recommended Exercises',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: PatientTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recommendedExercises.map((exercise) {
                          return Chip(
                            label: Text(exercise),
                            backgroundColor: PatientTheme.primaryColor
                                .withValues(alpha: 0.15),
                            avatar: const Icon(
                              Icons.fitness_center,
                              size: 18,
                              color: PatientTheme.primaryColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Exercises List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _buildAddExerciseDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Exercise'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            PatientTheme.borderRadiusSmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_exercises.isEmpty)
                PatientTheme.buildCard(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No exercises added yet.\nTap "Add Exercise" to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_exercises.length, (index) {
                  final exercise = _exercises[index];
                  return PatientTheme.buildCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(
                            PatientTheme.borderRadiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.purple[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        exercise['type'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _formatExerciseData(exercise),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[300],
                        ),
                        onPressed: () => _removeExercise(index),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
