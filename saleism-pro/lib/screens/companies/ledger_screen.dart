import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/company_provider.dart';

class LedgerScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  const LedgerScreen({super.key, required this.company});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Map<String, dynamic>> _ledger = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await context.read<CompanyProvider>().getLedger(widget.company['id']);
    if (mounted) setState(() { _ledger = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final credit = (widget.company['current_credit'] as num).toDouble();
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: Text(widget.company['name'] ?? ''),
        backgroundColor: AppColors.bgBlack,
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: credit > 0 ? AppColors.creditYellow.withOpacity(0.4) : AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Balance', style: TextStyle(color: AppColors.textSecondary)),
                    Text(CurrencyUtils.format(credit),
                      style: TextStyle(
                        color: credit > 0 ? AppColors.creditYellow : AppColors.profitGreen,
                        fontWeight: FontWeight.w800, fontSize: 18,
                      )),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(label: 'Phone', value: widget.company['phone'] ?? '-', icon: Icons.phone),
                    _SummaryItem(label: 'Credit Limit', value: CurrencyUtils.format((widget.company['credit_limit'] as num).toDouble()), icon: Icons.credit_card),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.primaryOrange, size: 18),
                const SizedBox(width: 8),
                const Text('Transaction History', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${_ledger.length} entries', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)))
          else if (_ledger.isEmpty)
            const Expanded(child: Center(child: Text('No transactions found', style: TextStyle(color: AppColors.textSecondary))))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _ledger.length,
                itemBuilder: (context, i) {
                  final entry = _ledger[i];
                  final debit = (entry['debit'] as num).toDouble();
                  final credit2 = (entry['credit'] as num).toDouble();
                  final balance = (entry['balance'] as num).toDouble();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry['description'] ?? entry['type'] ?? '',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(DateUtils2.toDisplay(entry['date']), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (debit > 0) _LedgerTag(label: 'Dr: ${CurrencyUtils.format(debit)}', color: AppColors.lossRed),
                            if (credit2 > 0) ...[const SizedBox(width: 8), _LedgerTag(label: 'Cr: ${CurrencyUtils.format(credit2)}', color: AppColors.profitGreen)],
                            const Spacer(),
                            Text('Bal: ${CurrencyUtils.format(balance)}',
                              style: TextStyle(color: balance > 0 ? AppColors.creditYellow : AppColors.profitGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 18),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class _LedgerTag extends StatelessWidget {
  final String label;
  final Color color;
  const _LedgerTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
