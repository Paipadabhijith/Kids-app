class SubscriptionModel {
  final SubscriptionTier tier;
  final DateTime? expiryDate;
  final bool isActive;

  SubscriptionModel({
    this.tier = SubscriptionTier.brightKids,
    this.expiryDate,
    this.isActive = true,
  });

  bool get isPremium => tier == SubscriptionTier.zenKids && isActive;
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.toString(),
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  SubscriptionModel copyWith({
    SubscriptionTier? tier,
    DateTime? expiryDate,
    bool? isActive,
  }) {
    return SubscriptionModel(
      tier: tier ?? this.tier,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum SubscriptionTier {
  brightKids, // Free tier
  zenKids,    // Premium tier
}

