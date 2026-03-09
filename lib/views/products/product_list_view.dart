import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../widgets/product_tile.dart';
import '../../widgets/empty_state.dart';
import '../../utils/theme.dart';
import 'product_form_view.dart';

/// Product list with search, category filter, and CRUD actions.
class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProductController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk & Stok'),
      ),
      body: Column(
        children: [
          // ─── Search bar ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: ctrl.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),

          // ─── Category chips ────────────────────────────
          if (ctrl.categories.length > 1)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: ctrl.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = ctrl.categories[index];
                  final isSelected = cat == ctrl.selectedCategory;
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => ctrl.setCategory(cat),
                    backgroundColor: isDarkMode ? AppTheme.cardDark : Colors.white,
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDarkMode 
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppTheme.textSecondary.withValues(alpha: 0.4)),
                      width: isSelected ? 2 : 1,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: isSelected 
                          ? AppTheme.primaryColor
                          : (isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // ─── Product list ──────────────────────────────
          Expanded(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.products.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Belum ada produk',
                        subtitle: 'Tambahkan produk pertamamu',
                        action: ElevatedButton.icon(
                          onPressed: () => _openForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Produk'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: ctrl.products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = ctrl.products[index];
                          return ProductTile(
                            product: product,
                            onTap: () => _openForm(context, product: product),
                            trailing: PopupMenuButton(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _openForm(context, product: product);
                                } else if (val == 'delete') {
                                  _confirmDelete(context, product.id, product.name);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_product',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormView(product: product),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductController>().deleteProduct(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
