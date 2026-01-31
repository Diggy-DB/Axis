import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _coreValuesController;
  late TextEditingController _worldviewController;
  late TextEditingController _ambitionController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _coreValuesController = TextEditingController(text: user?.coreValues ?? '');
    _worldviewController = TextEditingController(text: user?.worldview ?? '');
    _ambitionController = TextEditingController(text: user?.ambition ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coreValuesController.dispose();
    _worldviewController.dispose();
    _ambitionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          displayName: _nameController.text.trim(),
          coreValues: _coreValuesController.text.trim().isEmpty 
              ? null 
              : _coreValuesController.text.trim(),
          worldview: _worldviewController.text.trim().isEmpty 
              ? null 
              : _worldviewController.text.trim(),
          ambition: _ambitionController.text.trim().isEmpty 
              ? null 
              : _ambitionController.text.trim(),
        );

        await authProvider.updateUserProfile(updatedUser);

        if (mounted) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEditing() {
    final user = context.read<AuthProvider>().user;
    setState(() {
      _nameController.text = user?.name ?? '';
      _coreValuesController.text = user?.coreValues ?? '';
      _worldviewController.text = user?.worldview ?? '';
      _ambitionController.text = user?.ambition ?? '';
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save', style: TextStyle(fontSize: 16)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Member since ${DateFormat('MMMM yyyy').format(user.createdAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Name
                  Text(
                    'Personal Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Personal Values & Goals
                  Text(
                    'Values & Ambitions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These help our AI provide personalized insights and motivation',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _coreValuesController,
                    decoration: const InputDecoration(
                      labelText: 'Core Values',
                      hintText: 'e.g., Integrity, Growth, Family, Innovation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.favorite),
                      helperText: 'What principles guide your life?',
                    ),
                    maxLines: 2,
                    enabled: _isEditing,
                  ),
                  
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _worldviewController,
                    decoration: const InputDecoration(
                      labelText: 'Worldview',
                      hintText: 'e.g., Optimistic, Pragmatic, Growth-oriented',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      helperText: 'How do you see the world?',
                    ),
                    maxLines: 2,
                    enabled: _isEditing,
                  ),
                  
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _ambitionController,
                    decoration: const InputDecoration(
                      labelText: 'Life Ambition',
                      hintText: 'e.g., Build a successful business, Make a positive impact',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.rocket_launch),
                      helperText: 'What are you working towards?',
                    ),
                    maxLines: 3,
                    enabled: _isEditing,
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: const Icon(Icons.check),
                            label: const Text('Save Changes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _cancelEditing,
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Account Stats
                  Text(
                    'Account Statistics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _StatCard(
                    icon: Icons.calendar_month,
                    title: 'Account Age',
                    value: '${DateTime.now().difference(user.createdAt).inDays} days',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.verified_user,
                    title: 'Email Verified',
                    value: user.emailVerified ? 'Yes' : 'No',
                    color: user.emailVerified ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
