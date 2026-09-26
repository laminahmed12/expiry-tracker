class License {
  final String code;
  final String plan;
  final String deviceId;
  final DateTime? expiresAt;
  final bool permanent;
  const License({required this.code,required this.plan,required this.deviceId,required this.expiresAt,required this.permanent});
  bool get isExpired => !permanent && (expiresAt == null || DateTime.now().isAfter(expiresAt!));
}
