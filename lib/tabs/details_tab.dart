import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../pages/admin_create_user_page.dart';
import '../providers/user_provider.dart';

class DetailsTab extends StatefulWidget {
  final String userId;

  const DetailsTab({super.key, required this.userId});

  @override
  createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> {
  late Future<UserModel?> _userFuture;

  // Controllers for all fields including optional ones
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isEditing = false; // Toggle editing mode
  bool _isLoading = false; // Show loading indicator during save

  @override
  void initState() {
    super.initState();
    _userFuture = UserProvider().fetchUserDetails();
  }

  void _populateFields(UserModel user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _surnameController.text = user.surname ?? '';
    _ageController.text = user.age?.toString() ?? '';
    _referenceController.text = user.reference ?? '';
    _notesController.text = user.notes ?? '';
  }

  Future<void> _saveChanges(UserModel originalUser) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final updatedUser = UserModel(
      userId: originalUser.userId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: originalUser.password,
      role: originalUser.role,
      createdAt: originalUser.createdAt,
      surname: _surnameController.text.trim().isNotEmpty
          ? _surnameController.text.trim()
          : null,
      age: _ageController.text.trim().isNotEmpty
          ? int.tryParse(_ageController.text.trim())
          : null,
      reference: _referenceController.text.trim().isNotEmpty
          ? _referenceController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      if (originalUser.email != updatedUser.email) {
        // If email has changed, perform migration
        final success = await UserProvider().updateEmailAndMigrate(
          oldUid: originalUser.userId,
          oldEmail: originalUser.email,
          password: CreateUserPage.tempPw,
          newEmail: updatedUser.email,
          updatedUser: updatedUser,
        );

        if (success) {
          _showMessageDialog('Başarılı',
              'E-posta değiştirildi ve kullanıcı bilgileri taşındı.');
        } else {
          _showMessageDialog(
              'Hata', 'E-posta değişimi sırasında bir hata oluştu.');
        }
      } else {
        // If email hasn't changed, update user details
        final success = await UserProvider().updateUserDetails(updatedUser);
        if (success) {
          _showMessageDialog('Başarılı', 'Kullanıcı bilgileri güncellendi.');
        } else {
          _showMessageDialog('Hata', 'Bilgiler güncellenirken hata oluştu.');
        }
      }
    } catch (e) {
      _showMessageDialog('Hata', 'Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    }
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value.isNotEmpty ? value : 'Yok'),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Kullanıcı detayları alınırken hata oluştu: ${snapshot.error}'));
        } else if (snapshot.data == null) {
          return const Center(child: Text('Kullanıcı bilgisi bulunamadı.'));
        } else {
          final user = snapshot.data!;
          // Populate fields once the data is loaded
          if (!_isEditing) {
            _populateFields(user);
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing) ...[
                    _buildReadOnlyField('Ad', user.name),
                    _buildReadOnlyField('E-posta', user.email),
                    _buildReadOnlyField('Soyisim', user.surname ?? ''),
                    _buildReadOnlyField('Yaş', user.age?.toString() ?? ''),
                    _buildReadOnlyField('Referans', user.reference ?? ''),
                    _buildReadOnlyField('Notlar', user.notes ?? ''),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: const Text('Düzenle'),
                    ),
                  ] else ...[
                    _buildEditableField('Ad', _nameController),
                    _buildEditableField('E-posta', _emailController,
                        keyboardType: TextInputType.emailAddress),
                    _buildEditableField('Soyisim', _surnameController),
                    _buildEditableField('Yaş', _ageController,
                        keyboardType: TextInputType.number),
                    _buildEditableField('Referans', _referenceController),
                    _buildEditableField('Notlar', _notesController),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _saveChanges(user),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Kaydet'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                          },
                          child: const Text('İptal'),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
