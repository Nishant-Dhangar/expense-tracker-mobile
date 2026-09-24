import 'package:flutter/material.dart';
import '../services/shake_service.dart';
import '../services/auth_service.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'transactions_screen.dart';
import '../widgets/quick_expense_overlay.dart';
class DashboardScreen extends StatefulWidget {
  final AuthService authService;

  const DashboardScreen({
    super.key,
    required this.authService,
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
        }
      }

      if (!mounted) return;

      setState(() {
        user = currentUser;
        transactions = transactionList;

        totalIncome = income;
        totalExpense = expense;
        balance = income - expense;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Transactions',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionsScreen(
                    authService: widget.authService,
                  ),
                ),
              );

              await _loadDashboard();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.account_balance_wallet,
            ),
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
            'Hello, ${user?['name'] ?? 'User'}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 4),

          Text(
            user?['email'] ?? '',
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),

          const SizedBox(height: 20),

          // Balance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(balance),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Income and Expenses
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatAmount(totalIncome),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatAmount(totalExpense),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No transactions this month',
                  ),
                ),
              ),
            )
          else
            ...recentTransactions.map(
              (transaction) {
                final type =
                    transaction['type']?.toString() ??
                        '';

                final description =
                    transaction['description']
                            ?.toString() ??
                        '';

                final category =
                    transaction['category']?['name']
                            ?.toString() ??
                        'Unknown';

                final amount =
                    double.tryParse(
                          transaction['amount']
                              .toString(),
                        ) ??
                        0;

                final isIncome = type == 'INCOME';

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                      ),
                    ),
                    title: Text(
                      description.isEmpty
                          ? category
                          : description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(category),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}'
                      '${_formatAmount(amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}