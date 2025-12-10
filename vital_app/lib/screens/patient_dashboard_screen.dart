import 'package:flutter/material.dart';
import 'patient_profile_screen.dart';
import 'health_metrics_screen.dart';
import 'food_tracking_screen.dart';
import 'exercise_tracking_screen.dart';
import 'medication_checklist_screen.dart';
import 'appointments_calendar_screen.dart';
import 'prescription_approval_screen.dart';
import 'prescription_hub_screen.dart';
import 'search_clinicians_screen.dart';
import 'medical_documents_screen.dart';
import 'ai_adherence_screen.dart';
import 'complete_profile_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;

  // Navigator keys for each stack
  final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _healthNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _careNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _documentsNavigatorKey =
      GlobalKey<NavigatorState>();

  // List of navigator keys corresponding to each tab
  List<GlobalKey<NavigatorState>> get _navigatorKeys => [
    _profileNavigatorKey,
    _healthNavigatorKey,
    _careNavigatorKey,
    _documentsNavigatorKey,
  ];

  void _onTabTapped(int index) {
    // If tapping the same tab, pop to root
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Method to switch to a tab and optionally navigate
  void switchToTab(int index, {String? route}) {
    if (_currentIndex == index && route != null) {
      // Already on this tab, just push the route
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKeys[index].currentState?.pushNamed(route);
      });
    } else {
      // Switch tab first, then navigate
      setState(() {
        _currentIndex = index;
      });
      if (route != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _navigatorKeys[index].currentState?.pushNamed(route);
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Handle back button - pop from current navigator stack
          final currentNavigator = _navigatorKeys[_currentIndex].currentState;
          if (currentNavigator != null && currentNavigator.canPop()) {
            currentNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Profile Stack
            Navigator(
              key: _profileNavigatorKey,
              onGenerateRoute: (settings) {
                Widget screen;
                switch (settings.name) {
                  case '/ai-adherence':
                    screen = const AIAdherenceScreen();
                    break;
                  case '/complete-profile':
                    screen = CompleteProfileScreen(
                      existingProfile:
                          settings.arguments as Map<String, dynamic>?,
                    );
                    break;
                  default:
                    screen = PatientProfileScreen(
                      onNavigateToHealth: (route) =>
                          switchToTab(1, route: route),
                      onNavigateToCare: (route) => switchToTab(2, route: route),
                      onNavigateToDocuments: () => switchToTab(3),
                    );
                }
                return MaterialPageRoute(
                  builder: (context) => screen,
                  settings: settings,
                );
              },
            ),
            // Health Stack
            Navigator(
              key: _healthNavigatorKey,
              onGenerateRoute: (settings) {
                Widget screen;
                switch (settings.name) {
                  case '/food-tracking':
                    screen = const FoodTrackingScreen();
                    break;
                  case '/exercise-tracking':
                    screen = const ExerciseTrackingScreen();
                    break;
                  default:
                    screen = const HealthMetricsScreen();
                }
                return MaterialPageRoute(
                  builder: (context) => screen,
                  settings: settings,
                );
              },
            ),
            // Care Stack
            Navigator(
              key: _careNavigatorKey,
              onGenerateRoute: (settings) {
                Widget screen;
                switch (settings.name) {
                  case '/appointments-calendar':
                    screen = const AppointmentsCalendarScreen();
                    break;
                  case '/prescription-hub':
                    screen = const PrescriptionHubScreen();
                    break;
                  case '/prescription-approval':
                    screen = const PrescriptionApprovalScreen();
                    break;
                  case '/search-clinicians':
                    screen = const SearchCliniciansScreen();
                    break;
                  default:
                    screen = const MedicationChecklistScreen();
                }
                return MaterialPageRoute(
                  builder: (context) => screen,
                  settings: settings,
                );
              },
            ),
            // Documents Stack
            Navigator(
              key: _documentsNavigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => const MedicalDocumentsScreen(),
                  settings: settings,
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          elevation: 8,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Health',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services),
              label: 'Care',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Documents',
            ),
          ],
        ),
      ),
    );
  }
}
