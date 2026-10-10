import 'package:flutter/material.dart';
import 'package:drivio/widgets/common/coming_soon.dart';

/// Driving schools are not part of the first release yet.
class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Szkoły jazdy')),
      body: const ComingSoon(),
    );
  }
}
