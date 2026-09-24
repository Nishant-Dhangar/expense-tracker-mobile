import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'edit_transaction_screen.dart';
class TransactionsScreen extends StatefulWidget {
  final AuthService authService;

  const TransactionsScreen({
    super.key,
    required this.authService,
  });

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions =
          await widget.authService.getTransactions();

      setState(() {
        _transactions = transactions.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatAmount(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0;
    return '₹${value.toStringAsFixed(2)}';
  }

  String _formatDate(String date) {
    final parts = date.split('-');

    if (parts.length != 3) {
      return date;
    }

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Future<void> _confirmDelete(
    Map<String, dynamic> transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text(
            'Are you sure you want to delete this transaction?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final id = transaction['id'] as int;

      await widget.authService.deleteTransaction(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted'),
        ),
      );

      await _loadTransactions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
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

    if (_errorMessage != null) {
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
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTransactions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];

          final type = transaction['type']?.toString() ?? '';

          final description =
              transaction['description']?.toString() ?? '';

          final category =
              transaction['category']?['name']?.toString() ??
                  'Unknown';

          final date =
              transaction['transactionDate']?.toString() ?? '';

          final isIncome = type == 'INCOME';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                ),
              ),
              title: Text(
                description.isEmpty ? category : description,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '$category • ${_formatDate(date)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${_formatAmount(transaction['amount'])}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isIncome
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
  icon: const Icon(
    Icons.edit_outlined,
  ),
  tooltip: 'Edit',
  onPressed: () async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(
          authService: widget.authService,
          transaction: transaction,
        ),
      ),
    );

    if (updated == true) {
      await _loadTransactions();
    }
  },
),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    tooltip: 'Delete',
                    onPressed: () {
                      _confirmDelete(transaction);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}