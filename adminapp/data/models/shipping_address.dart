class ShippingAddress {
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String? landmark;

  ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.city,
    this.landmark,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'landmark': landmark,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: map['fullName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      landmark: map['landmark']?.toString(),
    );
  }

  String get formattedAddress {
    return '$address, $city${landmark != null ? ', Near $landmark' : ''}';
  }
}