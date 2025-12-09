import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  final Health _health = Health();

  // Health data types we want to track
  final List<HealthDataType> _healthDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.HEART_RATE,
  ];

  // Check if Health Connect is installed (Android only)
  Future<bool> isHealthConnectInstalled() async {
    try {
      await _health.configure();
      // Try to check permissions - if Health Connect is not installed, this will fail
      final hasPermissions = await _health.hasPermissions(_healthDataTypes);
      return hasPermissions != null;
    } catch (e) {
      // If Health Connect is not installed, configure will throw an error
      return false;
    }
  }

  // Request Health Connect permissions
  Future<bool> requestPermissions() async {
    try {
      await _health.configure();
      
      // Request activity recognition permission first (required for steps)
      await Permission.activityRecognition.request();
      
      // Request Health Connect permissions
      final requested = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: [
          HealthDataAccess.READ_WRITE,
          HealthDataAccess.READ_WRITE,
          HealthDataAccess.READ_WRITE,
          HealthDataAccess.READ_WRITE,
        ],
      );
      
      return requested;
    } catch (e) {
      return false;
    }
  }

  // Check if permissions are granted
  Future<bool?> hasPermissions() async {
    try {
      await _health.configure();
      return await _health.hasPermissions(_healthDataTypes);
    } catch (e) {
      return false;
    }
  }

  // Get health data for today
  Future<Map<String, dynamic>> getTodayHealthData() async {
    try {
      await _health.configure();
      
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      // Get steps
      int? steps;
      try {
        steps = await _health.getTotalStepsInInterval(midnight, now);
      } catch (e) {
        steps = null;
      }
      
      // Get calories burned (active energy)
      double? calories;
      try {
        final caloriesData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: midnight,
          endTime: now,
        );
        if (caloriesData.isNotEmpty) {
          double totalCalories = 0;
          for (var dataPoint in caloriesData) {
            if (dataPoint.value is NumericHealthValue) {
              totalCalories += (dataPoint.value as NumericHealthValue).numericValue;
            }
          }
          calories = totalCalories;
        }
      } catch (e) {
        calories = null;
      }
      
      // Get sleep (hours slept)
      double? hoursSlept;
      try {
        final sleepData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_ASLEEP],
          startTime: midnight,
          endTime: now,
        );
        if (sleepData.isNotEmpty) {
          double totalMinutes = 0;
          for (var dataPoint in sleepData) {
            if (dataPoint.value is NumericHealthValue) {
              totalMinutes += (dataPoint.value as NumericHealthValue).numericValue;
            }
          }
          hoursSlept = totalMinutes / 60.0; // Convert minutes to hours
        }
      } catch (e) {
        hoursSlept = null;
      }
      
      // Get heart rate (average for today)
      double? heartRate;
      try {
        final heartRateData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: midnight,
          endTime: now,
        );
        if (heartRateData.isNotEmpty) {
          double totalHeartRate = 0;
          int count = 0;
          for (var dataPoint in heartRateData) {
            if (dataPoint.value is NumericHealthValue) {
              totalHeartRate += (dataPoint.value as NumericHealthValue).numericValue;
              count++;
            }
          }
          heartRate = count > 0 ? totalHeartRate / count : null;
        }
      } catch (e) {
        heartRate = null;
      }
      
      return {
        'steps': steps,
        'caloriesBurned': calories,
        'hoursSlept': hoursSlept,
        'heartRate': heartRate,
      };
    } catch (e) {
      return {
        'steps': null,
        'caloriesBurned': null,
        'hoursSlept': null,
        'heartRate': null,
      };
    }
  }

  // Write manual health data
  Future<bool> writeManualHealthData({
    required int steps,
    required double calories,
    required double hoursSlept,
    required double heartRate,
  }) async {
    try {
      await _health.configure();
      final now = DateTime.now();
      
      bool success = true;
      
      // Write steps
      success &= await _health.writeHealthData(
        value: steps.toDouble(),
        type: HealthDataType.STEPS,
        startTime: now,
        endTime: now,
      );
      
      // Write calories
      success &= await _health.writeHealthData(
        value: calories,
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        startTime: now,
        endTime: now,
      );
      
      // Write sleep (convert hours to minutes)
      success &= await _health.writeHealthData(
        value: hoursSlept * 60,
        type: HealthDataType.SLEEP_ASLEEP,
        startTime: now,
        endTime: now,
      );
      
      // Write heart rate
      success &= await _health.writeHealthData(
        value: heartRate,
        type: HealthDataType.HEART_RATE,
        startTime: now,
        endTime: now,
      );
      
      return success;
    } catch (e) {
      return false;
    }
  }
}

