import 'package:flutter/material.dart';
import '../services/shake_service.dart';
import '../services/auth_service.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'transactions_screen.dart';
import '../widgets/quick_expense_overlay.dart';
import '../widgets/spending_chart.dart';
import 'settings_screen.dart';
import '../utils/theme_manager.dart';
class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeManager themeManager;
  const DashboardScreen({
  super.key,
  required this.authService,
  required this.themeManager,
});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ShakeService _shakeService = ShakeService();

  Map<String, dynamic>? user;

  List<dynamic> transactions = [];

  bool isLoading = true;
  String? errorMessage;

  double totalIncome = 0;
  double totalExpense = 0;
  double balance = 0;
  Map<String, double> spendingByCategory = {};

void _handleShake() {
  if (!mounted) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return QuickExpenseOverlay(
        authService: widget.authService,
      );
    },
  ).then((result) {
    if (result == true) {
      _loadDashboard();
    }
  });
}

  @override
  void dispose() {
    _shakeService.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _shakeService.start(
  onShake: _handleShake,
);
  }

  Future<void> _loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final currentUser =
          await widget.authService.getCurrentUser();

      final transactionList =
          await widget.authService.getTransactions();

      final now = DateTime.now();

      double income = 0;
      double expense = 0;
      final Map<String, double> categorySpending = {};

      for (final transaction in transactionList) {
        final type = transaction['type']?.toString();

        final dateString =
            transaction['transactionDate']?.toString();

        final amount =
            double.tryParse(
                  transaction['amount'].toString(),
                ) ??
                0;

        if (dateString == null) {
          continue;
        }

        final date = DateTime.tryParse(dateString);

        if (date == null) {
          continue;
        }

        // Only count transactions from the current month.
        if (date.year != now.year ||
            date.month != now.month) {
          continue;
        }

        if (type == 'INCOME') {
          income += amount;
       } else if (type == 'EXPENSE') {
  expense += amount;

  final categoryName =
      transaction['category']?['name']?.toString() ??
          'Other';

  categorySpending[categoryName] =
      (categorySpending[categoryName] ?? 0) + amount;
}
      }

      if (!mounted) return;

      setState(() {
        user = currentUser;
        transactions = transactionList;

        totalIncome = income;
        totalExpense = expense;
        balance = income - expense;
        spendingByCategory = categorySpending;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
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
String _getGreeting() {
  final hour = DateTime.now().hour;

  if (hour < 12) {
    return 'Good morning';
  } else if (hour < 17) {
    return 'Good afternoon';
  } else {
    return 'Good evening';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'Expense Tracker',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.receipt_long_outlined),
      tooltip: 'Transactions',
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionsScreen(
              authService: widget.authService,
            ),
          ),
        );

        await _loadDashboard();
      },
    ),
    IconButton(
      icon: const Icon(Icons.account_balance_wallet_outlined),
      tooltip: 'Budget',
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetScreen(
              authService: widget.authService,
            ),
          ),
        );

        await _loadDashboard();
      },
    ),
  IconButton(
  icon: const Icon(Icons.settings_outlined),
  tooltip: 'Settings',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          authService: widget.authService,
          themeManager: widget.themeManager,
        ),
      ),
    );
  },
),
  ],
),

      body: _buildBody(),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddTransactionScreen(
                authService: widget.authService,
              ),
            ),
          );

          if (result == true) {
            await _loadDashboard();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final recentTransactions =
        transactions.reversed.take(5).toList();

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
  '${_getGreeting()}, ${user?['name'] ?? 'User'} 👋',
  style: Theme.of(context)
      .textTheme
      .headlineSmall
      ?.copyWith(
        fontWeight: FontWeight.bold,
      ),
),

const SizedBox(height: 6),

Text(
  'Here’s your spending overview',
  style: TextStyle(
    color: Colors.grey.shade600,
    fontSize: 14,
  ),
),

const SizedBox(height: 20),
          // Balance
         // Balance
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFF1565C0),
        Color(0xFF42A5F5),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withValues(alpha: 0.25),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),

      Text(
        _formatAmount(balance),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 6),

      Text(
  '${_monthName(DateTime.now().month)} ${DateTime.now().year}',
  style: TextStyle(
    color: Colors.white.withValues(alpha: 0.8),
    fontSize: 14,
  ),
),
    ],
  ),
),
          // Income and Expenses
          // Income and Expenses
Row(
  children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Income',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              _formatAmount(totalIncome),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              _formatAmount(totalExpense),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),

          const SizedBox(height: 24),
          SpendingChart(
  spending: spendingByCategory,
),

const SizedBox(height: 24),

          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

         if (recentTransactions.isEmpty)
  Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          'No transactions this month',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
        ),
      ],
    ),
  )
else
  ...recentTransactions.map(
    (transaction) {
      final type =
          transaction['type']?.toString() ?? '';

      final description =
          transaction['description']?.toString() ?? '';

      final category =
          transaction['category']?['name']?.toString() ??
              'Unknown';

      final dateString =
          transaction['transactionDate']?.toString() ?? '';

      final amount =
          double.tryParse(
                transaction['amount'].toString(),
              ) ??
              0;

      final isIncome = type == 'INCOME';

      final icon = isIncome
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;

      final iconColor =
          isIncome ? Colors.green : Colors.red;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    description.isEmpty
                        ? category
                        : description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$category • $dateString',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: iconColor,
              ),
            ),
          ],
        ),
      );
    },
  ),
        ],
      ),
    );
  }
}