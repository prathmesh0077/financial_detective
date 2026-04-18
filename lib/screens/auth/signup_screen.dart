import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _signup() {
    ref.read(authProvider.notifier).login(
      _emailController.text.isEmpty ? 'agent@detective.io' : _emailController.text,
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.person_add_outlined, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 28),
              const Text(
                'Join Financial Detective',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'CREATE SECURE ACCESS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 3),
              ),
              const SizedBox(height: 44),
              _buildLabel('AGENT NAME'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textSecondary),
                decoration: const InputDecoration(hintText: 'Enter your name'),
              ),
              const SizedBox(height: 24),
              _buildLabel('IDENTIFICATION (EMAIL)'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textSecondary),
                decoration: const InputDecoration(hintText: 'agent@detective.io'),
              ),
              const SizedBox(height: 24),
              _buildLabel('CREDENTIAL (PASSWORD)'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textSecondary),
                decoration: const InputDecoration(hintText: '••••••••••'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _signup,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CREATE ACCOUNT'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5),
      ),
    );
  }
}
