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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgotPassword(
        _emailController.text.trim(),
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to send reset link'),
            backgroundColor: AppColors.error,
          ),
        );
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
                title: AppStrings.forgotPassword,
                subtitle: AppStrings.enterEmailToReset,
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
                      const SizedBox(height: 40),
                      // Email Field
                      CustomTextField(
                        hintText: AppStrings.email,
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      // Continue Button
                      CustomButton(
                        text: AppStrings.continueText,
                        onPressed: _handleContinue,
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
        Icons.lock_reset,
        size: 100,
        color: AppColors.textWhite,
      ),
    );
  }
}
