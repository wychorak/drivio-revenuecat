import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/theme/app_theme.dart';

class SchoolCard extends StatelessWidget {
  final SchoolModel school;

  const SchoolCard({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/school/${school.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.bgDark,
              backgroundImage: school.logoUrl != null
                  ? CachedNetworkImageProvider(school.logoUrl!)
                  : null,
              child: school.logoUrl == null
                  ? const Icon(
                      Icons.school_rounded,
                      color: AppTheme.textSecondary,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        school.rating.floor(),
                        (_) => const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                      ...List.generate(
                        5 - school.rating.floor(),
                        (_) => const Icon(
                          Icons.star_outline_rounded,
                          color: AppTheme.textSecondary,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${school.rating.toStringAsFixed(1)} (${school.reviewCount})',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppTheme.successColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        school.priceRangeText,
                        style: GoogleFonts.poppins(
                          color: AppTheme.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.textSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          school.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  'Szczegóły',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
