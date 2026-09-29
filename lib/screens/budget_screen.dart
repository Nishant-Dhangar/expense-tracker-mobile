import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
class BudgetScreen extends StatefulWidget {
  final AuthService authService;

  const BudgetScreen({
    super.key,
    required this.authService,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController _budgetController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  double? _budgetAmount;
  double _spentAmount = 0;

  String? _errorMessage;

  late int _currentMonth;
  late int _currentYear;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;

    _loadBudget();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final budget = await widget.authService.getBudget(
        _currentYear,
        _currentMonth,
      );

      final transactions =
          await widget.authService.getTransactions();

      double spent = 0;

      for (final transaction in transactions) {
        final type = transaction['type']?.toString();

        final dateString =
            transaction['transactionDate']?.toString();

        final amount =
            double.tryParse(
                  transaction['amount'].toString(),
                ) ??
                0;

        if (type == 'EXPENSE' && dateString != null) {
          final date = DateTime.tryParse(dateString);

          if (date != null &&
              date.year == _currentYear &&
              date.month == _currentMonth) {
            spent += amount;
          }
        }
      }

      setState(() {
        _budgetAmount =
            budget == null
                ? null
                : double.tryParse(
                    budget['amount'].toString(),
                  );

        _spentAmount = spent;

        if (_budgetAmount != null) {
          _budgetController.text =
              _budgetAmount!.toStringAsFixed(2);
        }

        _isLoading = false;
      });
      await _checkBudgetNotification();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      await _checkBudgetNotification();
    }
  }

  Future<void> _saveBudget() async {
    final amount =
        double.tryParse(_budgetController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid budget amount';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.saveBudget(
        month: _currentMonth,
        year: _currentYear,
        amount: amount,
      );

      if (!mounted) return;

      setState(() {
        _budgetAmount = amount;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved successfully'),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  double get _remaining {
    if (_budgetAmount == null) {
      return 0;
    }

    return _budgetAmount! - _spentAmount;
  }

  double get _progress {
    if (_budgetAmount == null || _budgetAmount! <= 0) {
      return 0;
    }

    return (_spentAmount / _budgetAmount!)
        .clamp(0.0, 1.0);
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  Color _progressColor() {
    if (_budgetAmount == null) {
      return Colors.blue;
    }

    final percentage =
        _spentAmount / _budgetAmount!;

    if (percentage >= 1) {
      return Colors.red;
    }

    if (percentage >= 0.75) {
      return Colors.orange;
    }

    return Colors.blue;
  }
Future<void> _checkBudgetNotification() async {
  if (_budgetAmount == null || _budgetAmount! <= 0) {
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

  final percentage =
      (_spentAmount / _budgetAmount!) * 100;

  final monthKey =
      '${percentage.toStringAsFixed(0)}%';

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
            'You have exceeded your monthly budget by ₹${(_spentAmount - _budgetAmount!).toStringAsFixed(2)}.',
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

    if (alreadyNotified) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBudget,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
  '${_monthName(_currentMonth)} $_currentYear',
  style: Theme.of(context)
      .textTheme
      .headlineSmall
      ?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
),

const SizedBox(height: 6),

Text(
  'Set a spending limit and keep track of your monthly expenses.',
  style: TextStyle(
    fontSize: 13,
    color: Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.60),
  ),
),

const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),
TextField(
  controller: _budgetController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
  decoration: InputDecoration(
    labelText: 'Budget amount',
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

                  SizedBox(
  width: double.infinity,
  height: 54,
  child: ElevatedButton(
    onPressed: _isSaving ? null : _saveBudget,
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
                Icons.save_outlined,
                size: 20,
              ),
              SizedBox(width: 8),
              Text('Save Budget'),
            ],
          ),
  ),
),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
if (_budgetAmount != null)
  Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context)
            .dividerColor
            .withValues(alpha: 0.15),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _progressColor()
                    .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: _progressColor(),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Budget Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${((_spentAmount / _budgetAmount!) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _progressColor(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 12,
            color: _progressColor(),
            backgroundColor: Theme.of(context)
                .dividerColor
                .withValues(alpha: 0.12),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatAmount(_budgetAmount!),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatAmount(_spentAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    _remaining >= 0
                        ? 'Remaining'
                        : 'Over',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatAmount(_remaining.abs()),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _remaining >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _progressColor()
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _remaining >= 0
                    ? Icons.info_outline_rounded
                    : Icons.warning_amber_rounded,
                size: 20,
                color: _progressColor(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _remaining >= 0
                      ? '${_formatAmount(_remaining)} left in your budget'
                      : 'You are ${_formatAmount(_remaining.abs())} over budget',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _progressColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        ],
      ),
    );
  }
}