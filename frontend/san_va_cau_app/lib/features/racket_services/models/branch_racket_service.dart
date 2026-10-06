class RacketServiceInfo {
  const RacketServiceInfo({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;

  factory RacketServiceInfo.fromJson(Map<String, dynamic> json) {
    return RacketServiceInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class BranchRacketService {
  const BranchRacketService({
    required this.id,
    required this.branchId,
    required this.serviceId,
    required this.service,
    this.referencePrice,
    this.description,
    this.estimatedDuration,
  });

  final String id;
  final String branchId;
  final String serviceId;
  final double? referencePrice;
  final String? description;
  final String? estimatedDuration;
  final RacketServiceInfo service;

  factory BranchRacketService.fromJson(Map<String, dynamic> json) {
    final price = json['referencePrice']?.toString();
    return BranchRacketService(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      referencePrice: price == null ? null : double.tryParse(price),
      description: json['description']?.toString(),
      estimatedDuration: json['estimatedDuration']?.toString(),
      service: RacketServiceInfo.fromJson(
        json['service'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
