class SuppliersResponse {
  final SuppliersMessage message;

  SuppliersResponse({required this.message});

  factory SuppliersResponse.fromJson(Map<String, dynamic> json) {
    return SuppliersResponse(
      message: SuppliersMessage.fromJson(json['message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
    };
  }
}

class SuppliersMessage {
  final List<Supplier> suppliers;
  final int page;
  final int pageSize;
  final int totalSuppliers;
  final int totalPages;

  SuppliersMessage({
    required this.suppliers,
    required this.page,
    required this.pageSize,
    required this.totalSuppliers,
    required this.totalPages,
  });

  factory SuppliersMessage.fromJson(Map<String, dynamic> json) {
    return SuppliersMessage(
      suppliers: (json['suppliers'] as List<dynamic>)
          .map((supplier) => Supplier.fromJson(supplier))
          .toList(),
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 50,
      totalSuppliers: json['total_suppliers'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suppliers': suppliers.map((supplier) => supplier.toJson()).toList(),
      'page': page,
      'page_size': pageSize,
      'total_suppliers': totalSuppliers,
      'total_pages': totalPages,
    };
  }
}

// Update your existing Supplier model to match the API response
class Supplier {
  final String supplierId;
  final String supplierName;
  final String supplierGroup;
  final String? address;

  Supplier({
    required this.supplierId,
    required this.supplierName,
    required this.supplierGroup,
    this.address,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierId: json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? '',
      supplierGroup: json['supplier_group']?.toString() ?? '',
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_group': supplierGroup,
      'address': address,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && other.supplierId == supplierId;
  }

  @override
  int get hashCode => supplierId.hashCode;
}
