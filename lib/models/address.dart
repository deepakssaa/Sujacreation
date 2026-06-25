import 'customer.dart';

class Address {
  final String id;
  final String name; // e.g., "Home", "Office"
  final String firstName;
  final String lastName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.address1,
    this.address2 = '',
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'IN',
    required this.email,
    required this.phone,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      address1: json['address_1'],
      address2: json['address_2'] ?? '',
      city: json['city'],
      state: json['state'],
      postcode: json['postcode'],
      country: json['country'] ?? 'IN',
      email: json['email'],
      phone: json['phone'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'email': email,
      'phone': phone,
      'is_default': isDefault,
    };
  }

  factory Address.fromCustomerBilling(CustomerBilling billing, {String name = 'Default', String? id}) {
    return Address(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      firstName: billing.firstName,
      lastName: billing.lastName,
      address1: billing.address1,
      address2: billing.address2,
      city: billing.city,
      state: billing.state,
      postcode: billing.postcode,
      country: billing.country,
      email: billing.email,
      phone: billing.phone,
      isDefault: true,
    );
  }

  CustomerBilling toCustomerBilling() {
    return CustomerBilling(
      firstName: firstName,
      lastName: lastName,
      address1: address1,
      address2: address2,
      city: city,
      state: state,
      postcode: postcode,
      country: country,
      email: email,
      phone: phone,
    );
  }
}
