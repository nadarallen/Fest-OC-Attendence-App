import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/student.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Register')),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.students.isEmpty) {
            return const Center(child: Text('No students registered yet.'));
          }

          return ListView.builder(
            itemCount: provider.students.length,
            itemBuilder: (context, index) {
              final student = provider.students[index];
              return _StudentListItem(student: student);
            },
          );
        },
      ),
    );
  }
}

class _StudentListItem extends StatefulWidget {
  final Student student;
  const _StudentListItem({required this.student});

  @override
  State<_StudentListItem> createState() => _StudentListItemState();
}

class _StudentListItemState extends State<_StudentListItem> {
  double _percentage = 0.0;
  int _present = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final stats = await provider.getAttendancePercentage(widget.student.rollNumber);
    if (mounted) {
      setState(() {
        _percentage = stats['percentage']!;
        _present = stats['present']!.toInt();
        _total = stats['total']!.toInt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(widget.student.rollNumber.length > 2 ? widget.student.rollNumber.substring(0, 2).toUpperCase() : widget.student.rollNumber),
        ),
        title: Text('${widget.student.name} (${widget.student.rollNumber})'),
        subtitle: Text('Dept: ${widget.student.department} | Sem: ${widget.student.semester}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _percentage < 75 ? Colors.red : Colors.green,
                fontSize: 16,
              ),
            ),
            Text(
              'P: $_present / T: $_total',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
