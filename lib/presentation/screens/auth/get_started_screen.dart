import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/auth/auth_header.dart';
import '../../providers/auth_provider.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        if (context.mounted) {
          context.go('/home');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Sign in failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              AuthHeader(
                title: AppStrings.getStarted,
                subtitle: AppStrings.signInToContinue,
                illustration: _buildIllustration(),
              ),
              // Form Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Email Field
                      CustomTextField(
                        hintText: AppStrings.email,
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      CustomTextField(
                        hintText: AppStrings.password,
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        validator: Validators.validatePassword,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push('/forgot-password');
                          },
                          child: const Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign In Button
                      CustomButton(
                        text: AppStrings.signIn,
                        onPressed: _handleSignIn,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Create Account Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            AppStrings.dontHaveAccount,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/create-account');
                            },
                            child: const Text(
                              AppStrings.createAccount,
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.person,
        size: 100,
        color: AppColors.textWhite,
      ),
    );
  }
}
