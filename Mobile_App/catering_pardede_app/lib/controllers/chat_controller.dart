import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/core/services/chat_service.dart';
import '/models/order_message_model.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '/core/storage/local_storage.dart';
import '/core/constants/api_endpoints.dart';
import 'dart:convert';
import '../core/utils/helpers.dart';
import '/core/services/push_notification_service.dart';

class ChatController extends ChangeNotifier {
  List<OrderMessageModel> messages = [];
  bool isLoading = false;
  PusherChannelsClient? pusherClient;
  PrivateChannel? _currentChannel;
  VoidCallback? onNewMessage;

  Future<void> initPusher(int orderId) async {
    debugPrint("Initializing Pusher for order $orderId...");
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
          debugPrint("Pusher Connection Error Handler: $exception");
        },
      );

      pusherClient!.onConnectionEstablished.listen((_) {
        debugPrint("Pusher WebSocket Connected Successfully! Subscribing now...");
        _currentChannel?.subscribe();
      });

      final authUrl = "${ApiEndpoints.baseUrl}/broadcasting/auth";
      
      // DEBUG: Explicitly test the auth endpoint first to catch hidden Laravel errors!
      try {
        debugPrint("Testing Auth Endpoint explicitly...");
        final testResponse = await http.post(
          Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: {
            'socket_id': '12345.67890', // Fake socket ID for test
            'channel_name': 'private-order.$orderId',
          }
        );
        debugPrint("Auth Endpoint HTTP Status: ${testResponse.statusCode}");
        debugPrint("Auth Endpoint Response: ${testResponse.body}");
      } catch(e) {
        debugPrint("Auth Endpoint Test Failed: $e");
      }

      _currentChannel = pusherClient!.privateChannel(
        'private-order.$orderId',
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          onAuthFailed: (exception, trace) {
            debugPrint("INTERNAL AUTH DELEGATE CRASHED: $exception");
          },
        ),
      );

      _currentChannel!.bind('message.sent').listen((event) {
        final data = event.data;
        debugPrint("Message Received on Mobile: $data");
        if (data != null) {
          try {
            // data might be a JSON string or a Map depending on the platform/event
            final Map<String, dynamic> jsonData = (data is String) ? jsonDecode(data) : Map<String, dynamic>.from(data);
            final newMessage = OrderMessageModel.fromJson(jsonData);
            
            final index = messages.indexWhere((m) => m.messageId == newMessage.messageId);
            if (index != -1) {
              messages[index] = newMessage;
              notifyListeners();
            } else {
              messages.add(newMessage);
              notifyListeners();
              onNewMessage?.call(); // Trigger scroll
              markAsRead(orderId); // Safely mark as read EXACTLY once
            }
          } catch (e, stacktrace) {
            debugPrint("CRITICAL PARSING ERROR: $e");
            debugPrint("Stacktrace: $stacktrace");
          }
        }
      });

      _currentChannel!.bind('pusher_internal:subscription_succeeded').listen((event) {
        debugPrint("Mobile Pusher Subscription Succeeded!");
      });

      _currentChannel!.bind('pusher_internal:subscription_error').listen((event) {
        debugPrint("Mobile Pusher Subscription Error: ${event.data}");
      });

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
      messages = await ChatService.getOrderMessages(orderId);
    } catch (e) {
      debugPrint("Fetch Messages Error: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(BuildContext context, int orderId, String message) async {
    if (message.trim().isEmpty) return;
    
    try {
      final newMessage = await ChatService.sendMessage(orderId, message);
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
      await ChatService.markMessagesAsRead(orderId);
      // Sync global chat notification count
      PushNotificationService.updateUnreadChatCount();
      // Update local messages to avoid stale unread status
      for (var i = 0; i < messages.length; i++) {
        if (!messages[i].isRead) {
          messages[i] = OrderMessageModel(
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
