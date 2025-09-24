import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/need_request.dart';
import '../../services/database_service.dart';

class NeedRequestScreen extends StatefulWidget {
  const NeedRequestScreen({super.key});

  @override
  State<NeedRequestScreen> createState() => _NeedRequestScreenState();
}

class _NeedRequestScreenState extends State<NeedRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _beneficiariesController = TextEditingController();
  final _justificationController = TextEditingController();
  
  String _selectedNeedType = NeedType.infrastructure;
  NeedPriority _selectedPriority = NeedPriority.medium;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _beneficiariesController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Facility/Service'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          const Icon(
                            Icons.add_location_alt,
                            size: 48,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Request New Facility',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Help improve your community by requesting needed facilities and services',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Need Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedNeedType,
                            decoration: InputDecoration(
                              labelText: 'Facility/Service Type',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: NeedType.all.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(NeedType.displayNames[type] ?? type),
                                    Text(
                                      NeedType.descriptions[type] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedNeedType = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a facility type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Title
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Request Title',
                              hintText: 'Brief title for your request',
                              prefixIcon: const Icon(Icons.title),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              if (value.trim().length < 5) {
                                return 'Title must be at least 5 characters long';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Detailed Description',
                              hintText: 'Explain what facility/service is needed and why',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please provide a description';
                              }
                              if (value.trim().length < 20) {
                                return 'Description must be at least 20 characters long';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Location
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location/Area',
                              hintText: 'Where is this facility needed?',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please specify the location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Detailed Address (Optional)',
                              hintText: 'Full address or landmarks',
                              prefixIcon: const Icon(Icons.home),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Priority
                          DropdownButtonFormField<NeedPriority>(
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority Level',
                              prefixIcon: const Icon(Icons.priority_high),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: NeedPriority.values.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getPriorityIcon(priority),
                                      color: _getPriorityColor(priority),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_getPriorityLabel(priority)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Estimated Beneficiaries
                          TextFormField(
                            controller: _beneficiariesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Estimated Beneficiaries',
                              hintText: 'How many people will benefit?',
                              prefixIcon: const Icon(Icons.people),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please estimate the number of beneficiaries';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number <= 0) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Justification
                          TextFormField(
                            controller: _justificationController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Justification (Optional)',
                              hintText: 'Why is this facility important for the community?',
                              prefixIcon: const Icon(Icons.notes),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send),
                                      SizedBox(width: 8),
                                      Text(
                                        'Submit Request',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPriorityIcon(NeedPriority priority) {
    switch (priority) {
      case NeedPriority.low:
        return Icons.low_priority;
      case NeedPriority.medium:
        return Icons.circle;
      case NeedPriority.high:
        return Icons.priority_high;
      case NeedPriority.urgent:
        return Icons.emergency;
    }
  }

  Color _getPriorityColor(NeedPriority priority) {
    switch (priority) {
      case NeedPriority.low:
        return Colors.green;
      case NeedPriority.medium:
        return Colors.orange;
      case NeedPriority.high:
        return Colors.red;
      case NeedPriority.urgent:
        return Colors.red[800]!;
    }
  }

  String _getPriorityLabel(NeedPriority priority) {
    switch (priority) {
      case NeedPriority.low:
        return 'Low Priority';
      case NeedPriority.medium:
        return 'Medium Priority';
      case NeedPriority.high:
        return 'High Priority';
      case NeedPriority.urgent:
        return 'Urgent';
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userSession = await DatabaseService.instance.getCurrentUserSession();
      
      final needRequest = NeedRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        needType: _selectedNeedType,
        priority: _selectedPriority,
        status: NeedStatus.submitted,
        location: _locationController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        requesterName: userSession?['userName'] ?? 'Anonymous',
        requesterEmail: userSession?['userEmail'] ?? '',
        estimatedBeneficiaries: int.parse(_beneficiariesController.text.trim()),
        justification: _justificationController.text.trim().isEmpty ? null : _justificationController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Save to database
      await DatabaseService.instance.saveNeedRequest(needRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Need request submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _addressController.clear();
        _beneficiariesController.clear();
        _justificationController.clear();
        setState(() {
          _selectedNeedType = NeedType.infrastructure;
          _selectedPriority = NeedPriority.medium;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}