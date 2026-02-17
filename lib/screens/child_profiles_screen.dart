import 'package:flutter/material.dart';
import '../models/child_profile_model.dart';
import '../services/storage_service.dart';

class ChildProfilesScreen extends StatefulWidget {
  const ChildProfilesScreen({super.key});

  @override
  State<ChildProfilesScreen> createState() => _ChildProfilesScreenState();
}

class _ChildProfilesScreenState extends State<ChildProfilesScreen> {
  final StorageService _storageService = StorageService();
  List<ChildProfileModel> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _storageService.getChildProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _switchProfile(ChildProfileModel profile) async {
    try {
      // Deactivate all profiles
      final updatedProfiles = _profiles.map((p) {
        return p.copyWith(isActive: p.id == profile.id);
      }).toList();
      
      await _storageService.saveChildProfiles(updatedProfiles);
      
      setState(() {
        _profiles = updatedProfiles;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${profile.name}\'s profile'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfile(ChildProfileModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete ${profile.name}\'s profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updatedProfiles = _profiles.where((p) => p.id != profile.id).toList();
        await _storageService.saveChildProfiles(updatedProfiles);
        
        setState(() {
          _profiles = updatedProfiles;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddProfileDialog() {
    _showProfileDialog();
  }

  void _showEditProfileDialog(ChildProfileModel profile) {
    _showProfileDialog(existingProfile: profile);
  }

  void _showProfileDialog({ChildProfileModel? existingProfile}) {
    final isEdit = existingProfile != null;
    final nameController = TextEditingController(text: existingProfile?.name ?? '');
    final ageController = TextEditingController(
      text: existingProfile != null ? '${existingProfile.age}' : '',
    );
    final timeLimitController = TextEditingController(
      text: '${existingProfile?.dailyTimeLimitMinutes ?? 60}',
    );
    final topicsController = TextEditingController(
      text: existingProfile?.preferredTopics.join(', ') ?? '',
    );
    final blockedController = TextEditingController(
      text: existingProfile?.blockedKeywords.join(', ') ?? '',
    );
    bool calmModeEnabled = existingProfile?.calmModeEnabled ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Child Profile' : 'Add Child Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter child\'s name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    hintText: 'Enter age',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Time Limit (minutes)',
                    hintText: 'e.g., 60',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: topicsController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Topics',
                    hintText: 'e.g., math, animals, drawing',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: blockedController,
                  decoration: const InputDecoration(
                    labelText: 'Blocked Keywords',
                    hintText: 'e.g., scary, horror, fight',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Calm Mode'),
                  subtitle: const Text('Lower visual stimulation for this child'),
                  value: calmModeEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      calmModeEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || ageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in name and age'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final parsedAge = int.tryParse(ageController.text.trim()) ?? 5;
                final parsedLimit = int.tryParse(timeLimitController.text.trim()) ?? 60;
                final preferredTopics = topicsController.text
                    .split(',')
                    .map((topic) => topic.trim().toLowerCase())
                    .where((topic) => topic.isNotEmpty)
                    .toSet()
                    .toList();
                final blockedKeywords = blockedController.text
                    .split(',')
                    .map((word) => word.trim().toLowerCase())
                    .where((word) => word.isNotEmpty)
                    .toSet()
                    .toList();

                final profile = ChildProfileModel(
                  id: existingProfile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  age: parsedAge,
                  dailyTimeLimitMinutes: parsedLimit,
                  preferredTopics: preferredTopics,
                  blockedKeywords: blockedKeywords,
                  calmModeEnabled: calmModeEnabled,
                  createdAt: existingProfile?.createdAt,
                  isActive: existingProfile?.isActive ?? _profiles.isEmpty,
                );

                try {
                  late final List<ChildProfileModel> updatedProfiles;
                  if (isEdit) {
                    updatedProfiles = _profiles
                        .map((p) => p.id == profile.id ? profile : p)
                        .toList();
                  } else {
                    updatedProfiles = [..._profiles, profile];
                  }
                  await _storageService.saveChildProfiles(updatedProfiles);
                  setState(() {
                    _profiles = updatedProfiles;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? '${profile.name}\'s profile updated'
                            : '${profile.name}\'s profile created',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Child Profiles'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProfileDialog,
            tooltip: 'Add Profile',
          ),
        ],
      ),
      body: _profiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No profiles yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a child profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddProfileDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Profile'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return _buildProfileCard(profile);
              },
            ),
    );
  }

  Widget _buildProfileCard(ChildProfileModel profile) {
    return Card(
      elevation: profile.isActive ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: profile.isActive
            ? BorderSide(color: profile.profileColor, width: 2.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _switchProfile(profile),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: profile.profileColor,
                    child: profile.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              profile.avatarUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  profile.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            profile.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Profile Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (profile.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${profile.age} years old • ${profile.ageGroup}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showEditProfileDialog(profile),
                        tooltip: 'Edit Profile',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteProfile(profile),
                        tooltip: 'Delete Profile',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Profile options summary (dynamic, not fixed/hardcoded to 3 tiles)
              Wrap(
                spacing: 20,
                runSpacing: 10,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    Icons.timer,
                    '${profile.dailyTimeLimitMinutes}m',
                    'Daily Limit',
                    Colors.blue,
                  ),
                  _buildStatChip(
                    Icons.interests_outlined,
                    '${profile.preferredTopics.length}',
                    'Interests',
                    Colors.purple,
                  ),
                  _buildStatChip(
                    Icons.block,
                    '${profile.blockedKeywords.length}',
                    'Blocked',
                    Colors.red,
                  ),
                  _buildStatChip(
                    Icons.visibility,
                    profile.calmModeEnabled ? 'ON' : 'OFF',
                    'Calm Mode',
                    profile.calmModeEnabled ? Colors.teal : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

