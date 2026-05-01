import 'package:flutter/material.dart';
import '/core/services/chat_service.dart';
import '/models/order_message_model.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '/core/storage/local_storage.dart';
import '/core/constants/api_endpoints.dart';
import 'dart:convert';

class ChatController extends ChangeNotifier {
  List<OrderMessageModel> messages = [];
  bool isLoading = false;
  PusherChannelsClient? pusherClient;
  PrivateChannel? _currentChannel;

  Future<void> initPusher(int orderId) async {
    final token = await LocalStorage.getToken();
    if (token == null) return;

    try {
      final options = PusherChannelsOptions.fromHost(
        scheme: 'ws',
        host: '10.0.2.2', // Localhost for Android Emulator
        key: "catering_pardede_key",
        port: 8080,
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
        'private-order.$orderId',
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      _currentChannel!.bind('App\\Events\\MessageSent').listen((event) {
        final data = event.data;
        if (data != null) {
          // data might be a JSON string or a Map depending on the platform/event
          final Map<String, dynamic> jsonData = (data is String) ? jsonDecode(data) : data;
          final newMessage = OrderMessageModel.fromJson(jsonData);
          
          if (!messages.any((m) => m.messageId == newMessage.messageId)) {
            messages.add(newMessage);
            notifyListeners();
          }
        }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengirim pesan")),
      );
    }
  }

  Future<void> sendProposal(int orderId, String note, double price) async {
    try {
      final newMessage = await ChatService.sendProposal(orderId, note, price);
      if (newMessage != null && !messages.any((m) => m.messageId == newMessage.messageId)) {
        messages.add(newMessage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Send Proposal Error: $e");
    }
  }

  Future<void> acceptProposal(BuildContext context, int orderId, int messageId) async {
    try {
      await ChatService.acceptProposal(orderId, messageId);
      final index = messages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        messages[index] = OrderMessageModel(
          messageId: messages[index].messageId,
          orderId: messages[index].orderId,
          senderId: messages[index].senderId,
          message: messages[index].message,
          isRead: messages[index].isRead,
          type: messages[index].type,
          proposedPrice: messages[index].proposedPrice,
          proposalStatus: 'accepted',
          createdAt: messages[index].createdAt,
          sender: messages[index].sender,
        );
        notifyListeners();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Penawaran diterima! Total harga diperbarui.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menerima penawaran")),
      );
    }
  }
  Future<void> markAsRead(int orderId) async {
    try {
      await ChatService.markMessagesAsRead(orderId);
      // Update local messages to avoid stale unread status
      for (var i = 0; i < messages.length; i++) {
        if (!messages[i].isRead) {
          messages[i] = OrderMessageModel(
            messageId: messages[i].messageId,
            orderId: messages[i].orderId,
            senderId: messages[i].senderId,
            message: messages[i].message,
            isRead: true,
            type: messages[i].type,
            proposedPrice: messages[i].proposedPrice,
            proposalStatus: messages[i].proposalStatus,
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
