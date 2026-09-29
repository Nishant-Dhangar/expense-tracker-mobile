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

  if (!notificationsEnabled) {
    return;
  }

  final currentUser =
      await widget.authService.getCurrentUser();

  final userId = currentUser['id'];

  if (userId == null) {
    return;
  }

  final now = DateTime.now();

  final budget = await widget.authService.getBudget(
    now.year,
    now.month,
  );

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

  final monthKey =
      '${now.year}_${now.month}';

  final budget80Key =
      'budget80Notified_${userId}_$monthKey';

  final budget100Key =
      'budget100Notified_${userId}_$monthKey';

  // 🔴 100%+ alert
  if (percentage >= 100) {
    final alreadyNotified =
        prefs.getBool(budget100Key) ?? false;

    if (!alreadyNotified) {
      await NotificationService.showBudgetAlert(
        title: 'Budget Exceeded',
        body:
            'You have exceeded your monthly budget by ₹${(spent - budgetAmount).toStringAsFixed(2)}.',
      );

      await prefs.setBool(
        budget100Key,
        true,
      );
    }

    return;
  }

  // 🟠 80% alert
  if (percentage >= 80) {
    final alreadyNotified =
        prefs.getBool(budget80Key) ?? false;

    if (!alreadyNotified) {
      await NotificationService.showBudgetAlert(
        title: 'Budget Alert',
        body:
            'You have used ${percentage.toStringAsFixed(0)}% of your monthly budget.',
      );

      await prefs.setBool(
        budget80Key,
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
      icon: Icon(Icons.arrow_upward_rounded),
    ),
    ButtonSegment(
      value: 'INCOME',
      label: Text('Income'),
      icon: Icon(Icons.arrow_downward_rounded),
    ),
  ],
  selected: {_type},
  onSelectionChanged: (selection) {
    _changeType(selection.first);
  },
  style: ButtonStyle(
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),
    ),
    textStyle: WidgetStateProperty.all(
      const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),

                  const SizedBox(height: 25),

                  // Amount
                  TextField(
  controller: _amountController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
  decoration: InputDecoration(
    labelText: 'Amount',
    hintText: '0.00',
    prefixText: '₹ ',
    prefixStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.primary,
    ),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.35),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      ),
    ),
  ),
),

                  const SizedBox(height: 16),

                  // Category
                 DropdownButtonFormField<int>(
  initialValue: _selectedCategoryId,
  decoration: InputDecoration(
    labelText: 'Category',
    prefixIcon: const Icon(Icons.category_outlined),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.35),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      ),
    ),
  ),
  items: _categories.map((category) {
    return DropdownMenuItem<int>(
      value: category['id'],
      child: Text(
        category['name'],
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
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
  maxLines: 2,
  textCapitalization: TextCapitalization.sentences,
  decoration: InputDecoration(
    labelText: 'Description',
    hintText: 'What was this transaction for?',
    prefixIcon: const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Icon(Icons.notes_outlined),
    ),
    alignLabelWithHint: true,
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.35),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      ),
    ),
  ),
),

                  const SizedBox(height: 16),

                  // Date
                  Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Theme.of(context)
          .dividerColor
          .withValues(alpha: 0.35),
    ),
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
    ),
    leading: Icon(
      Icons.calendar_today_outlined,
      color: Theme.of(context).colorScheme.primary,
    ),
    title: const Text(
      'Transaction Date',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: Text(
      '${_selectedDate.day}/'
      '${_selectedDate.month}/'
      '${_selectedDate.year}',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
    ),
    onTap: _selectDate,
  ),
),

                  const SizedBox(height: 16),

                  if (_errorMessage != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.red.withValues(alpha: 0.20),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.red,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ),

                  const SizedBox(height: 10),

                  SizedBox(
  height: 54,
  child: ElevatedButton(
    onPressed: _isSaving ? null : _saveTransaction,
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    child: _isSaving
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_rounded,
                size: 21,
              ),
              SizedBox(width: 8),
              Text('Save Transaction'),
            ],
          ),
  ),
),
                ],
              ),
            ),
    );
  }
}