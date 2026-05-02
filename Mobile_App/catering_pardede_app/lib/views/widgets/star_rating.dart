import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final Function(int)? onRatingChanged;
  final bool isInteractive;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 30,
    this.onRatingChanged,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= rating;

        return GestureDetector(
          onTap: isInteractive ? () => onRatingChanged?.call(starIndex) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected ? Colors.amber : Colors.grey.withValues(alpha: 0.5),
              size: size,
              shadows: isSelected
                  ? [
                      Shadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
