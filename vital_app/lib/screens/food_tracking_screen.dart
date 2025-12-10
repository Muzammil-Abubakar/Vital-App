import 'package:flutter/material.dart';
import '../services/food_data_service.dart';
import '../services/prescription_service.dart';
import '../theme/patient_theme.dart';

class FoodTrackingScreen extends StatefulWidget {
  const FoodTrackingScreen({super.key});

  @override
  State<FoodTrackingScreen> createState() => _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends State<FoodTrackingScreen> {
  final _foodDataService = FoodDataService();
  final _prescriptionService = PrescriptionService();

  bool _isLoading = true;

  // Food data
  double _totalCalories = 0.0;
  List<Map<String, dynamic>> _foods = [];

  // Recommended foods from prescriptions
  List<String> _recommendedFoods = [];

  // Controllers for adding new food
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedQuantityType = 'serving';
  final List<String> _quantityTypes = [
    'serving',
    'cup',
    'gram (g)',
    'ounce (oz)',
    'piece',
  ];

  // Controller for total calories
  final _totalCaloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoodData();
    _loadRecommendedFoods();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _totalCaloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final foodData = await _foodDataService.getTodayFoodData();

      if (foodData != null) {
        setState(() {
          _totalCalories =
              (foodData['totalCalories'] as num?)?.toDouble() ?? 0.0;
          _foods = List<Map<String, dynamic>>.from(foodData['foods'] ?? []);
          _totalCaloriesController.text = _totalCalories.toStringAsFixed(1);
        });
      } else {
        setState(() {
          _totalCalories = 0.0;
          _foods = [];
          _totalCaloriesController.text = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading food data: $e'),
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

  Future<void> _loadRecommendedFoods() async {
    final user = _prescriptionService.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _prescriptionService
          .getPrescriptionsForPatient(user.uid)
          .first;
      final Set<String> allRecommendedFoods = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final recommendedFoods = List<String>.from(
          data['recommendedFoods'] ?? [],
        );
        allRecommendedFoods.addAll(recommendedFoods);
      }

      if (mounted) {
        setState(() {
          _recommendedFoods = allRecommendedFoods.toList()..sort();
        });
      }
    } catch (e) {
      // Silently fail - recommended foods are optional
      if (mounted) {
        setState(() {
          _recommendedFoods = [];
        });
      }
    }
  }

  Future<void> _addFood() async {
    final foodName = _foodNameController.text.trim();
    final quantity = _quantityController.text.trim();

    if (foodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a food name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (quantity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantityValue = double.tryParse(quantity);
    if (quantityValue == null || quantityValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _foods.add({
        'name': foodName,
        'quantity': quantityValue,
        'quantityType': _selectedQuantityType,
      });
    });

    _foodNameController.clear();
    _quantityController.clear();
    _selectedQuantityType = 'serving';

    // Save to Firestore
    await _saveFoodData();
  }

  void _removeFood(int index) {
    setState(() {
      _foods.removeAt(index);
    });
    _saveFoodData();
  }

  Future<void> _saveFoodData() async {
    try {
      final totalCalories =
          double.tryParse(_totalCaloriesController.text.trim()) ?? 0.0;

      await _foodDataService.storeDailyFoodData(
        totalCalories: totalCalories,
        foods: _foods,
      );

      setState(() {
        _totalCalories = totalCalories;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food data saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving food data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAddFoodDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PatientTheme.borderRadiusMedium),
      ),
      title: const Text('Add Food'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _foodNameController,
              decoration: InputDecoration(
                labelText: 'Food Name',
                prefixIcon: const Icon(Icons.restaurant),
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
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: const Icon(Icons.scale),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PatientTheme.borderRadiusSmall,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedQuantityType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          PatientTheme.borderRadiusSmall,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _quantityTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedQuantityType = value ?? 'serving';
                      });
                    },
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
            _foodNameController.clear();
            _quantityController.clear();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _addFood();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange[700],
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: PatientTheme.surfaceColor,
        appBar: PatientTheme.buildAppBar(
          title: 'Food Tracking',
          backgroundColor: Colors.orange[700]!,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: PatientTheme.surfaceColor,
      appBar: PatientTheme.buildAppBar(
        title: 'Food Tracking',
        backgroundColor: Colors.orange[700]!,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFoodData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFoodData();
          await _loadRecommendedFoods();
        },
        color: Colors.orange[700],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Total Calories Card
              PatientTheme.buildCard(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(
                              PatientTheme.borderRadiusSmall,
                            ),
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Total Calories Eaten',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _totalCaloriesController,
                      decoration: InputDecoration(
                        labelText: 'Total Calories (kcal)',
                        prefixIcon: const Icon(Icons.local_fire_department),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            PatientTheme.borderRadiusSmall,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveFoodData,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Calories'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              PatientTheme.borderRadiusSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Recommended Foods Section
              if (_recommendedFoods.isNotEmpty) ...[
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
                            'Recommended Foods',
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
                        children: _recommendedFoods.map((food) {
                          return Chip(
                            label: Text(food),
                            backgroundColor: PatientTheme.primaryColor
                                .withValues(alpha: 0.15),
                            avatar: const Icon(
                              Icons.restaurant,
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

              // Foods List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Foods Eaten',
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
                          builder: (context) => _buildAddFoodDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Food'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange[700],
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

              if (_foods.isEmpty)
                PatientTheme.buildCard(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No foods added yet.\nTap "Add Food" to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_foods.length, (index) {
                  final food = _foods[index];
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
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(
                            PatientTheme.borderRadiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        food['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${food['quantity']} ${food['quantityType']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[300],
                        ),
                        onPressed: () => _removeFood(index),
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
