class Estate {
  final String id;
  final String name;
  final String code;
  final String? address;
  final String? securityPhone;

  Estate({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.securityPhone,
  });

  factory Estate.fromJson(Map<String, dynamic> json) {
    return Estate(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String?,
      securityPhone: json['securityPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'securityPhone': securityPhone,
    };
  }
}
