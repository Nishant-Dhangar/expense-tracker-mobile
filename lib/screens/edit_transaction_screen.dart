import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EditTransactionScreen extends StatefulWidget {
  final AuthService authService;
  final Map<String, dynamic> transaction;

  const EditTransactionScreen({
    super.key,
    required this.authService,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends State<EditTransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  String _type = 'EXPENSE';
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    _amountController = TextEditingController(
      text: transaction['amount']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: transaction['description']?.toString() ?? '',
    );

    _type = transaction['type']?.toString() ?? 'EXPENSE';

    final dateString =
        transaction['transactionDate']?.toString();

    if (dateString != null && dateString.isNotEmpty) {
      _selectedDate = DateTime.tryParse(dateString) ??
          DateTime.now();
    }

    _selectedCategoryId =
        transaction['category']?['id'] as int?;

    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await widget.authService.getCategories();

      final filtered = categories
          .where((category) =>
              category['type']?.toString() == _type)
          .toList();

      int? categoryId = _selectedCategoryId;

      final categoryExists = filtered.any(
        (category) => category['id'] == categoryId,
      );

      if (!categoryExists) {
        categoryId =
            filtered.isNotEmpty ? filtered.first['id'] as int : null;
      }

      setState(() {
        _categories = filtered;
        _selectedCategoryId = categoryId;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingCategories = false;
      });
    }
  }

  void _changeType(String type) {
    setState(() {
      _type = type;
      _selectedCategoryId = null;
      _isLoadingCategories = true;
    });

    _loadCategories();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount =
        double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid amount';
      });
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final date =
        '${_selectedDate.year.toString().padLeft(4, '0')}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';

    try {
      await widget.authService.updateTransaction(
        id: widget.transaction['id'] as int,
        amount: amount,
        type: _type,
        description: _descriptionController.text.trim(),
        transactionDate: date,
        categoryId: _selectedCategoryId!,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'EXPENSE',
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'INCOME',
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                _changeType(selection.first);
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoadingCategories)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'] as int,
                    child: Text(
                      category['name'].toString(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),

            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Date: ${_selectedDate.day.toString().padLeft(2, '0')}/'
                  '${_selectedDate.month.toString().padLeft(2, '0')}/'
                  '${_selectedDate.year}',
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isSaving ? null : _saveTransaction,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Update Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}