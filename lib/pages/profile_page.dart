import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/pages/reset_password_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('Loading data for userId: ${widget.userId}');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final data = userDoc.data();
      print('User data: $data');
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _surnameController.text = data['surname'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
      } else {
        print('No data found for userId: ${widget.userId}');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserData() async {
    if (_nameController.text.isEmpty || _surnameController.text.isEmpty || _ageController.text.isEmpty) {
      _showInfoDialog('Lütfen tüm alanları doldurun.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      int? age = int.tryParse(_ageController.text);
      if (age == null) {
        _showInfoDialog('Lütfen Yaş alanına geçerli bir sayı giriniz.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'name': _nameController.text,
        'surname': _surnameController.text,
        'age': age,
      }, SetOptions(merge: true));
      print('User data saved for userId: ${widget.userId}');
    } catch (e) {
      print('Error saving user data: $e');
    }
    setState(() {
      _isLoading = false;
    });
    _showInfoDialog('Bilgiler güncellendi!');
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if(!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width * 0.33;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveUserData,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Soyad'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Yaş'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
           // const Spacer(),
            Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton.icon(
                      onPressed: _saveUserData,
                      icon: const Icon(Icons.save),
                      label: const Text('Kaydet'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResetPasswordPage(
                              email: FirebaseAuth.instance.currentUser?.email ?? '',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Şifre Sıfırla'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
