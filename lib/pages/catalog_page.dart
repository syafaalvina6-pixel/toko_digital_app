import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product_model.dart';
import 'cart_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<CartProvider>().fetchProducts();
        context.read<CartProvider>().fetchCart();
      }
    });
  }

  // Dialog Form Tambah / Edit Produk
  void _showProductFormDialog(BuildContext context, {Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: isEdit ? product.name : '');
    final priceController =
        TextEditingController(text: isEdit ? product.price.toInt().toString() : '');
    final urlController = TextEditingController(
        text: (isEdit && !product.imageUrl.startsWith('data:image'))
            ? product.imageUrl
            : '');
    String selectedImageBase64 =
        (isEdit && product.imageUrl.startsWith('data:image')) ? product.imageUrl : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL Gambar (Opsional)',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 600,
                        imageQuality: 70,
                      );

                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        final base64Image =
                            'data:image/jpeg;base64,${base64Encode(bytes)}';
                        setState(() {
                          selectedImageBase64 = base64Image;
                          urlController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih dari Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (selectedImageBase64.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('✓ Foto galeri terpilih',
                        style: TextStyle(color: Colors.green)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text) ?? 0;
                  final finalImage = selectedImageBase64.isNotEmpty
                      ? selectedImageBase64
                      : urlController.text.trim();

                  if (name.isNotEmpty && price > 0) {
                    final provider = context.read<CartProvider>();
                    if (isEdit) {
                      provider.editProduct(product.id, name, price, finalImage);
                    } else {
                      provider.addProduct(name, price, finalImage);
                    }
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog Konfirmasi Hapus Produk
  void _confirmDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CartProvider>().deleteProduct(product.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.local_cafe, size: 50, color: Colors.brown),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final products = cartProvider.products;

    final totalCartCount =
        cartProvider.items.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kopi & Kafe Shop'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CartPage()),
                  );
                },
              ),
              if (totalCartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$totalCartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: products.isEmpty
          ? const Center(
              child: Text('Belum ada produk',
                  style: TextStyle(color: Colors.grey)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                final product = products[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: _buildProductImage(product.imageUrl),
                          ),
                          // Tombol Edit & Hapus di Pojok Kanan Atas Gambar
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _showProductFormDialog(context,
                                        product: product),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(Icons.edit,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _confirmDeleteDialog(
                                        context, product),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(Icons.delete,
                                          color: Colors.redAccent, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${product.price.toInt()}',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  cartProvider.addToCart(product);
                                },
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 16),
                                label: const Text('Beli'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        onPressed: () => _showProductFormDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}