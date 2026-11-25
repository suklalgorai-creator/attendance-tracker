import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subject.dart';
import '../core/services/database_service.dart';
import '../core/utils/attendance_calculator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final list = DatabaseService.getSubjects();
    if (list.isEmpty) {
      // Seed initial subjects if first time
      final defaultSubjects = [
        Subject(id: '1', name: 'Operating Systems', attended: 24, total: 28),
        Subject(id: '2', name: 'Database Management', attended: 22, total: 30),
        Subject(id: '3', name: 'Computer Networks', attended: 18, total: 26),
        Subject(id: '4', name: 'Software Engineering', attended: 26, total: 28),
      ];
      DatabaseService.saveSubjects(defaultSubjects);
      setState(() => _subjects = defaultSubjects);
    } else {
      setState(() => _subjects = list);
    }
  }

  void _markAttendance(Subject subject, bool isPresent) {
    setState(() {
      subject.total += 1;
      if (isPresent) {
        subject.attended += 1;
      }
    });
    DatabaseService.saveSubjects(_subjects);
  }

  void _deleteSubject(Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${subject.name}?'),
        content: const Text('Are you sure you want to remove this subject?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              DatabaseService.deleteSubject(subject.id);
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    double target = 75.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g. Machine Learning',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final navigator = Navigator.of(ctx);
                final newSub = Subject(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  attended: 0,
                  total: 0,
                  targetPercentage: target,
                );
                await DatabaseService.addSubject(newSub);
                navigator.pop();
                _loadData();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _shareOverallStatus() {
    final totalAttended = _subjects.fold<int>(0, (sum, s) => sum + s.attended);
    final totalClasses = _subjects.fold<int>(0, (sum, s) => sum + s.total);
    final overallPct = totalClasses > 0
        ? ((totalAttended / totalClasses) * 100).toStringAsFixed(1)
        : '100';

    final text =
        '🎓 My College Attendance is $overallPct%!\n'
        'Check if you can safely bunk your next class with College Attendance Tracker App.\n'
        'Download now: https://suklalgorai.dev/apps/attendance';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final totalAttended = _subjects.fold<int>(0, (sum, s) => sum + s.attended);
    final totalClasses = _subjects.fold<int>(0, (sum, s) => sum + s.total);
    final double overallPercentage = totalClasses > 0
        ? (totalAttended / totalClasses) * 100
        : 100.0;
    final bool isOverallSafe = overallPercentage >= 75.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        title: Text(
          'College Attendance',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Attendance Score',
            onPressed: _shareOverallStatus,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectDialog,
        backgroundColor: const Color(0xFF2878FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subject'),
      ),
      body: CustomScrollView(
        slivers: [
          // Overall Summary Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2878FF), Color(0xFF7955ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2878FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Attendance',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${overallPercentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isOverallSafe
                                ? '✓ Safe from Detain (>= 75%)'
                                : '⚠ Warning: Below 75% target',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$totalAttended/$totalClasses',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subjects Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Subjects (${_subjects.length})',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF171725),
                    ),
                  ),
                  Text(
                    '75% Rule Applied',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF646477),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subjects List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final subject = _subjects[index];
              final metrics = AttendanceCalculator.evaluate(
                attended: subject.attended,
                total: subject.total,
                target: subject.targetPercentage,
              );

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: metrics.isSafe
                        ? const Color(0xFF2878FF).withValues(alpha: 0.12)
                        : const Color(0xFFFF5F56).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF171725).withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Name and Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subject.name,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF171725),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: metrics.isSafe
                                ? const Color(0xFFEAF7F4)
                                : const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${metrics.percentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: metrics.isSafe
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE63946),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Status & Stats Row
                    Text(
                      'Attended: ${subject.attended} / ${subject.total} classes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF646477),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: subject.total > 0
                            ? (subject.attended / subject.total).clamp(0.0, 1.0)
                            : 1.0,
                        backgroundColor: const Color(0xFFEEF0FF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          metrics.isSafe
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE63946),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Safe Bunk Advice Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            metrics.isSafe
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            size: 15,
                            color: metrics.isSafe
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE63946),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              metrics.statusMessage,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: metrics.isSafe
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFE63946),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons Row (+ Present, - Absent)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _markAttendance(subject, true),
                            icon: const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            label: Text(
                              'Present',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF10B981)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _markAttendance(subject, false),
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFFE63946),
                            ),
                            label: Text(
                              'Absent',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFE63946),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE63946)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFF86869A),
                            size: 20,
                          ),
                          onPressed: () => _deleteSubject(subject),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }, childCount: _subjects.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
