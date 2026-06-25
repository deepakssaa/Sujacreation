class OrderRequest {
  final String paymentMethod;
  final String paymentMethodTitle;
  final bool setPaid;
  final Billing billing;
  final Shipping shipping;
  final List<LineItem> lineItems;

  final List<ShippingLine>? shippingLines;
  final int? customerId;

  OrderRequest({
    required this.paymentMethod,
    required this.paymentMethodTitle,
    required this.setPaid,
    required this.billing,
    required this.shipping,
    required this.lineItems,
    this.shippingLines,
    this.customerId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': setPaid,
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
      'line_items': lineItems.map((item) => item.toJson()).toList(),
    };
    if (shippingLines != null) {
      data['shipping_lines'] = shippingLines!.map((s) => s.toJson()).toList();
    }
    if (customerId != null) {
      data['customer_id'] = customerId;
    }
    return data;
  }
}

class ShippingLine {
  final String methodId;
  final String methodTitle;
  final String total;

  ShippingLine({
    required this.methodId,
    required this.methodTitle,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'method_id': methodId,
      'method_title': methodTitle,
      'total': total,
    };
  }
}

class Billing {
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

  Billing({
    required this.firstName,
    required this.lastName,
    required this.address1,
    this.address2 = "",
    required this.city,
    required this.state,
    required this.postcode,
    this.country = "IN",
    required this.email,
    required this.phone,
  });

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

class Shipping {
  final String firstName;
  final String lastName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;

  Shipping({
    required this.firstName,
    required this.lastName,
    required this.address1,
    this.address2 = "",
    required this.city,
    required this.state,
    required this.postcode,
    this.country = "IN",
  });

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

class LineItem {
  final int productId;
  final int quantity;
  final int? variationId;

  LineItem({
    required this.productId,
    required this.quantity,
    this.variationId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'product_id': productId,
      'quantity': quantity,
    };
    if (variationId != null && variationId != 0) {
      data['variation_id'] = variationId;
    }
    return data;
  }
}
