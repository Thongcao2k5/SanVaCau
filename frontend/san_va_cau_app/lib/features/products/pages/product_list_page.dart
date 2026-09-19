import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/product_api.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ProductApi _productApi;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productApi = ProductApi();
    _productsFuture = _productApi.getProducts();
  }

  void _reloadProducts() {
    setState(() {
      _productsFuture = _productApi.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Không thể tải danh sách sản phẩm';

            return _ProductStateMessage(
              icon: Icons.wifi_off_outlined,
              title: 'Có lỗi xảy ra',
              message: message,
              actionText: 'Thử lại',
              onActionPressed: _reloadProducts,
            );
          }

          final products = snapshot.data ?? const <Product>[];

          if (products.isEmpty) {
            return _ProductStateMessage(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có sản phẩm',
              message: 'Khi admin thêm sản phẩm, danh sách sẽ hiển thị ở đây.',
              actionText: 'Tải lại',
              onActionPressed: _reloadProducts,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reloadProducts(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];

                return ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chi tiết ${product.name} sẽ làm tiếp.'),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProductStateMessage extends StatelessWidget {
  const _ProductStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onActionPressed, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
