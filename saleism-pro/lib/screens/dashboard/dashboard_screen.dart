import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/stat_card.dart';
import '../stock/stock_screen.dart';
import '../companies/companies_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dash, _) {
            if (dash.loading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
            }
            return RefreshIndicator(
              color: AppColors.primaryOrange,
              backgroundColor: AppColors.bgCard,
              onRefresh: () => dash.loadDashboard(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SALEISM PRO', style: TextStyle(color: AppColors.primaryOrange, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              Text('Welcome, ${auth.userName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                            onPressed: () => _logout(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top feature card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryOrange, AppColors.orangeDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Today's Sales", style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyUtils.format(dash.todaySales),
                                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.trending_up, color: Colors.white70, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Margin: ${dash.profitMargin.toStringAsFixed(1)}%',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.show_chart, color: Colors.white30, size: 64),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text('Overview', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),

                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.5,
                            children: [
                              StatCard(
                                title: 'Stock Value',
                                value: CurrencyUtils.formatCompact(dash.stockValue),
                                icon: Icons.inventory_2_outlined,
                                color: AppColors.info,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockScreen())),
                              ),
                              StatCard(
                                title: 'Total Profit',
                                value: CurrencyUtils.formatCompact(dash.totalProfit),
                                icon: Icons.trending_up,
                                color: AppColors.profitGreen,
                                highlight: true,
                              ),
                              StatCard(
                                title: 'Total Sales',
                                value: CurrencyUtils.formatCompact(dash.totalSales),
                                icon: Icons.point_of_sale,
                                color: AppColors.primaryOrange,
                              ),
                              StatCard(
                                title: 'Total Purchase',
                                value: CurrencyUtils.formatCompact(dash.totalPurchase),
                                icon: Icons.shopping_cart_outlined,
                                color: AppColors.warning,
                              ),
                              StatCard(
                                title: 'Outstanding',
                                value: CurrencyUtils.formatCompact(dash.outstandingCredit),
                                icon: Icons.account_balance_wallet_outlined,
                                color: AppColors.creditYellow,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompaniesScreen())),
                              ),
                              StatCard(
                                title: 'Low Stock',
                                value: '${dash.lowStockCount} items',
                                icon: Icons.warning_amber_outlined,
                                color: AppColors.lossRed,
                                highlight: dash.lowStockCount > 0,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockScreen())),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (dash.lowStockProducts.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.warning_amber, color: AppColors.lossRed, size: 18),
                                const SizedBox(width: 6),
                                const Text('Low Stock Alert', style: TextStyle(color: AppColors.lossRed, fontSize: 15, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...dash.lowStockProducts.take(3).map((p) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.lossRed.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.inventory_2, color: AppColors.lossRed, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(p['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                                  Text('${p['total_pieces'] ?? 0} pcs', style: const TextStyle(color: AppColors.lossRed, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            )),
                            const SizedBox(height: 20),
                          ],

                          Row(
                            children: [
                              const Text('Companies', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text('${dash.totalCompanies} total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompaniesScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.business, color: AppColors.primaryOrange),
                                  const SizedBox(width: 12),
                                  const Text('Manage Companies & Ledger', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(80, 40)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
