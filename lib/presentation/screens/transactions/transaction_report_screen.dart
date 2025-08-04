import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../service_locator.dart';
import '../../providers/transactions/transactions_provider.dart';
import '../../providers/products/products_provider.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../app/utilities/currency_formatter.dart';

class TransactionReportScreen extends StatefulWidget {
  const TransactionReportScreen({super.key});

  @override
  State<TransactionReportScreen> createState() => _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen> {
  final transactionsProvider = sl<TransactionsProvider>();
  String _filter = '7_hari';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Lihat laporan: '),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'harian', child: Text('Harian')),
                    DropdownMenuItem(value: '7_hari', child: Text('7 Hari Terakhir')),
                    DropdownMenuItem(value: '1_bulan', child: Text('1 Bulan Terakhir')),
                    DropdownMenuItem(value: 'all', child: Text('All')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _filter = val);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildReport() {
    final all = transactionsProvider.allTransactions ?? [];
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final allProducts = productsProvider.allProducts ?? [];
    final now = DateTime.now();
    List filtered = all.where((trx) {
      if (trx.createdAt == null) return false;
      final trxDate = DateTime.tryParse(trx.createdAt!);
      if (trxDate == null) return false;
      switch (_filter) {
        case 'harian':
          return trxDate.year == now.year && trxDate.month == now.month && trxDate.day == now.day;
        case '7_hari':
          return trxDate.isAfter(now.subtract(const Duration(days: 7)));
        case '1_bulan':
          return trxDate.isAfter(DateTime(now.year, now.month - 1, now.day));
        case 'all':
        default:
          return true;
      }
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Tidak ada transaksi untuk periode ini.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final trx = filtered[i];
        final date = trx.createdAt != null ? trx.createdAt!.split('T').first : '-';
        // Ambil detail produk dari transaksi jika ada
        final items = trx.items ?? [];
        return ListTile(
          title: Text('Rp${trx.totalAmount}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tanggal: $date\nMetode: ${trx.paymentMethod}${trx.customerName != null ? '\nCustomer: ${trx.customerName}' : ''}',
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Text('Produk:'),
                ...items.map<Widget>((item) {
                  if (item == null) {
                    debugPrint('Null item pada transaksi: id=${trx.id}');
                    return const Text('- Data produk tidak valid');
                  }
                  if (item.productId == null) {
                    debugPrint('Null productId pada transaksi: id=${trx.id}');
                    return Text('- ${item.name} (ID produk tidak valid)');
                  }
                  String unit = 'pcs';
                  final match = allProducts.firstWhere(
                    (p) => p.id == item.productId,
                    orElse: () => ProductEntity(
                      id: item.productId,
                      createdById: '',
                      name: item.name,
                      imageUrl: '',
                      stock: 0,
                      price: item.price,
                      unit: 'pcs',
                    ),
                  );
                  unit = match.unit;
                  return Text('- ${item.name} (${item.quantity} $unit x ${CurrencyFormatter.format(item.price)})');
                }).toList(),
              ],
            ],
          ),
        );
      },
    );
  }
}
