import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/themes/app_sizes.dart';
import '../../../service_locator.dart';
import '../../providers/transactions/transactions_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_text_field.dart';
import 'components/transaction_card.dart';
import '../../providers/products/products_provider.dart';
import '../../../domain/entities/product_entity.dart';

// Halaman untuk menampilkan daftar histori transaksi user.
// Mengambil data dari TransactionsProvider dan menampilkan list transaksi.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final transactionProvider = sl<TransactionsProvider>();

  final scrollController = ScrollController();

  final searchFieldController = TextEditingController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      transactionProvider.getAllTransactions();
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void scrollListener() async {
    // Automatically load more data on end of scroll position
    if (scrollController.offset == scrollController.position.maxScrollExtent) {
      await transactionProvider.getAllTransactions(offset: transactionProvider.allTransactions?.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'SCD',
            onPressed: () => _showScdDialog(context),
          ),
        ],
      ),
      body: Consumer<TransactionsProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.getAllTransactions(),
            displacement: 60,
            child: Scrollbar(
              child: CustomScrollView(
                controller: scrollController,
                // Disable scroll when data is null or empty
                physics: (provider.allTransactions?.isEmpty ?? true) ? const NeverScrollableScrollPhysics() : null,
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    automaticallyImplyLeading: false,
                    collapsedHeight: 70,
                    titleSpacing: 0,
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                      child: searchField(),
                    ),
                  ),
                  SliverLayoutBuilder(
                    builder: (context, constraint) {
                      if (provider.allTransactions == null) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: AppProgressIndicator(),
                        );
                      }

                      if (provider.allTransactions!.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: AppEmptyState(
                            subtitle: 'No transaction available',
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                        sliver: SliverList.builder(
                          itemCount: provider.allTransactions!.length,
                          itemBuilder: (context, i) {
                            return TransactionCard(transaction: provider.allTransactions![i]);
                          },
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: AppLoadingMoreIndicator(isLoading: provider.isLoadingMore),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showScdDialog(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
    final allProducts = productsProvider.allProducts ?? [];

    ProductEntity? selectedProduct;
    String? scdResult;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cek SCD Produk'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<ProductEntity>(
                    isExpanded: true,
                    value: selectedProduct,
                    hint: const Text('Pilih produk'),
                    items: allProducts.map((product) {
                      return DropdownMenuItem<ProductEntity>(
                        value: product,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProduct = value;
                        scdResult = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedProduct != null && scdResult == null) const Text('Tekan tombol di bawah untuk cek SCD.'),
                  if (scdResult != null) Text(scdResult!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
                if (selectedProduct != null && scdResult == null)
                  ElevatedButton(
                    onPressed: () {
                      // Hitung SCD
                      final now = DateTime.now();
                      final sevenDaysAgo = now.subtract(const Duration(days: 7));
                      final allTransactions = transactionsProvider.allTransactions ?? [];
                      // Filter transaksi 7 hari terakhir
                      final recentTransactions = allTransactions.where((trx) {
                        if (trx.createdAt == null) return false;
                        final trxDate = DateTime.tryParse(trx.createdAt!);
                        if (trxDate == null) return false;
                        return trxDate.isAfter(sevenDaysAgo) && trxDate.isBefore(now.add(const Duration(days: 1)));
                      }).toList();
                      // Hitung total quantity produk di transaksi 7 hari terakhir
                      int totalQty = 0;
                      for (final trx in recentTransactions) {
                        if (trx.orderedProducts == null) continue;
                        for (final op in trx.orderedProducts!) {
                          if (op.productId == selectedProduct!.id) {
                            totalQty += op.quantity;
                          }
                        }
                      }
                      // Hitung rata-rata harian
                      double avgPerDay = totalQty / 7.0;
                      int stock = selectedProduct!.stock;
                      String result;
                      if (avgPerDay == 0) {
                        result = 'Penjualan 7 hari terakhir 0. SCD tidak dapat dihitung.';
                      } else {
                        double scd = stock / avgPerDay;
                        result =
                            'Stok: $stock\nRata-rata terjual/hari: ${avgPerDay.toStringAsFixed(2)}\nSCD: ${scd.toStringAsFixed(1)} hari';
                      }
                      setState(() {
                        scdResult = result;
                      });
                    },
                    child: const Text('Cek SCD'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget searchField() {
    return AppTextField(
      controller: searchFieldController,
      hintText: 'Search Transaction ID...',
      type: AppTextFieldType.search,
      textInputAction: TextInputAction.search,
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        transactionProvider.allTransactions = null;
        transactionProvider.getAllTransactions(contains: searchFieldController.text);
      },
      onTapClearButton: () {
        transactionProvider.getAllTransactions(contains: searchFieldController.text);
      },
    );
  }
}
