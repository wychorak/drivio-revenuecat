import 'package:cached_network_image/cached_network_image.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SchoolCard extends StatelessWidget {
  final SchoolModel school;

  const SchoolCard({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/school/${school.id}'),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outline.withAlpha(90)),
                ),
                clipBehavior: Clip.antiAlias,
                child: school.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: school.logoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            _SchoolPlaceholder(color: colors.onSurfaceVariant),
                      )
                    : _SchoolPlaceholder(color: colors.onSurfaceVariant),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            school.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: colors.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _InfoChip(
                          icon: Icons.star_rounded,
                          iconColor: AppTheme.premiumGold,
                          text:
                              '${school.rating.toStringAsFixed(1)} · ${school.reviewCount} opinii',
                        ),
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          iconColor: AppTheme.successColor,
                          text: school.priceRangeText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: colors.onSurfaceVariant,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            school.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchoolPlaceholder extends StatelessWidget {
  final Color color;

  const _SchoolPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.school_rounded, color: color, size: 30);
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
