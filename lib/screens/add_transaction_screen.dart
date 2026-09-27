import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
class AddTransactionScreen extends StatefulWidget {
  final AuthService authService;

  const AddTransactionScreen({
    super.key,
    required this.authService,
  });

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'EXPENSE';
  DateTime _selectedDate = DateTime.now();

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
      final categories =
          await widget.authService.getCategories();

      final filteredCategories = categories
          .where(
            (category) =>
                category['type'] == _type,
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _categories = filteredCategories;
        _selectedCategoryId =
            filteredCategories.isNotEmpty
                ? filteredCategories.first['id']
                : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _isLoading = false;
      });
    }
  }

  void _changeType(String type) {

    setState(() {
      _type = type;
      _selectedCategoryId = null;
    });

    _loadCategories();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        _errorMessage =
            'Enter a valid amount greater than 0';
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
      final date =
          '${_selectedDate.year.toString().padLeft(4, '0')}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}';

      await widget.authService.addTransaction(
  amount: amount,
  type: _type,
  description:
      _descriptionController.text.trim(),
  transactionDate: date,
  categoryId: _selectedCategoryId!,
);

await _checkBudgetAfterExpense();

if (!mounted) return;

Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
Future<void> _checkBudgetAfterExpense() async {
  if (_type != 'EXPENSE') {
    return;
  }

  final prefs = await SharedPreferences.getInstance();

  final notificationsEnabled =
      prefs.getBool('notificationsEnabled') ?? false;
debugPrint(
  'NOTIFICATIONS ENABLED: $notificationsEnabled',
);
  if (!notificationsEnabled) {
    return;
  }

  final now = DateTime.now();

  final budget = await widget.authService.getBudget(
    now.year,
    now.month,
  );
  debugPrint('BUDGET RESULT: $budget');

  if (budget == null) {
    return;
  }

  final budgetAmount =
      double.tryParse(budget['amount'].toString());

  if (budgetAmount == null || budgetAmount <= 0) {
    return;
  }

  final transactions =
      await widget.authService.getTransactions();

  double spent = 0;

  for (final transaction in transactions) {
    if (transaction['type']?.toString() != 'EXPENSE') {
      continue;
    }

    final dateString =
        transaction['transactionDate']?.toString();

    if (dateString == null) {
      continue;
    }

    final transactionDate =
        DateTime.tryParse(dateString);

    if (transactionDate == null) {
      continue;
    }

    if (transactionDate.year == now.year &&
        transactionDate.month == now.month) {
      spent +=
          double.tryParse(
                transaction['amount'].toString(),
              ) ??
              0;
    }
  }

  final percentage =
      (spent / budgetAmount) * 100;
debugPrint(
  'BUDGET CHECK: spent=$spent, budget=$budgetAmount, percentage=$percentage',
);
  final monthKey =
      '${now.year}_${now.month}';

  // 🔴 100%+ alert
  if (percentage >= 100) {
    final alreadyNotified =
    prefs.getBool(
          'Budget100Notified_$monthKey',
        ) ??
        false;

    if (!alreadyNotified) {
      await NotificationService.showBudgetAlert(
        title: 'Budget Exceeded',
        body:
            'You have exceeded your monthly budget by ₹${(spent - budgetAmount).toStringAsFixed(2)}.',
      );

      await prefs.setBool(
        'Budget100Notified_$monthKey',
        true,
      );
    }

    return;
  }

  // 🟠 80% alert
  if (percentage >= 80) {
   final alreadyNotified =
    prefs.getBool(
          'Budget80Notified_$monthKey',
        ) ??
        false;
        debugPrint(
  '80% ALREADY NOTIFIED: $alreadyNotified',
);

    if (!alreadyNotified) {
      await NotificationService.showBudgetAlert(
        title: 'Budget Alert',
        body:
            'You have used ${percentage.toStringAsFixed(0)}% of your monthly budget.',
      );

     await prefs.setBool(
  'Budget80Notified_$monthKey',
  true,
);
    }
  }
}
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  // Transaction type
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

                  const SizedBox(height: 25),

                  // Amount
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

                  // Category
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(
                          category['name'],
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

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.day}/'
                      '${_selectedDate.month}/'
                      '${_selectedDate.year}',
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving ? null : _saveTransaction,
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text('Save Transaction'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}