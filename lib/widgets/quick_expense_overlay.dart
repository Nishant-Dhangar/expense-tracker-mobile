import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  color: Theme.of(context).cardColor,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(
    color: Theme.of(context)
        .dividerColor
        .withValues(alpha: 0.15),
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ],
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
    hintText: '0.00',
    prefixText: '₹ ',
    prefixStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.primary,
    ),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.35),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
    ),
  ),
),

          const SizedBox(height: 16),

           Text(
  'Category',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).textTheme.bodyLarge?.color,
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
          _errorMessage = null;
        });
      },
      selectedColor: Theme.of(context)
          .colorScheme
          .primary
          .withValues(alpha: 0.15),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context)
                .dividerColor
                .withValues(alpha: 0.30),
      ),
      labelStyle: TextStyle(
        fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).textTheme.bodyLarge?.color,
      ),
      showCheckmark: true,
    );
  }).toList(),
),

          const SizedBox(height: 16),

         TextField(
  controller: _noteController,
  maxLines: 2,
  textCapitalization: TextCapitalization.sentences,
  decoration: InputDecoration(
    labelText: 'Note',
    hintText: 'What did you spend on?',
    prefixIcon: const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Icon(Icons.notes_outlined),
    ),
    alignLabelWithHint: true,
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.35),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      ),
    ),
  ),
),

          if (_errorMessage != null) ...[
  const SizedBox(height: 12),
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
],

          const SizedBox(height: 20),
SizedBox(
  width: double.infinity,
  height: 54,
  child: ElevatedButton.icon(
    onPressed: _isSaving ? null : _saveExpense,
    icon: _isSaving
        ? const SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : const Icon(
            Icons.check_rounded,
            size: 21,
          ),
    label: Text(
      _isSaving ? 'Saving...' : 'Save Expense',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
),
        ],
      ),
    );
  }
Future<void> _checkBudgetNotification() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final notificationsEnabled =
        prefs.getBool('notificationsEnabled') ?? false;

    if (!notificationsEnabled) return;

    final now = DateTime.now();

    final budget = await widget.authService.getBudget(
  now.year,
  now.month,
);

    if (budget == null || budget['amount'] == null) return;

    final budgetAmount = (budget['amount'] as num).toDouble();

    if (budgetAmount <= 0) return;

    final transactions =
        await widget.authService.getTransactions();

    double spentAmount = 0;

    for (final transaction in transactions) {
      final type = transaction['type']?.toString().toUpperCase();
      final dateString = transaction['transactionDate']?.toString();

      if (type != 'EXPENSE' || dateString == null) continue;

      final date = DateTime.tryParse(dateString);

      if (date != null &&
          date.year == now.year &&
          date.month == now.month) {
        spentAmount +=
            (transaction['amount'] as num).toDouble();
      }
    }

    final percentage = (spentAmount / budgetAmount) * 100;

    final currentUser =
        await widget.authService.getCurrentUser();

    final userId = currentUser['id'];

    if (userId == null) return;

    final budget80Key =
        'budget80Notified_${userId}_${now.year}_${now.month}';

    final budget100Key =
        'budget100Notified_${userId}_${now.year}_${now.month}';

    if (percentage >= 100) {
      final alreadyNotified =
          prefs.getBool(budget100Key) ?? false;

      if (!alreadyNotified) {
        await NotificationService.showBudgetAlert(
          title: 'Budget Exceeded',
          body:
              'You have exceeded your monthly budget by ₹${(spentAmount - budgetAmount).toStringAsFixed(2)}.',
        );

        await prefs.setBool(budget100Key, true);
      }

      return;
    }

    if (percentage >= 80) {
      final alreadyNotified =
          prefs.getBool(budget80Key) ?? false;

      if (!alreadyNotified) {
        await NotificationService.showBudgetAlert(
          title: 'Budget Alert',
          body:
              'You have used ${percentage.toStringAsFixed(0)}% of your monthly budget.',
        );

        await prefs.setBool(budget80Key, true);
      }
    }
  } catch (_) {
    // Notification failure should not prevent saving the expense.
  }
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

// Check budget after the expense has been saved.
await _checkBudgetNotification();

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