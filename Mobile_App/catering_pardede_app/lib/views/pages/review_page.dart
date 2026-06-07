import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/order_service.dart';
import '../../../models/review_model.dart';
import '../../core/utils/helpers.dart';
import '../widgets/custom_header.dart';
import '../widgets/star_rating.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reviewData = await OrderService.getLatestReviews();
      if (mounted) {
        setState(() {
          _reviews = (reviewData as List).map((json) => ReviewModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CustomHeader(
            title: "ULASAN PELANGGAN",
            showIcons: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchReviews,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      )
                    : _reviews.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada ulasan pelanggan.",
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchReviews,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: _reviews.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 20),
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                final hasBeenEdited = review.updatedAt != null &&
                                    review.createdAt != null &&
                                    review.updatedAt!.difference(review.createdAt!).inSeconds.abs() > 1;

                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF9F7F2),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(24),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.05),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 16),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    review.userName ?? 'Pelanggan',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF2D0A0A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const Text(
                                                    'Verified Buyer',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (review.createdAt != null)
                                              Text(
                                                "${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                StarRating(rating: review.rating, isInteractive: false, size: 20),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF9F9F9),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: const Color(0xFFF0F0F0)),
                                              ),
                                              child: Text(
                                                review.comment != null && review.comment!.isNotEmpty
                                                    ? "\"${review.comment}\""
                                                    : "\"Tidak ada komentar\"",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color(0xFF4A4A4A),
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                            if (hasBeenEdited) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  "edited: ${review.updatedAt!.day}/${review.updatedAt!.month}/${review.updatedAt!.year}",
                                                  style: const TextStyle(
                                                    color: AppColors.secondary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
