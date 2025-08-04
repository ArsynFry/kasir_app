// Halaman login/sign in aplikasi.
// Mendukung login email/password dan bisa dikembangkan untuk Google Sign-In.

import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/assets/app_assets.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/themes/app_sizes.dart';
import '../../../../service_locator.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _authProvider = sl<AuthProvider>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSizes.padding,
            right: AppSizes.padding,
            top: AppSizes.padding,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.padding,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                welcomeMessage(),
                emailPasswordFields(),
                signInButton(),
                signUpButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget welcomeMessage() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppImage(
            image: AppAssets.welcome,
            imgProvider: ImgProvider.assetImage,
          ),
          const SizedBox(height: AppSizes.padding),
          Text(
            'Welcome!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Welcome to Flutter POS app',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget signInButton() {
    return AppButton(
      text: 'Sign In',
      onTap: () async {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        if (email.isEmpty || password.isEmpty) {
          AppDialog.showErrorDialog(error: 'Email dan password wajib diisi');
          return;
        }
        AppDialog.showDialogProgress();
        var res = await _authProvider.signIn(email: email, password: password);
        AppDialog.closeDialog();
        if (res.isSuccess) {
          AppRoutes.router.refresh();
        } else {
          final errorMsg = res.error?.message ?? '';
          if (!errorMsg.toLowerCase().contains('duplicate key')) {
            AppDialog.showErrorDialog(error: errorMsg);
          }
        }
      },
    );
  }

  Widget signUpButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextButton(
        onPressed: () {
          // Gunakan GoRouter untuk navigasi
          AppRoutes.router.go('/auth/sign_up');
        },
        child: const Text('Belum punya akun? Daftar'),
      ),
    );
  }

  Widget emailPasswordFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
    );
  }
}
