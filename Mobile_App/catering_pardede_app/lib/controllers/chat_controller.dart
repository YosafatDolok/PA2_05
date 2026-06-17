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
import '/core/services/auth_service.dart';

class ChatController extends ChangeNotifier {
  List<OrderMessageModel> messages = [];
  bool isLoading = false;
  bool isOffline = false;
  PusherChannelsClient? pusherClient;
  PrivateChannel? _currentChannel;
  VoidCallback? onNewMessage;
  bool _isProcessingQueue = false;

  Future<void> _saveToCache(int orderId) async {
    try {
      final listJson = messages.map((m) => m.toJson()).toList();
      await LocalStorage.saveChatCache(orderId, listJson);
    } catch (e) {
      debugPrint("Failed to save chat cache: $e");
    }
  }

  Future<void> _processPendingQueue(int orderId) async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (true) {
        final pending = await LocalStorage.getPendingMessages(orderId);
        if (pending.isEmpty) break;

        final firstPending = pending.first;
        final tempId = firstPending['message_id'] as int;
        final text = firstPending['message'] as String;

        try {
          final sentMsg = await ChatService.sendMessage(orderId, text);
          if (sentMsg != null) {
            // Berhasil! Hapus dari antrean tertunda
            pending.removeAt(0);
            await LocalStorage.savePendingMessages(orderId, pending);

            // Perbarui daftar lokal
            final idx = messages.indexWhere((m) => m.messageId == tempId);
            if (idx != -1) {
              messages[idx] = sentMsg; // Ganti pesan sementara dengan pesan dari server
            } else {
              // Jika tempId sudah diganti oleh listener Pusher, periksa apakah pesan asli sudah ada di daftar
              final exists = messages.any((m) => m.messageId == sentMsg.messageId);
              if (!exists) {
                messages.add(sentMsg);
              }
            }
            isOffline = false;
            notifyListeners();
            onNewMessage?.call();
          } else {
            throw Exception("Server returned null message");
          }
        } catch (e) {
          debugPrint("Offline Chat Worker Error for msg $tempId: $e");
          final isConnectionError = Helpers.isConnectionError(e);

          if (isConnectionError) {
            isOffline = true;
            notifyListeners();
            break; // Hentikan sementara pekerja
          } else {
            // Error dari sisi server: hapus dari antrean dan atur status ke gagal
            pending.removeAt(0);
            await LocalStorage.savePendingMessages(orderId, pending);

            final idx = messages.indexWhere((m) => m.messageId == tempId);
            if (idx != -1) {
              messages[idx] = messages[idx].copyWith(sendStatus: 'failed');
              notifyListeners();
            }
          }
        }
      }
    } finally {
      _isProcessingQueue = false;
      await _saveToCache(orderId);
    }
  }

  Future<void> retrySendMessage(BuildContext context, int orderId, int tempId) async {
    final idx = messages.indexWhere((m) => m.messageId == tempId);
    if (idx == -1) return;

    messages[idx] = messages[idx].copyWith(sendStatus: 'sending');
    notifyListeners();

    final pending = await LocalStorage.getPendingMessages(orderId);
    if (!pending.any((item) => item['message_id'] == tempId)) {
      pending.add({
        'message_id': tempId,
        'order_id': orderId,
        'sender_id': messages[idx].senderId,
        'message': messages[idx].message,
        'send_status': 'sending',
      });
      await LocalStorage.savePendingMessages(orderId, pending);
    }

    _processPendingQueue(orderId);
  }

  Future<void> discardFailedMessage(int orderId, int tempId) async {
    messages.removeWhere((m) => m.messageId == tempId);
    notifyListeners();

    final pending = await LocalStorage.getPendingMessages(orderId);
    pending.removeWhere((item) => item['message_id'] == tempId);
    await LocalStorage.savePendingMessages(orderId, pending);
    await _saveToCache(orderId);
  }

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
        
        // Kirim semua pesan offline yang tertunda ketika koneksi terhubung kembali
        _processPendingQueue(orderId);
        // Sinkronisasi pesan untuk mendapatkan pesan siaran yang terlewat
        fetchMessages(orderId);
      });

      final authUrl = "${ApiEndpoints.baseUrl}/broadcasting/auth";
      
      // DEBUG: Uji endpoint otentikasi secara eksplisit terlebih dahulu untuk mendeteksi error Laravel
      try {
        debugPrint("Testing Auth Endpoint explicitly...");
        final testResponse = await http.post(
          Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: {
            'socket_id': '12345.67890', // ID socket tiruan untuk pengujian
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

      // Dengarkan pesan baru
      _currentChannel!.bind('message.sent').listen((event) {
        final data = event.data;
        debugPrint("Message Received on Mobile: $data");
        if (data != null) {
          try {
            final Map<String, dynamic> jsonData = (data is String) ? jsonDecode(data) : Map<String, dynamic>.from(data);
            final newMessage = OrderMessageModel.fromJson(jsonData);
            
            final index = messages.indexWhere((m) => m.messageId == newMessage.messageId);
            if (index != -1) {
              messages[index] = newMessage;
              notifyListeners();
            } else {
              // Check if it matches a pending optimistic message (same sender, same message text, negative temporary ID)
              final pendingIndex = messages.indexWhere((m) =>
                  m.messageId != null &&
                  m.messageId! < 0 &&
                  m.senderId == newMessage.senderId &&
                  m.message != null &&
                  newMessage.message != null &&
                  m.message!.trim() == newMessage.message!.trim());

              if (pendingIndex != -1) {
                messages[pendingIndex] = newMessage;
                notifyListeners();
              } else {
                messages.add(newMessage);
                notifyListeners();
                onNewMessage?.call(); // Memicu gulir layar
                markAsRead(orderId); // Tandai sebagai dibaca tepat satu kali secara aman
              }
            }
          } catch (e, stacktrace) {
            debugPrint("CRITICAL PARSING ERROR: $e");
            debugPrint("Stacktrace: $stacktrace");
          }
        }
      });

      // Dengarkan pesan yang dihapus — perbarui gelembung chat lokal ke placeholder
      _currentChannel!.bind('message.deleted').listen((event) {
        final data = event.data;
        if (data != null) {
          try {
            final Map<String, dynamic> jsonData = (data is String) ? jsonDecode(data) : Map<String, dynamic>.from(data);
            final deletedId = jsonData['message_id'] as int?;
            if (deletedId == null) return;

            final index = messages.indexWhere((m) => m.messageId == deletedId);
            if (index != -1) {
              messages[index] = messages[index].copyAsDeleted();
              notifyListeners();
            }
          } catch (e) {
            debugPrint("Delete event parse error: $e");
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

    // 1. Muat dari penyimpanan cache terlebih dahulu
    try {
      final cachedData = await LocalStorage.getChatCache(orderId);
      if (cachedData.isNotEmpty) {
        messages = cachedData.map((json) => OrderMessageModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading chat cache: $e");
    }

    // 2. Ambil pesan terbaru
    try {
      final freshMessages = await ChatService.getOrderMessages(orderId);
      messages = freshMessages;
      isOffline = false;
      await _saveToCache(orderId);
    } catch (e) {
      debugPrint("Fetch Messages Error: $e");
      final isConnectionError = Helpers.isConnectionError(e);
      if (isConnectionError) {
        isOffline = true;
      }
    }
    isLoading = false;
    notifyListeners();

    // 3. Proses antrean
    _processPendingQueue(orderId);
  }

  Future<void> sendMessage(BuildContext context, int orderId, String message) async {
    if (message.trim().isEmpty) return;
    
    // Dapatkan ID pengguna saat ini
    final userData = await AuthService.getUser();
    final currentUserId = userData != null ? (userData['user_id'] ?? userData['id']) as int : 0;
    
    // Buat pesan optimistik
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimisticMessage = OrderMessageModel(
      messageId: tempId,
      orderId: orderId,
      senderId: currentUserId,
      message: message,
      isRead: false,
      isDeleted: false,
      createdAt: DateTime.now().toIso8601String(),
      sendStatus: 'sending',
    );
    
    // Tambahkan ke daftar lokal dan beri tahu pendengar
    messages.add(optimisticMessage);
    notifyListeners();
    onNewMessage?.call();

    // Simpan ke antrean dan cache
    try {
      final pending = await LocalStorage.getPendingMessages(orderId);
      pending.add({
        'message_id': tempId,
        'order_id': orderId,
        'sender_id': currentUserId,
        'message': message,
        'send_status': 'sending',
      });
      await LocalStorage.savePendingMessages(orderId, pending);
      await _saveToCache(orderId);
    } catch (e) {
      debugPrint("Failed to queue pending message: $e");
    }

    // Proses antrean tertunda
    _processPendingQueue(orderId);
  }

  /// Menghapus pesan secara lunak (soft delete). Memperbarui daftar lokal secara optimistik,
  /// kemudian melakukan konfirmasi ke server. Jika gagal, memulihkan pesan asli.
  Future<void> deleteMessage(BuildContext context, int orderId, int messageId) async {
    final index = messages.indexWhere((m) => m.messageId == messageId);
    if (index == -1) return;

    final original = messages[index];

    // Pembaruan optimistik
    messages[index] = original.copyAsDeleted();
    notifyListeners();

    try {
      await ChatService.deleteMessage(orderId, messageId);
      // Konfirmasi server berhasil — event Pusher akan memperbarui layar pengguna lain.
      await _saveToCache(orderId);
    } catch (e) {
      // Batalkan pembaruan jika gagal
      messages[index] = original;
      notifyListeners();
      final msg = e.toString().replaceFirst('Exception: ', '');
      Helpers.showSnackBar(context, msg.isNotEmpty ? msg : 'Gagal menghapus pesan');
    }
  }

  Future<void> markAsRead(int orderId) async {
    try {
      await ChatService.markMessagesAsRead(orderId);
      // Sinkronisasi jumlah notifikasi chat global
      PushNotificationService.updateUnreadChatCount();
      // Perbarui pesan lokal untuk menghindari status belum dibaca yang usang
      for (var i = 0; i < messages.length; i++) {
        if (!messages[i].isRead) {
          messages[i] = messages[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
      await _saveToCache(orderId);
    } catch (e) {
      debugPrint("Mark as read error: $e");
    }
  }
}
