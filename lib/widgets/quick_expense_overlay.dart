import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class QuickExpenseOverlay extends StatefulWidget {
  final AuthService authService;

  const QuickExpenseOverlay({
    super.key,
    required this.authService,
  });

  @override
  State<QuickExpenseOverlay> createState() => _QuickExpenseOverlayState();
}

class _QuickExpenseOverlayState extends State<QuickExpenseOverlay> {
  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _noteController =
      TextEditingController();

  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.authService.getCategories();

      final expenseCategories = categories.where((category) {
        return category['type'] == 'EXPENSE';
      }).toList();

      if (!mounted) return;

      setState(() {
        _categories = expenseCategories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
  children: [
    Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.flash_on_rounded,
        color: Colors.blue,
        size: 26,
      ),
    ),
    const SizedBox(width: 12),
    const Expanded(
      child: Text(
        'Quick Expense',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.close_rounded),
      tooltip: 'Close',
    ),
  ],
),

          const SizedBox(height: 24),

          TextField(
  controller: _amountController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  ),
  decoration: InputDecoration(
    labelText: 'Amount',
    prefixText: '₹ ',
    prefixStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.grey.shade300,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Colors.blue,
        width: 2,
      ),
    ),
  ),
),

          const SizedBox(height: 16),

          const Text(
  'Category',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 10),

Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _categories.map<Widget>((category) {
    final categoryId = category['id'] as int;
    final isSelected = _selectedCategoryId == categoryId;

    return ChoiceChip(
      label: Text(category['name']),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedCategoryId = categoryId;
        });
      },
    );
  }).toList(),
),

          const SizedBox(height: 16),

          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'What did you spend on?',
              border: OutlineInputBorder(),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton.icon(
    onPressed: _isSaving ? null : _saveExpense,
    icon: _isSaving
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.check_rounded),
    label: Text(
      _isSaving ? 'Saving...' : 'Save Expense',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
),
        ],
      ),
    );
  }

  Future<void> _saveExpense() async {
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

    try {
      final now = DateTime.now();

      final date =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      await widget.authService.addTransaction(
        amount: amount,
        type: 'EXPENSE',
        description: _noteController.text.trim(),
        transactionDate: date,
        categoryId: _selectedCategoryId!,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = e.toString();
      });
    }
  }
}