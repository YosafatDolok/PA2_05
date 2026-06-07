import 'package:flutter/material.dart';
import '/core/services/delivery_chat_service.dart';
import '/models/delivery_message_model.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '/core/storage/local_storage.dart';
import '/core/constants/api_endpoints.dart';
import 'dart:convert';
import '../core/utils/helpers.dart';
import '/core/services/push_notification_service.dart';

class DeliveryChatController extends ChangeNotifier {
  List<DeliveryMessageModel> messages = [];
  bool isLoading = false;
  PusherChannelsClient? pusherClient;
  PrivateChannel? _currentChannel;

  Future<void> initPusher(int orderId) async {
    debugPrint("Initializing Delivery Pusher for order $orderId...");
    final token = await LocalStorage.getToken();
    if (token == null) return;

    try {
      final options = PusherChannelsOptions.fromHost(
        scheme: ApiEndpoints.pusherScheme,
        host: ApiEndpoints.pusherHost,
        key: "catering_pardede_key",
        port: ApiEndpoints.pusherPort,
        shouldSupplyMetadataQueries: true,
        metadata: PusherChannelsOptionsMetadata.byDefault(),
      );

      pusherClient = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (exception, trace, client) {
          debugPrint("Pusher Connection Error: $exception");
        },
      );

      final authUrl = "${ApiEndpoints.baseUrl}/broadcasting/auth";
      
      _currentChannel = pusherClient!.privateChannel(
        'private-delivery.order.$orderId',
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      _currentChannel!.bind('delivery.message.sent').listen((event) {
        final data = event.data;
        if (data != null) {
          final Map<String, dynamic> jsonData = (data is String) ? jsonDecode(data) : data;
          final newMessage = DeliveryMessageModel.fromJson(jsonData);
          
          final index = messages.indexWhere((m) => m.messageId == newMessage.messageId);
          if (index != -1) {
            messages[index] = newMessage;
            notifyListeners();
          } else {
            messages.add(newMessage);
            notifyListeners();
          }
        }
      });

      _currentChannel!.bind('pusher_internal:subscription_succeeded').listen((event) {
        debugPrint("Mobile Delivery Pusher Subscription Succeeded!");
      });

      _currentChannel!.bind('pusher_internal:subscription_error').listen((event) {
        debugPrint("Mobile Delivery Pusher Subscription Error: ${event.data}");
      });

      _currentChannel!.subscribe();
      pusherClient!.connect();
      
    } catch (e) {
      debugPrint("Pusher Init Error: $e");
    }
  }

  void disconnectPusher(int orderId) {
    _currentChannel?.unsubscribe();
    pusherClient?.disconnect();
  }

  Future<void> fetchMessages(int orderId) async {
    isLoading = true;
    notifyListeners();
    try {
      messages = await DeliveryChatService.getMessages(orderId);
    } catch (e) {
      debugPrint("Fetch Messages Error: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(BuildContext context, int orderId, String message) async {
    if (message.trim().isEmpty) return;
    
    try {
      final newMessage = await DeliveryChatService.sendMessage(orderId, message);
      if (newMessage != null && !messages.any((m) => m.messageId == newMessage.messageId)) {
        messages.add(newMessage);
        notifyListeners();
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Gagal mengirim pesan');
    }
  }

  Future<void> markAsRead(int orderId) async {
    try {
      await DeliveryChatService.markMessagesAsRead(orderId);
      // Sync global chat notification count if applicable
      PushNotificationService.updateUnreadChatCount();
      
      for (var i = 0; i < messages.length; i++) {
        if (!messages[i].isRead) {
          messages[i] = DeliveryMessageModel(
            messageId: messages[i].messageId,
            orderId: messages[i].orderId,
            senderId: messages[i].senderId,
            message: messages[i].message,
            isRead: true,
            createdAt: messages[i].createdAt,
            sender: messages[i].sender,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Mark as read error: $e");
    }
  }
}
