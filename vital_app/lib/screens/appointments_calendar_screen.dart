import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/appointment_tracking_service.dart';
import '../theme/patient_theme.dart';

class AppointmentsCalendarScreen extends StatefulWidget {
  const AppointmentsCalendarScreen({super.key});

  @override
  State<AppointmentsCalendarScreen> createState() =>
      _AppointmentsCalendarScreenState();
}

class _AppointmentsCalendarScreenState
    extends State<AppointmentsCalendarScreen> {
  final _appointmentTrackingService = AppointmentTrackingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAppointments = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await _appointmentTrackingService
          .getAppointmentsWithStatus();

      if (mounted) {
        setState(() {
          _allAppointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAppointmentAttended(
    Map<String, dynamic> appointment,
  ) async {
    try {
      await _appointmentTrackingService.markAppointmentAttended(
        prescriptionId: appointment['prescriptionId'] as String,
        appointmentId: appointment['appointmentId'] as String,
        appointmentDate: appointment['date'] as DateTime,
      );

      await _loadAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment marked as attended!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    return _allAppointments.where((appt) {
      final apptDate = appt['date'] as DateTime;
      return apptDate.year == day.year &&
          apptDate.month == day.month &&
          apptDate.day == day.day;
    }).toList();
  }

  List<Map<String, dynamic>> _getUpcomingAppointments() {
    return _allAppointments
        .where((appt) => appt['isUpcoming'] == true)
        .toList();
  }

  List<Map<String, dynamic>> _getMissedAppointments() {
    return _allAppointments.where((appt) => appt['isMissed'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: PatientTheme.surfaceColor,
        appBar:
            AppBar(
                  title: const Text('Appointments Calendar'),
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  bottom: TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
                      Tab(icon: Icon(Icons.upcoming), text: 'Upcoming'),
                      Tab(icon: Icon(Icons.warning), text: 'Missed'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadAppointments,
                      tooltip: 'Refresh',
                    ),
                  ],
                )
                as PreferredSizeWidget,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Calendar View
                  RefreshIndicator(
                    onRefresh: _loadAppointments,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            calendarFormat: _calendarFormat,
                            eventLoader: _getAppointmentsForDay,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              outsideDaysVisible: false,
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: true,
                              titleCentered: true,
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Appointments for selected day
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'Appointments on ${DateFormat('MMMM dd, yyyy').format(_selectedDay)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._getAppointmentsForDay(_selectedDay).map((
                                  appt,
                                ) {
                                  return _buildAppointmentCard(appt);
                                }),
                                if (_getAppointmentsForDay(
                                  _selectedDay,
                                ).isEmpty)
                                  PatientTheme.buildCard(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No appointments on this day.',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Upcoming Appointments
                  RefreshIndicator(
                    onRefresh: _loadAppointments,
                    color: Colors.teal[700],
                    child: _getUpcomingAppointments().isEmpty
                        ? Center(
                            child: PatientTheme.buildCard(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.upcoming_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No upcoming appointments.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            itemCount: _getUpcomingAppointments().length,
                            itemBuilder: (context, index) {
                              return _buildAppointmentCard(
                                _getUpcomingAppointments()[index],
                              );
                            },
                          ),
                  ),

                  // Missed Appointments
                  RefreshIndicator(
                    onRefresh: _loadAppointments,
                    color: Colors.teal[700],
                    child: _getMissedAppointments().isEmpty
                        ? Center(
                            child: PatientTheme.buildCard(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No missed appointments.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            itemCount: _getMissedAppointments().length,
                            itemBuilder: (context, index) {
                              return _buildAppointmentCard(
                                _getMissedAppointments()[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final title = appointment['title'] as String;
    final date = appointment['date'] as DateTime;
    final isAttended = appointment['isAttended'] == true;
    final isMissed = appointment['isMissed'] == true;
    final clinicianName = appointment['clinicianName'] as String;

    Color cardColor;
    IconData statusIcon;
    String statusText;

    if (isAttended) {
      cardColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Attended';
    } else if (isMissed) {
      cardColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Missed';
    } else {
      cardColor = Colors.blue;
      statusIcon = Icons.upcoming;
      statusText = 'Upcoming';
    }

    return PatientTheme.buildCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      gradientColors: [
        cardColor.withValues(alpha: 0.1),
        cardColor.withValues(alpha: 0.05),
      ],
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(PatientTheme.borderRadiusSmall),
          ),
          child: Icon(statusIcon, color: cardColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('MMMM dd, yyyy • hh:mm a').format(date)}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Clinician: $clinicianName',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  PatientTheme.borderRadiusSmall,
                ),
              ),
              child: Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        trailing: isAttended
            ? Icon(
                Icons.check_circle,
                color: PatientTheme.primaryColor,
                size: 28,
              )
            : isMissed
            ? null
            : IconButton(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: PatientTheme.primaryColor,
                ),
                onPressed: () => _markAppointmentAttended(appointment),
                tooltip: 'Mark as Attended',
              ),
        isThreeLine: true,
      ),
    );
  }
}
