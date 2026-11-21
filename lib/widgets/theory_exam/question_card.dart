import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/theme/app_theme.dart';

/// Picture (tap to zoom) or film, and the text of a theory question.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, this.media});

  final TheoryQuestion question;

  /// Shown instead of the picture, e.g. the question's film.
  final Widget? media;

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
        if (media != null) ...[
          media!,
          const SizedBox(height: 14),
        ] else if (image != null) ...[
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
