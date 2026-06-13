import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'app_alerts.dart';

class Helpers {
  /// Formats a number with thousands separator (e.g., 1000 -> 1.000).
  static String formatNumber(num number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number).replaceAll(',', '.');
  }
  /// Launches an external map application with the specified coordinates.
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

  /// Upgraded SnackBar that now uses our Premium AppAlerts system.
  /// It automatically detects if the message is a Success or an Error.
  static void showSnackBar(
    BuildContext context, 
    String message, {
    bool? isError,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Clean up technical exception messages
    final cleanMessage = message
        .replaceAll('Exception: ', '')
        .replaceAll('exception: ', '')
        .replaceAll('Exception', '')
        .replaceAll('exception', '');

    // Smart detection for colors
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

  /// Use this for critical errors that need user attention
  static void showErrorDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    final cleanMessage = message
        .replaceAll('Exception: ', '')
        .replaceAll('exception: ', '')
        .replaceAll('Exception', '')
        .replaceAll('exception', '');

    AppAlerts.showDialogError(
      context: context,
      title: title,
      message: cleanMessage,
      onConfirm: onConfirm,
    );
  }

  /// Use this for final confirmations (e.g. Success registration, Success payment)
  static void showSuccessDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    AppAlerts.showDialogSuccess(
      context: context,
      title: title,
      message: message,
      onConfirm: onConfirm,
    );
  }

  /// Use this for user choices (e.g. "Batalkan Pesanan?", "Hapus Item?")
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

  /// Safely pushes a named route, debouncing rapid taps within 500ms.
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

  /// Safely pushes a direct Route route, debouncing rapid taps within 500ms.
  static Future<T?> pushSafe<T>(BuildContext context, Route<T> route) async {
    final now = DateTime.now();
    if (_lastNavigatedTime != null && 
        now.difference(_lastNavigatedTime!).inMilliseconds < 500) {
      return null;
    }
    _lastNavigatedTime = now;
    return Navigator.push<T>(context, route);
  }

  /// Launches any external URL safely.
  static Future<void> launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $urlString';
    }
  }
}
