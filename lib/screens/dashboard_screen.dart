import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../services/csv_service.dart';
import 'scanner_screen.dart';
import 'student_list_screen.dart';

class DashboardScreen extends StatefulWidget {
   const DashboardScreen({super.key});

   @override
   State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
   bool _isExporting = false;

   @override
   void initState() {
     super.initState();
     Future.microtask(() => 
       Provider.of<AttendanceProvider>(context, listen: false).loadStudents()
     );
   }

   void _exportCsv() async {
     setState(() {
       _isExporting = true;
     });
     try {
       final path = await CsvService().exportAttendanceToCsv();
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(
             children: [
               const Icon(Icons.check_circle, color: Colors.white),
               const SizedBox(width: 8),
               Expanded(child: Text('CSV Shared successfully!')),
             ],
           ),
           backgroundColor: Colors.green,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
         ),
       );
     } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(
             children: [
               const Icon(Icons.error, color: Colors.white),
               const SizedBox(width: 8),
               Expanded(child: Text('Export Failed: $e')),
             ],
           ),
           backgroundColor: Colors.redAccent,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
         ),
       );
     } finally {
       if (mounted) {
         setState(() {
           _isExporting = false;
         });
       }
     }
   }

   Future<void> _confirmClearDatabase() async {
     // First confirmation step
     final firstConfirm = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Row(
           children: [
             Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
             SizedBox(width: 8),
             Text('Reset Database?'),
           ],
         ),
         content: const Text(
           'This will permanently delete all student and attendance records from the server. This action cannot be undone.\n\nAre you sure you want to proceed?',
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: const Text('Cancel'),
           ),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
             onPressed: () => Navigator.pop(context, true),
             child: const Text('Proceed', style: TextStyle(color: Colors.white)),
           ),
         ],
       ),
     );

     if (firstConfirm != true || !mounted) return;

     // Second confirmation step (text verification)
     final textController = TextEditingController();
     final secondConfirm = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Confirm Deletion'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text(
               'To confirm, type "DELETE" in the box below to permanently erase the database:',
               style: TextStyle(fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 12),
             TextField(
               controller: textController,
               decoration: const InputDecoration(
                 hintText: 'DELETE',
                 border: OutlineInputBorder(),
               ),
               textCapitalization: TextCapitalization.characters,
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: const Text('Cancel'),
           ),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
             onPressed: () {
               if (textController.text.trim() == 'DELETE') {
                 Navigator.pop(context, true);
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Verification code mismatch!')),
                 );
               }
             },
             child: const Text('Permanently Erase', style: TextStyle(color: Colors.white)),
           ),
         ],
       ),
     );

     if (secondConfirm == true && mounted) {
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (context) => const Center(
           child: Card(
             child: Padding(
               padding: EdgeInsets.all(24.0),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Resetting database, please wait...'),
                 ],
               ),
             ),
           ),
         ),
       );

       try {
         await Provider.of<AttendanceProvider>(context, listen: false).clearAllData();
         if (!mounted) return;
         Navigator.pop(context); // Close loading dialog
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Database reset completed!'),
             backgroundColor: Colors.green,
           ),
         );
       } catch (e) {
         if (!mounted) return;
         Navigator.pop(context); // Close loading dialog
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Failed to clear database: $e'),
             backgroundColor: Colors.redAccent,
           ),
         );
       }
     }
   }

   @override
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     return Scaffold(
       body: CustomScrollView(
         slivers: [
            // Premium Gradient Header
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              actions: [
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      tooltip: 'Logout (${auth.currentUsername ?? ""})',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to log out of your session?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Logout', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          auth.logout();
                        }
                      },
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Unpaid Labours',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withRed(100),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -20,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats & Navigation Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active User & Session Countdown Card
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        final session = auth.session;
                        if (session == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade600,
                                Colors.blue.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Authenticated User: ${auth.currentDisplayName ?? auth.currentUsername}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Session expires in: ${session.formattedRemainingTime}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      '2h max',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Welcome Text
                    Text(
                      'Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                   // Stat Card
                   Consumer<AttendanceProvider>(
                     builder: (context, provider, child) {
                       return Card(
                         color: Colors.white,
                         surfaceTintColor: Colors.white,
                         child: Padding(
                           padding: const EdgeInsets.all(20.0),
                           child: Row(
                             children: [
                               CircleAvatar(
                                 radius: 28,
                                 backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                 child: Icon(
                                   Icons.people_alt_rounded,
                                   color: theme.colorScheme.primary,
                                   size: 28,
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     'Total Registered',
                                     style: theme.textTheme.bodyMedium?.copyWith(
                                       color: Colors.grey[600],
                                     ),
                                   ),
                                   Text(
                                     provider.isLoading
                                         ? '...'
                                         : '${provider.students.length} Students',
                                     style: theme.textTheme.headlineSmall?.copyWith(
                                       fontWeight: FontWeight.bold,
                                       color: theme.colorScheme.primary,
                                     ),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                       );
                     },
                   ),
                   const SizedBox(height: 16),

                   Text(
                     'Quick Actions',
                     style: theme.textTheme.titleMedium?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: const Color(0xFF1E293B),
                     ),
                   ),
                   const SizedBox(height: 12),

                    // Menu buttons
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        _DashboardActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Scan Attendance',
                          description: 'Check-In/Out students',
                          color: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const ScannerScreen()),
                            );
                          },
                        ),
                        _DashboardActionCard(
                          icon: Icons.assignment_rounded,
                          label: 'View Register',
                          description: 'Profiles & Stats',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const StudentListScreen()),
                            );
                          },
                        ),
                        _DashboardActionCard(
                          icon: _isExporting
                              ? Icons.hourglass_top_rounded
                              : Icons.cloud_download_rounded,
                          label: _isExporting ? 'Exporting...' : 'Export CSV',
                          description: 'Share attendance report',
                          color: Colors.amber[800]!,
                          onTap: _isExporting ? () {} : _exportCsv,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
}

class _DashboardActionCard extends StatelessWidget {
   final IconData icon;
   final String label;
   final String description;
   final Color color;
   final VoidCallback onTap;

   const _DashboardActionCard({
     required this.icon,
     required this.label,
     required this.description,
     required this.color,
     required this.onTap,
   });

   @override
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     return Card(
       elevation: 3,
       color: Colors.white,
       surfaceTintColor: Colors.white,
       child: InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(20),
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(icon, size: 30, color: color),
               const SizedBox(height: 8),
               Text(
                 label,
                 style: theme.textTheme.titleMedium?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                   color: const Color(0xFF1E293B),
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
               const SizedBox(height: 2),
               Expanded(
                 child: Text(
                   description,
                   style: theme.textTheme.bodySmall?.copyWith(
                     color: Colors.grey[600],
                     fontSize: 11,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
             ],
           ),
         ),
       ),
     );
   }
}
