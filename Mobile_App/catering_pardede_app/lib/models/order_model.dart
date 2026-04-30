import 'menu_model.dart';
import 'review_model.dart';

class OrderModel {
  final int id;
  final int userId;
  final int? driverId;
  final String eventAddress;
  final String? eventLatitude;
  final String? eventLongitude;
  final String? locationNotes;
  final DateTime eventDate;
  final int statusId;
  final double finalPrice;
  final DateTime orderDate;
  final int people;
  final String? notes;
  final DateTime? startedDeliveryAt;
  final DateTime? deliveredAt;
  final String? deliveryNotes;
  final String? deliveryProofImage;
  final OrderStatusModel? status;
  final List<OrderItemModel>? items;
  final ReviewModel? review;

  OrderModel({
    required this.id,
    required this.userId,
    this.driverId,
    required this.eventAddress,
    this.eventLatitude,
    this.eventLongitude,
    this.locationNotes,
    required this.eventDate,
    required this.statusId,
    required this.finalPrice,
    required this.orderDate,
    required this.people,
    this.notes,
    this.startedDeliveryAt,
    this.deliveredAt,
    this.deliveryNotes,
    this.deliveryProofImage,
    this.status,
    this.items,
    this.review,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['order_id'],
      userId: json['user_id'],
      driverId: json['driver_id'],
      eventAddress: json['event_address'],
      eventLatitude: json['event_latitude']?.toString(),
      eventLongitude: json['event_longitude']?.toString(),
      locationNotes: json['location_notes'],
      eventDate: DateTime.parse(json['event_date']),
      statusId: json['status_id'],
      finalPrice: double.tryParse(json['final_price']?.toString() ?? '0') ?? 0.0,
      orderDate: DateTime.parse(json['order_date']),
      people: json['people'],
      notes: json['notes'],
      startedDeliveryAt: json['started_delivery_at'] != null
          ? DateTime.parse(json['started_delivery_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      deliveryNotes: json['delivery_notes'],
      deliveryProofImage: json['delivery_proof_image'],
      status: json['status'] != null
          ? OrderStatusModel.fromJson(json['status'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => OrderItemModel.fromJson(i))
              .toList()
          : null,
      review: json['review'] != null
          ? ReviewModel.fromJson(json['review'])
          : null,
    );
  }
}

class OrderItemModel {
  final int id;
  final int orderId;
  final int menuId;
  final double? finalPrice;
  final MenuModel? menu;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuId,
    this.finalPrice,
    this.menu,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['order_item_id'],
      orderId: json['order_id'],
      menuId: json['menu_id'],
      finalPrice: double.tryParse(json['final_price']?.toString() ?? ''),
      menu: json['menu'] != null ? MenuModel.fromJson(json['menu']) : null,
    );
  }
}

class OrderStatusModel {
  final int id;
  final String name;

  OrderStatusModel({
    required this.id,
    required this.name,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      id: json['status_id'],
      name: json['status_name'],
    );
  }
}
