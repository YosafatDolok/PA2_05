import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'app_alerts.dart';

class Helpers {
  /// Memformat angka dengan pemisah ribuan (contoh: 1000 -> 1.000).
  static String formatNumber(num number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number).replaceAll(',', '.');
  }
  /// Membuka aplikasi peta eksternal dengan koordinat yang ditentukan.
  static Future<void> launchMap(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch map application';
    }
  }

  /// Memeriksa apakah error merupakan masalah koneksi atau jaringan.
  static bool isConnectionError(dynamic error) {
    if (error == null) return false;
    final lowercaseError = error.toString().toLowerCase();
    return lowercaseError.contains('socketexception') ||
        lowercaseError.contains('clientexception') ||
        lowercaseError.contains('networkisunreachable') ||
        lowercaseError.contains('connection failed') ||
        lowercaseError.contains('connection timed out') ||
        lowercaseError.contains('socketfailed') ||
        lowercaseError.contains('host lookup') ||
        lowercaseError.contains('no address associated with hostname') ||
        lowercaseError.contains('failed host lookup') ||
        lowercaseError.contains('connection reset') ||
        lowercaseError.contains('connection closed') ||
        lowercaseError.contains('software caused connection abort') ||
        lowercaseError.contains('koneksi internet terputus');
  }

  /// Mengubah exception/error menjadi pesan error bahasa Indonesia yang mudah dipahami.
  static String toFriendlyError(dynamic error) {
    if (error == null) return '';
    if (isConnectionError(error)) {
      return 'Koneksi internet terputus. Silakan periksa jaringan Anda.';
    }
    final errorStr = error.toString();
    return errorStr
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^Exception\s*', caseSensitive: false), '');
  }

  /// SnackBar yang ditingkatkan untuk menggunakan sistem AppAlerts Premium.
  /// Otomatis mendeteksi apakah pesan berupa Sukses atau Error.
  static void showSnackBar(
    BuildContext context, 
    String message, {
    bool? isError,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Membersihkan pesan exception teknis dan menangani status offline jaringan
    String cleanMessage;
    if (isConnectionError(message)) {
      cleanMessage = 'Koneksi internet terputus. Silakan periksa jaringan Anda.';
    } else {
      cleanMessage = message
          .replaceAll('Exception: ', '')
          .replaceAll('exception: ', '')
          .replaceAll('Exception', '')
          .replaceAll('exception', '');
    }

    // Deteksi pintar untuk warna
    final lowercaseMessage = cleanMessage.toLowerCase();
    final errorState = isError ?? !(
      lowercaseMessage.contains('berhasil') || 
      lowercaseMessage.contains('sukses') ||
      lowercaseMessage.contains('ditambahkan') ||
      lowercaseMessage.contains('dikirim') ||
      lowercaseMessage.contains('diperbarui') ||
      lowercaseMessage.contains('diterima') ||
      lowercaseMessage.contains('dihapus') ||
      lowercaseMessage.contains('dibatalkan') ||
      lowercaseMessage.contains('ditunjuk') ||
      lowercaseMessage.contains('aktif') ||
      lowercaseMessage.contains('dibuat')
    );
    
    if (!errorState) {
      AppAlerts.showSuccess(context, cleanMessage, actionLabel: actionLabel, onAction: onAction);
    } else {
      AppAlerts.showToast(context, cleanMessage, isError: true, actionLabel: actionLabel, onAction: onAction);
    }
  }

  /// Gunakan ini untuk error kritis yang membutuhkan perhatian pengguna
  static void showErrorDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    String cleanMessage;
    if (isConnectionError(message)) {
      cleanMessage = 'Koneksi internet terputus. Silakan periksa jaringan Anda.';
    } else {
      cleanMessage = message
          .replaceAll('Exception: ', '')
          .replaceAll('exception: ', '')
          .replaceAll('Exception', '')
          .replaceAll('exception', '');
    }

    AppAlerts.showDialogError(
      context: context,
      title: title,
      message: cleanMessage,
      onConfirm: onConfirm,
    );
  }

  /// Gunakan ini untuk konfirmasi akhir (contoh: Pendaftaran sukses, Pembayaran sukses)
  static void showSuccessDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    AppAlerts.showDialogSuccess(
      context: context,
      title: title,
      message: message,
      onConfirm: onConfirm,
    );
  }

  /// Gunakan ini untuk pilihan pengguna (contoh: "Batalkan Pesanan?", "Hapus Item?")
  static void showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya, Lanjutkan',
    required VoidCallback onConfirm,
  }) {
    AppAlerts.showDialogConfirm(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  static DateTime? _lastNavigatedTime;

  /// Berpindah ke route bernama secara aman, menghindari ketukan ganda dalam waktu 500ms.
  static Future<T?> pushNamedSafe<T>(
    BuildContext context, 
    String routeName, {
    Object? arguments,
  }) async {
    final now = DateTime.now();
    if (_lastNavigatedTime != null && 
        now.difference(_lastNavigatedTime!).inMilliseconds < 500) {
      return null;
    }
    _lastNavigatedTime = now;
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Berpindah ke Route langsung secara aman, menghindari ketukan ganda dalam waktu 500ms.
  static Future<T?> pushSafe<T>(BuildContext context, Route<T> route) async {
    final now = DateTime.now();
    if (_lastNavigatedTime != null && 
        now.difference(_lastNavigatedTime!).inMilliseconds < 500) {
      return null;
    }
    _lastNavigatedTime = now;
    return Navigator.push<T>(context, route);
  }

  /// Membuka URL eksternal secara aman.
  static Future<void> launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $urlString';
    }
  }
}
