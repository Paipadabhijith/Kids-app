class SubscriptionModel {
  final SubscriptionTier tier;
  final DateTime? expiryDate;
  final bool isActive;
  /// Indicates that the user has requested to move to the basic tier
  /// at the end of the current billing cycle. They keep premium
  /// benefits until [expiryDate].
  final bool cancelAtPeriodEnd;

  SubscriptionModel({
    this.tier = SubscriptionTier.brightKids,
    this.expiryDate,
    this.isActive = true,
    this.cancelAtPeriodEnd = false,
  });

  /// User has premium access right now.
  /// - Must be on Zen Kids tier
  /// - Subscription must be active
  /// - And not past the expiry date (if any)
  bool get isPremium {
    final now = DateTime.now();
    final notExpired = expiryDate == null || expiryDate!.isAfter(now);
    return tier == SubscriptionTier.zenKids && isActive && notExpired;
  }

  bool get isFree => !isPremium;

  String get tierName => tier == SubscriptionTier.zenKids ? 'Zen Kids' : 'Bright Kids';
  String get tierBadge => tier == SubscriptionTier.zenKids ? 'ZK' : 'BK';

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.toString() == json['tier'],
        orElse: () => SubscriptionTier.brightKids,
      ),
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      isActive: json['isActive'] ?? true,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.toString(),
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
    };
  }

  SubscriptionModel copyWith({
    SubscriptionTier? tier,
    DateTime? expiryDate,
    bool? isActive,
    bool? cancelAtPeriodEnd,
  }) {
    return SubscriptionModel(
      tier: tier ?? this.tier,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
    );
  }
}

enum SubscriptionTier {
  brightKids, // Free tier
  zenKids,    // Premium tier
}

