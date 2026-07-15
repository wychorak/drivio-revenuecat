import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/theme/app_theme.dart';

class CommentTile extends StatefulWidget {
  final CommentModel comment;
  final Future<void> Function(String reason)? onReport;
  final Future<void> Function()? onBlock;

  const CommentTile({
    super.key,
    required this.comment,
    this.onReport,
    this.onBlock,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _reported = false;

  String get _initials {
    final name = widget.comment.userDisplayName;
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showReportDialog() {
    const reasons = ['Obraźliwy', 'Fałszywy', 'Spam'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Zgłoś komentarz',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map(
                (r) => ListTile(
                  title: Text(
                    r,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (widget.onReport != null) {
                      await widget.onReport!(r);
                    }
                    if (mounted) {
                      setState(() => _reported = true);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _blockAuthor() async {
    if (widget.onBlock == null) return;
    await widget.onBlock!();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Użytkownik został zablokowany.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withAlpha(25),
                child: Text(
                  _initials,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.comment.userDisplayName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'd MMM yyyy, HH:mm',
                        'pl',
                      ).format(widget.comment.timestamp),
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_reported)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Zgłoszono',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                  color: AppTheme.bgCard,
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportDialog();
                    } else if (value == 'block') {
                      _blockAuthor();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Text(
                        'Zgłoś komentarz',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                    if (widget.onBlock != null)
                      PopupMenuItem(
                        value: 'block',
                        child: Text(
                          'Zablokuj autora',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                  ],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.comment.text,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
