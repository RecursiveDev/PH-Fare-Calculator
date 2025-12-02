/// Enum representing different discount types for transportation fares.
/// Based on Philippine law (RA 11314, RA 9994, RA 7277), eligible users
/// (Students, Senior Citizens, and PWD) receive a 20% discount on all public transportation fares.
enum DiscountType {
  /// Standard fare - no discount applied
  standard,
  
  /// Discounted fare - 20% off
  /// Applies to Students (RA 11314), Senior Citizens (RA 9994), and PWD (RA 7277)
  discounted,
}

/// Extension to provide display-friendly names for DiscountType
extension DiscountTypeExtension on DiscountType {
  /// Returns a user-friendly display name for the discount type
  String get displayName {
    switch (this) {
      case DiscountType.standard:
        return 'Regular';
      case DiscountType.discounted:
        return 'Discounted (Student/Senior/PWD)';
    }
  }
  
  /// Returns true if this discount type is eligible for the 20% fare discount
  bool get isEligibleForDiscount {
    return this == DiscountType.discounted;
  }
  
  /// Returns the discount multiplier (0.80 for 20% discount, 1.0 for no discount)
  double get fareMultiplier {
    return isEligibleForDiscount ? 0.80 : 1.0;
  }
}