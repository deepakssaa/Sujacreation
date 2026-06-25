class Customer {
  final int? id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String? password;
  final CustomerBilling billing;
  final CustomerShipping shipping;
  final List<dynamic>? metaData;

  Customer({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.password,
    required this.billing,
    required this.shipping,
    this.metaData,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'] ?? '',
      billing: CustomerBilling.fromJson(json['billing'] ?? {}),
      shipping: CustomerShipping.fromJson(json['shipping'] ?? {}),
      metaData: json['meta_data'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
    };
    if (password != null) {
      data['password'] = password;
    }
    if (metaData != null) {
      data['meta_data'] = metaData;
    }
    return data;
  }
}

class CustomerBilling {
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

  CustomerBilling({
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
  });

  factory CustomerBilling.fromJson(Map<String, dynamic> json) {
    return CustomerBilling(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? 'IN',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}

class CustomerShipping {
  final String firstName;
  final String lastName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;

  CustomerShipping({
    required this.firstName,
    required this.lastName,
    required this.address1,
    this.address2 = '',
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'IN',
  });

  factory CustomerShipping.fromJson(Map<String, dynamic> json) {
    return CustomerShipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? 'IN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
    };
  }
}
