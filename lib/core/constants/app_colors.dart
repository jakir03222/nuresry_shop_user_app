import 'package:flutter/material.dart';

class AppColors {
  // Smart Plant Theme - Primary Colors (Nursery Shop Theme)
  static const Color primary = Color(0xFF2E7D32); // plantMediumGreen - Main brand color
  static const Color primaryDark = Color(0xFF1B5E20); // plantDarkGreen - Darker shade
  static const Color primaryLight = Color(0xFF66BB6A); // Lighter green for accents
  static const Color primaryLighter = Color(0xFF81C784); // plantLightGreen
  static const Color primaryLightest = Color(0xFFC8E6C9); // plantMintGreen - Subtle backgrounds
  
  // Legacy Blue Colors (kept for backward compatibility)
  static const Color primaryBlue = Color(0xFF2E7D32); // Now uses plant green
  static const Color primaryBlueDark = Color(0xFF1B5E20);
  static const Color primaryBlueLight = Color(0xFF66BB6A);
  
  // Background Colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8F9FA); // Slightly warmer than F5F5F5
  static const Color backgroundGrey = Color(0xFFF0F4F3); // Slight green tint
  static const Color backgroundMint = Color(0xFFF1F8F4); // Very subtle mint background
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A); // Softer than pure black
  static const Color textSecondary = Color(0xFF6B7280); // Modern grey
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9CA3AF); // Softer grey
  static const Color textGreen = Color(0xFF2E7D32); // Green text for emphasis
  
  // Accent Colors
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFEF4444); // Modern red
  static const Color accentOrange = Color(0xFFF59E0B); // Modern orange
  static const Color accentYellow = Color(0xFFEAB308); // Modern yellow
  static const Color accentTeal = Color(0xFF14B8A6); // Complementary teal
  
  // Plant Theme Colors (Enhanced)
  static const Color plantDarkGreen = Color(0xFF1B5E20);
  static const Color plantMediumGreen = Color(0xFF2E7D32);
  static const Color plantLightGreen = Color(0xFF81C784);
  static const Color plantMintGreen = Color(0xFFC8E6C9);
  static const Color plantEmerald = Color(0xFF10B981); // Vibrant emerald
  
  // Border Colors
  static const Color borderGrey = Color(0xFFE5E7EB); // Softer border
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderGreen = Color(0xFFD1FAE5); // Subtle green border
  
  // Flash Sale
  static const Color flashSaleRed = Color(0xFFDC2626); // Modern red
  static const Color flashSaleOrange = Color(0xFFF97316); // Vibrant orange
  
  // Price Colors
  static const Color priceOriginal = Color(0xFF6B7280);
  static const Color priceDiscount = Color(0xFF10B981); // Modern green
  
  // Button Colors
  static const Color buttonPrimary = Color(0xFF2E7D32); // Plant green
  static const Color buttonPrimaryHover = Color(0xFF1B5E20); // Darker on hover
  static const Color buttonSecondary = Color(0xFF6B7280);
  static const Color buttonSuccess = Color(0xFF10B981);
  
  // Status Colors (Modern)
  static const Color success = Color(0xFF10B981); // Modern green
  static const Color error = Color(0xFFEF4444); // Modern red
  static const Color warning = Color(0xFFF59E0B); // Modern orange
  static const Color info = Color(0xFF3B82F6); // Modern blue
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
