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

  final percentage =
      (_spentAmount / _budgetAmount!) * 100;

  final monthKey = '$_currentYear$_currentMonth';

  // 100% budget alert
  if (percentage >= 100) {
    final alreadyNotified =
        prefs.getBool('budget100Notified_$monthKey') ?? false;

    if (!alreadyNotified) {
      await NotificationService.showBudgetAlert(
        title: 'Budget Exceeded',
        body:
            'You have exceeded your monthly budget by ₹${(_spentAmount - _budgetAmount!).toStringAsFixed(2)}.',
      );

      await prefs.setBool(
        'budget100Notified_$monthKey',
        true,
      );
    }

    return;
  }

  // 80% budget alert
  if (percentage >= 80) {
    final alreadyNotified =
        prefs.getBool('budget80Notified_$monthKey') ?? false;

    if (alreadyNotified) {
      return;
    }

    await NotificationService.showBudgetAlert(
      title: 'Budget Alert',
      body:
          'You have used ${percentage.toStringAsFixed(0)}% of your monthly budget.',
    );

    await prefs.setBool(
      'budget80Notified_$monthKey',
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
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText: 'Budget amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving ? null : _saveBudget,
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(),
                            )
                          : const Text('Save Budget'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_budgetAmount != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 12,
                      color: _progressColor(),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Budget'),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(
                                _budgetAmount!,
                              ),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            const Text('Spent'),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(
                                _spentAmount,
                              ),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _remaining >= 0
                          ? '${_formatAmount(_remaining)} remaining'
                          : '${_formatAmount(_remaining.abs())} over budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _remaining >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
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
        ],
      ),
    );
  }
}