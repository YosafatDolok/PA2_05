import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/order_service.dart';
import '../../../models/review_model.dart';
import '../../core/utils/helpers.dart';
import 'star_rating.dart';
import 'tap_scale.dart';

class ReviewSheet extends StatefulWidget {
  final int orderId;
  final ReviewModel? existingReview;
  const ReviewSheet({super.key, required this.orderId, this.existingReview});

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment ?? '';
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      Helpers.showSnackBar(context, 'Pilih bintang terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isEditing = widget.existingReview != null;
      final result = isEditing
          ? await OrderService.editReview(
              widget.orderId,
              _rating,
              _commentController.text,
            )
          : await OrderService.submitReview(
              widget.orderId,
              _rating,
              _commentController.text,
            );

      if (mounted) {
        if (result['success']) {
          Navigator.pop(context, true); // Return true to refresh UI
          Helpers.showSnackBar(context, result['message'] ?? (isEditing ? 'Ulasan diperbarui' : 'Ulasan dikirim'));
        } else {
          Helpers.showSnackBar(context, result['message'] ?? 'Gagal memproses ulasan');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bagaimana pengalaman Anda?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ulasan Anda sangat berarti bagi kami.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Text(
            'KETUK UNTUK MEMBERI RATING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          StarRating(
            rating: _rating,
            size: 48,
            onRatingChanged: (val) => setState(() => _rating = val),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _commentController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalaman rasa Anda...',
              hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
              fillColor: Colors.white,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 32),
          TapScale(
            onTap: _isLoading ? null : _submitReview,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Text(
                      widget.existingReview != null ? 'SIMPAN PERUBAHAN' : 'KIRIM ULASAN',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
