import 'package:flutter/material.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: const Center(
        child: Text('Reports List - Coming Soon'),
      ),
    );
  }
}

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Report'),
      ),
      body: const Center(
        child: Text('Create Report - Coming Soon'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text('Profile - Coming Soon'),
      ),
    );
  }
}