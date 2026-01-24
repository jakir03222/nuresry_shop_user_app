import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/auth/auth_header.dart';
import '../../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyEmail(
        otp: _otpController.text.trim(),
        email: widget.email,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.successMessage ?? 'Email verified successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          // Navigate to login screen after successful verification
          context.go('/get-started');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'OTP verification failed'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
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
                title: 'Verify Email',
                subtitle: 'Enter the OTP sent to ${widget.email}',
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
                      // OTP Field
                      CustomTextField(
                        hintText: 'Enter OTP',
                        prefixIcon: Icons.lock_outline,
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter OTP';
                          }
                          if (value.length < 4 || value.length > 6) {
                            return 'OTP must be 4-6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Verify Button
                      CustomButton(
                        text: 'Verify OTP',
                        onPressed: _handleVerifyOtp,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Resend OTP Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive OTP?",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement resend OTP
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Resend OTP functionality coming soon'),
                                  backgroundColor: AppColors.primaryBlue,
                                ),
                              );
                            },
                            child: const Text(
                              'Resend',
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
        Icons.email_outlined,
        size: 100,
        color: AppColors.textWhite,
      ),
    );
  }
}
