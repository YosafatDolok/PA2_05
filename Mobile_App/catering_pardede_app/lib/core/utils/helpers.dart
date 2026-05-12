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
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Smart detection for colors
    final isSuccess = message.toLowerCase().contains('berhasil') || 
                      message.toLowerCase().contains('sukses') ||
                      message.toLowerCase().contains('ditambahkan');
    
    if (isSuccess) {
      AppAlerts.showSuccess(context, message, actionLabel: actionLabel, onAction: onAction);
    } else {
      AppAlerts.showToast(context, message, isError: true, actionLabel: actionLabel, onAction: onAction);
    }
  }

  /// Use this for critical errors that need user attention
  static void showErrorDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    AppAlerts.showDialogError(
      context: context,
      title: title,
      message: message,
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
}
