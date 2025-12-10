import 'package:flutter/material.dart';
import '../theme/patient_theme.dart';

class PrescriptionHubScreen extends StatelessWidget {
  const PrescriptionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientTheme.surfaceColor,
      appBar: PatientTheme.buildAppBar(
        title: 'Prescriptions',
        backgroundColor: Colors.orange[700]!,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Header Card
            PatientTheme.buildCard(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              gradientColors: [
                Colors.orange[100]!.withValues(alpha: 0.5),
                Colors.orange[50]!.withValues(alpha: 0.3),
              ],
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(
                        PatientTheme.borderRadiusMedium,
                      ),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      size: 48,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manage Your Prescriptions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request new prescriptions or review pending ones',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Create Prescription Request Card
                  PatientTheme.buildCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    onTap: () {
                      Navigator.of(context).pushNamed('/search-clinicians');
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PatientTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(
                              PatientTheme.borderRadiusSmall,
                            ),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            size: 32,
                            color: PatientTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request Prescription',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search for a clinician and request a new prescription',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                  // Approve Prescription Card
                  PatientTheme.buildCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    onTap: () {
                      Navigator.of(context).pushNamed('/prescription-approval');
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(
                              PatientTheme.borderRadiusSmall,
                            ),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 32,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Approve Prescription',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Review and approve pending prescriptions from clinicians',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
