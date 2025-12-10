import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ai_adherence_service.dart';
import '../services/auth_service.dart';

class AIAdherenceScreen extends StatefulWidget {
  const AIAdherenceScreen({super.key});

  @override
  State<AIAdherenceScreen> createState() => _AIAdherenceScreenState();
}

class _AIAdherenceScreenState extends State<AIAdherenceScreen> {
  final _aiAdherenceService = AIAdherenceService();
  final _authService = AuthService();
  bool _isGenerating = false;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _currentReport;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _aiAdherenceService.getAdherenceReport(_selectedDate);
      if (mounted) {
        setState(() {
          _currentReport = report;
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
            content: Text('Error loading report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final report = await _aiAdherenceService.generateAdherenceReport(_selectedDate);
      if (mounted) {
        setState(() {
          _currentReport = report;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adherence report generated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showDebugPrompt() async {
    try {
      final prompt = await _aiAdherenceService.getPromptForDate(_selectedDate);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange),
              SizedBox(width: 8),
              Text('Debug: AI Prompt'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                prompt,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Copy to clipboard
                // Note: You'll need to add clipboard package or use a simpler approach
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prompt displayed. You can select and copy it.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prompt: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadReport();
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Adherence')),
        body: const Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Adherence Report'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date Card
                    Card(
                      color: Colors.purple.withValues(alpha: 0.1),
                      child: InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.purple),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedDate.day == DateTime.now().day &&
                                  _selectedDate.month == DateTime.now().month &&
                                  _selectedDate.year == DateTime.now().year)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'TODAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Generate Report Button
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateReport,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Generating Report...' : 'Generate Adherence Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Debug Button
                    OutlinedButton.icon(
                      onPressed: _isGenerating ? null : _showDebugPrompt,
                      icon: const Icon(Icons.bug_report, size: 18),
                      label: const Text('View Debug Prompt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Report Display
                    if (_currentReport == null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.assessment_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No report generated yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Generate a report to see your adherence analysis',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Score Card
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    _getScoreColor(_currentReport!['score'] as double)
                                        .withValues(alpha: 0.8),
                                    _getScoreColor(_currentReport!['score'] as double)
                                        .withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Text(
                                    'Adherence Score',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    (_currentReport!['score'] as double)
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'out of 10',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.title,
                                          color: Colors.purple[700], size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Report Title',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _currentReport!['title'] as String? ?? 'Adherence Report',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Report Content Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.description,
                                          color: Colors.purple[700], size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'AI Analysis',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _currentReport!['report'] as String? ??
                                        'No report available.',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                  ),
                                  if (_currentReport!['generatedAt'] != null) ...[
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Generated: ${DateFormat('MMM dd, yyyy • hh:mm a').format(_currentReport!['generatedAt'] as DateTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

