import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/user_account.dart';
import '../services/totp_service.dart';
import '../services/auth_service.dart';

class SetupQrScreen extends StatefulWidget {
  const SetupQrScreen({super.key});

  @override
  State<SetupQrScreen> createState() => _SetupQrScreenState();
}

class _SetupQrScreenState extends State<SetupQrScreen> {
  final AuthService _authService = AuthService();
  List<UserAccount> _users = UserAccount.defaultUsers;
  late UserAccount _selectedUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; });
    final loadedUsers = await _authService.getAuthorizedUsersAsync();
    setState(() {
      _users = loadedUsers;
      _selectedUser = loadedUsers.first;
      _isLoading = false;
    });
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _selectedUser.displayName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User Name (${_selectedUser.username})'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name / User Identifier',
            hintText: 'Enter name (e.g. Allen, Gate 1, Coordinator)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _authService.updateDisplayName(_selectedUser.username, newName);
                if (!mounted) return;
                Navigator.pop(context);
                await _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated user name to "$newName"')),
                );
              }
            },
            child: const Text('Save Name'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final keyUri = TotpService.generateKeyUri(
      username: _selectedUser.displayName,
      secret: _selectedUser.totpSecret,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorized User Setup'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Info Card
            Card(
              color: Colors.blue.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Each of the 4 authorized users can edit their name and scan their QR code into Google Authenticator.',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Selection Dropdown
            Text(
              'Select User Account:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserAccount>(
                  value: _users.firstWhere(
                    (u) => u.username == _selectedUser.username,
                    orElse: () => _users.first,
                  ),
                  isExpanded: true,
                  items: _users.map((user) {
                    return DropdownMenuItem<UserAccount>(
                      value: user,
                      child: Text(
                        '${user.displayName} (${user.username})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newUser) {
                    if (newUser != null) {
                      setState(() {
                        _selectedUser = newUser;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code Container Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedUser.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, size: 22),
                          tooltip: 'Edit User Name',
                          onPressed: _showEditNameDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan with Google Authenticator',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR Code Display
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double qrSize = (constraints.maxWidth * 0.65).clamp(140.0, 190.0);
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: keyUri,
                            version: QrVersions.auto,
                            size: qrSize,
                            backgroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Secret Key Text & Copy Button
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Secret: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SelectableText(
                          _selectedUser.totpSecret,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Copy Secret Key',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _selectedUser.totpSecret));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied secret key for ${_selectedUser.displayName}'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions Steps
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Setup Instructions:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              number: '1',
              text: 'Optionally tap the edit icon to customize your display name.',
            ),
            _buildInstructionStep(
              number: '2',
              text: 'Install Google Authenticator (or any TOTP app) on your mobile device.',
            ),
            _buildInstructionStep(
              number: '3',
              text: 'Open the app, tap "+" and scan the QR code displayed above.',
            ),
            _buildInstructionStep(
              number: '4',
              text: 'Log in using your name and current 6-digit authenticator code.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF6366F1),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
