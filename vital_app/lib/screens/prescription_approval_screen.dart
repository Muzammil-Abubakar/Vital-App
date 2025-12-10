import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/prescription_service.dart';
import '../services/daily_tracking_service.dart';
import '../services/auth_service.dart';
import '../theme/patient_theme.dart';

class PrescriptionApprovalScreen extends StatefulWidget {
  const PrescriptionApprovalScreen({super.key});

  @override
  State<PrescriptionApprovalScreen> createState() =>
      _PrescriptionApprovalScreenState();
}

class _PrescriptionApprovalScreenState
    extends State<PrescriptionApprovalScreen> {
  final _prescriptionService = PrescriptionService();
  final _dailyTrackingService = DailyTrackingService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pending Prescriptions')),
        body: const Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      backgroundColor: PatientTheme.surfaceColor,
      appBar: PatientTheme.buildAppBar(
        title: 'Pending Prescriptions',
        backgroundColor: Colors.orange[700]!,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _prescriptionService.getPrescriptionsForPatient(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: PatientTheme.buildCard(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No prescriptions found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          final prescriptions = snapshot.data!.docs;
          final pendingPrescriptions = prescriptions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['approved'] != true;
          }).toList();

          if (pendingPrescriptions.isEmpty) {
            return Center(
              child: PatientTheme.buildCard(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(40),
                gradientColors: [
                  PatientTheme.primaryColor.withValues(alpha: 0.1),
                  PatientTheme.primaryColor.withValues(alpha: 0.05),
                ],
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: PatientTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All prescriptions approved!',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: pendingPrescriptions.length,
            itemBuilder: (context, index) {
              final prescription = pendingPrescriptions[index];
              final data = prescription.data() as Map<String, dynamic>;
              final clinicianName =
                  data['clinicianName'] as String? ?? 'Unknown';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final recommendedFoods = List<String>.from(
                data['recommendedFoods'] ?? [],
              );
              final recommendedExercises = List<String>.from(
                data['recommendedExercises'] ?? [],
              );
              final medicines = List<Map<String, dynamic>>.from(
                data['medicines'] ?? [],
              );
              final appointments = List<Map<String, dynamic>>.from(
                data['appointments'] ?? [],
              );

              return PatientTheme.buildCard(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      PatientTheme.borderRadiusMedium,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(
                        PatientTheme.borderRadiusSmall,
                      ),
                    ),
                    child: Icon(
                      Icons.medical_information,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Prescription from $clinicianName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (createdAt != null)
                        Text(
                          'Date: ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (recommendedFoods.isNotEmpty) ...[
                            _buildSectionHeader('Recommended Foods'),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: recommendedFoods
                                  .map(
                                    (food) => Chip(
                                      label: Text(food),
                                      backgroundColor: PatientTheme.primaryColor
                                          .withValues(alpha: 0.15),
                                      avatar: const Icon(
                                        Icons.restaurant,
                                        size: 18,
                                        color: PatientTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (recommendedExercises.isNotEmpty) ...[
                            _buildSectionHeader('Recommended Exercises'),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: recommendedExercises
                                  .map(
                                    (exercise) => Chip(
                                      label: Text(exercise),
                                      backgroundColor: PatientTheme.primaryColor
                                          .withValues(alpha: 0.15),
                                      avatar: const Icon(
                                        Icons.fitness_center,
                                        size: 18,
                                        color: PatientTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (medicines.isNotEmpty) ...[
                            _buildSectionHeader('Medicines'),
                            ...medicines.map((med) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(
                                    PatientTheme.borderRadiusSmall,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.medication,
                                      size: 20,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med['name'] as String? ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${med['duration']} days, ${med['timesPerDay']} times/day',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                          if (appointments.isNotEmpty) ...[
                            _buildSectionHeader('Appointments'),
                            ...appointments.map((appt) {
                              final apptDate = (appt['date'] as Timestamp)
                                  .toDate();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.teal[50],
                                  borderRadius: BorderRadius.circular(
                                    PatientTheme.borderRadiusSmall,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 20,
                                      color: Colors.teal[700],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appt['title'] as String? ??
                                                'Appointment',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(apptDate),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _rejectPrescription(
                                  context,
                                  prescription.id,
                                ),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () => _approvePrescription(
                                  context,
                                  prescription.id,
                                  data,
                                  createdAt ?? DateTime.now(),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: PatientTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      PatientTheme.borderRadiusSmall,
                                    ),
                                  ),
                                ),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePrescription(
    BuildContext context,
    String prescriptionId,
    Map<String, dynamic> prescriptionData,
    DateTime prescriptionDate,
  ) async {
    // Show loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      debugPrint('Starting prescription approval...');
      debugPrint('Prescription ID: $prescriptionId');
      debugPrint('Prescription Date: $prescriptionDate');

      // Mark prescription as approved first
      debugPrint('Marking prescription as approved...');
      await _prescriptionService.approvePrescription(prescriptionId);
      debugPrint('Prescription marked as approved');

      // Process prescription and create daily tracking documents
      debugPrint('Processing prescription for daily tracking...');
      final medicines = List<Map<String, dynamic>>.from(
        prescriptionData['medicines'] ?? [],
      );
      final appointments = List<Map<String, dynamic>>.from(
        prescriptionData['appointments'] ?? [],
      );

      debugPrint('Medicines count: ${medicines.length}');
      debugPrint('Appointments count: ${appointments.length}');

      await _dailyTrackingService.processApprovedPrescription(
        prescriptionId: prescriptionId,
        prescriptionDate: prescriptionDate,
        medicines: medicines,
        appointments: appointments,
      );
      debugPrint('Daily tracking documents created');

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription approved and added to your tracking!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error approving prescription: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        // Make sure to close loading dialog even on error
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Close loading dialog
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving prescription: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _rejectPrescription(
    BuildContext context,
    String prescriptionId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Prescription'),
        content: const Text(
          'Are you sure you want to reject this prescription? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _prescriptionService.rejectPrescription(prescriptionId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting prescription: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
