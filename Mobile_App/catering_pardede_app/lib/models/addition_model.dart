import 'menu_model.dart';

class OrderAdditionRequest {
  final int id;
  final int orderId;
  final int statusId;
  final String statusName;
  final String? notes;
  final List<OrderAdditionItem> items;
  final DateTime createdAt;

  OrderAdditionRequest({
    required this.id,
    required this.orderId,
    required this.statusId,
    required this.statusName,
    this.notes,
    required this.items,
    required this.createdAt,
  });

  factory OrderAdditionRequest.fromJson(Map<String, dynamic> json) {
    return OrderAdditionRequest(
      id: json['id'],
      orderId: json['order_id'],
      statusId: json['status_id'],
      statusName: json['status']['status_name'],
      notes: json['notes'],
      items: (json['items'] as List)
          .map((i) => OrderAdditionItem.fromJson(i))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class OrderAdditionItem {
  final int id;
  final int menuId;
  final String menuName;
  final double? finalPrice;

  OrderAdditionItem({
    required this.id,
    required this.menuId,
    required this.menuName,
    this.finalPrice,
  });

  factory OrderAdditionItem.fromJson(Map<String, dynamic> json) {
    return OrderAdditionItem(
      id: json['id'],
      menuId: json['menu_id'],
      menuName: json['menu']['name'],
      finalPrice: json['final_price'] != null 
          ? double.parse(json['final_price'].toString()) 
          : null,
    );
  }
}
