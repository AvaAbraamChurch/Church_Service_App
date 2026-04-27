import 'dart:convert';

import 'package:church/core/services/supabase_bulk_create_users.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';

class BulkCreateUsersScreen extends StatefulWidget {
  const BulkCreateUsersScreen({super.key});

  @override
  State<BulkCreateUsersScreen> createState() => _BulkCreateUsersScreenState();
}

class _BulkCreateUsersScreenState extends State<BulkCreateUsersScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  BulkCreateResult? _result;

  @override
  void initState() {
    super.initState();
    _jsonController.text = _sampleJson;
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _submitBulkCreate() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    List<BulkUserInput> users;
    try {
      users = _parseUsers(_jsonController.text);
    } catch (e) {
      _showError('Invalid JSON payload: $e');
      return;
    }

    if (users.isEmpty) {
      _showError('Please provide at least one user.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _result = null;
    });

    try {
      final response = await bulkCreateUsers(users);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = response;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Done: ${response.summary.success}/${response.summary.total} users created.',
          ),
          backgroundColor: response.summary.failed > 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  List<BulkUserInput> _parseUsers(String payload) {
    final dynamic decoded = jsonDecode(payload);
    final List<dynamic> rawUsers;

    if (decoded is List<dynamic>) {
      rawUsers = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['users'] is List<dynamic>) {
      rawUsers = decoded['users'] as List<dynamic>;
    } else {
      throw const FormatException('Expected a JSON array or {"users": [...]} object.');
    }

    return rawUsers
        .whereType<Map<String, dynamic>>()
        .map(BulkUserInput.fromJson)
        .where((user) => user.name.isNotEmpty)
        .toList();
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        title: const Text('إضافة مستخدمين بالجملة'),
        backgroundColor: teal700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste JSON users payload and submit to Supabase Edge Function.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jsonController,
                maxLines: 14,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'Users JSON',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'JSON payload is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            _jsonController.text = _sampleJson;
                          },
                    icon: const Icon(Icons.restore),
                    label: const Text('Sample'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitBulkCreate,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Create Users'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_result != null) _buildResultCard(_result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BulkCreateResult result) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary: ${result.summary.success}/${result.summary.total} success, ${result.summary.failed} failed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (result.successful.isNotEmpty)
              ExpansionTile(
                title: Text('Successful (${result.successful.length})'),
                children: result.successful
                    .map(
                      (user) => ListTile(
                        dense: true,
                        title: Text(user.name),
                        subtitle: Text('${user.email} | ${user.username}'),
                      ),
                    )
                    .toList(),
              ),
            if (result.failed.isNotEmpty)
              ExpansionTile(
                title: Text('Failed (${result.failed.length})'),
                children: result.failed
                    .map(
                      (user) => ListTile(
                        dense: true,
                        title: Text(user.name),
                        subtitle: Text('${user.email} | ${user.error}'),
                        leading: const Icon(Icons.error_outline, color: Colors.red),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

const String _sampleJson = '''[
  {
    "name": "John Doe",
    "userType": "CH",
    "gender": "M",
    "userClass": "class_1",
    "serviceType": "primaryBoys",
    "phoneNumber": "0100000000",
    "address": "Cairo",
    "birthday": "2012-05-01"
  },
  {
    "name": "Mary Mina",
    "userType": "SV",
    "gender": "F",
    "userClass": "class_2",
    "serviceType": "primaryGirls"
  }
]''';

