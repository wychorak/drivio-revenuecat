import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/theme/app_theme.dart';

/// Picture (tap to zoom) and text of a theory question.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question});

  final TheoryQuestion question;

  void _zoom(BuildContext context, String image) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: PhotoView(imageProvider: AssetImage(image)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = question.image;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (image != null) ...[
          GestureDetector(
            onTap: () => _zoom(context, image),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppTheme.bgElevated,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          question.text,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
