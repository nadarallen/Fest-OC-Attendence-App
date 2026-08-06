import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/student.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'roll', 'attendance_asc', 'attendance_desc'
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: 'Search by Name or Roll No',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Name (A-Z)')),
              const PopupMenuItem(value: 'roll', child: Text('Roll No')),
            ],
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.students.isEmpty) {
            return const Center(child: Text('No students registered yet.'));
          }

          // Filter
          List<Student> filteredList = provider.students.where((s) {
            return s.name.toLowerCase().contains(_searchQuery) ||
                   s.rollNumber.toLowerCase().contains(_searchQuery);
          }).toList();

          // Sort
          if (_sortBy == 'name') {
            filteredList.sort((a, b) => a.name.compareTo(b.name));
          } else if (_sortBy == 'roll') {
            filteredList.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final student = filteredList[index];
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
    // Avoid looking up provider if not mounted
    if (!mounted) return;
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
    final bool isLowAttendance = _percentage < 75;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        onTap: () {
          // Show details dialog or navigation could go here
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isLowAttendance ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                child: Text(
                  widget.student.rollNumber.length > 2 
                    ? widget.student.rollNumber.substring(widget.student.rollNumber.length - 2)
                    : widget.student.rollNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLowAttendance ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${widget.student.rollNumber} | ${widget.student.ocDomain}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowAttendance ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_present / $_total Days',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
