import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/company_provider.dart';
import 'company_form.dart';
import 'ledger_screen.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().loadCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: const Text('Companies'),
        backgroundColor: AppColors.bgBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryOrange),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
          ),
          Expanded(
            child: Consumer<CompanyProvider>(
              builder: (context, prov, _) {
                if (prov.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
                final companies = prov.companies.where((c) =>
                  _search.isEmpty || (c['name'] as String).toLowerCase().contains(_search)).toList();
                if (companies.isEmpty) return const Center(child: Text('No companies found', style: TextStyle(color: AppColors.textSecondary)));
                return RefreshIndicator(
                  color: AppColors.primaryOrange,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => prov.loadCompanies(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: companies.length,
                    itemBuilder: (context, i) => _CompanyTile(
                      company: companies[i],
                      onEdit: () => _openForm(context, company: companies[i]),
                      onDelete: () => _deleteCompany(context, companies[i]),
                      onLedger: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => LedgerScreen(company: companies[i]),
                      )),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {Map<String, dynamic>? company}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CompanyForm(company: company),
    )).then((_) => context.read<CompanyProvider>().loadCompanies());
  }

  void _deleteCompany(BuildContext context, Map<String, dynamic> company) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Company', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${company['name']}"? This cannot be undone.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(80, 40)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CompanyProvider>().deleteCompany(company['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLedger;

  const _CompanyTile({required this.company, required this.onEdit, required this.onDelete, required this.onLedger});

  @override
  Widget build(BuildContext context) {
    final credit = (company['current_credit'] as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: credit > 0 ? AppColors.creditYellow.withOpacity(0.3) : AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.business, color: AppColors.primaryOrange),
        ),
        title: Text(company['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company['contact_person'] != null && company['contact_person'].isNotEmpty)
              Text(company['contact_person'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (company['phone'] != null && company['phone'].isNotEmpty)
              Text(company['phone'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            if (credit > 0)
              Text('Credit: ${CurrencyUtils.format(credit)}', style: const TextStyle(color: AppColors.creditYellow, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.bgCard,
          onSelected: (val) {
            if (val == 'edit') onEdit();
            else if (val == 'delete') onDelete();
            else if (val == 'ledger') onLedger();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'ledger', child: Row(children: [Icon(Icons.receipt_long, color: AppColors.primaryOrange, size: 18), SizedBox(width: 8), Text('Ledger', style: TextStyle(color: AppColors.textPrimary))])),
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: AppColors.info, size: 18), SizedBox(width: 8), Text('Edit', style: TextStyle(color: AppColors.textPrimary))])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppColors.error, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.textPrimary))])),
          ],
        ),
        onTap: onLedger,
      ),
    );
  }
}
