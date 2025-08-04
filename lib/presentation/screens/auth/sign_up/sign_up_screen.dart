import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (result.isHasError) {
      setState(() => _error = result.error?.message ?? 'Terjadi kesalahan');
    } else {
      Navigator.of(context).pop(); // Kembali ke login atau home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama'),
                      validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Daftar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
