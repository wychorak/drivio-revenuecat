import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivio/config/app_config.dart';

/// Opens the privacy policy hosted on the public site.
Future<void> openPrivacyPolicy(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(
    Uri.parse(AppConfig.privacyPolicyUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Nie udało się otworzyć polityki prywatności. '
          'Znajdziesz ją na ${AppConfig.privacyPolicyUrl}',
        ),
      ),
    );
  }
}
