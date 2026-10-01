import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/db_helper.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  List<Product> _products = [];

  List<CartItem> get items => _items;
  List<Product> get products => _products;

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // List Produk Bawaan
  final List<Product> _defaultProducts = [
    Product(
      id: 1, 
      name: 'Kopi Susu Gula Aren', 
      price: 22000, 
      imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 2, 
      name: 'Matcha Green Tea Latte', 
      price: 28000, 
      imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 3, 
      name: 'Iced Americano Single Origin', 
      price: 20000, 
      imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 4, 
      name: 'Chocolate Lava Latte', 
      price: 25000, 
      imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
    ),
    Product(
      id: 5, 
      name: 'Butter Croissant Premium', 
      price: 23000, 
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  // Fetch Produk
  Future<void> fetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('master_products');

    if (savedData != null && savedData.isNotEmpty) {
      final List list = jsonDecode(savedData);
      _products = list.map((e) => Product.fromMap(e)).toList();
    } else {
      if (!kIsWeb) {
        try {
          final db = await DBHelper.database;
          final data = await db.query('master_products');
          if (data.isNotEmpty) {
            _products = data.map((e) => Product.fromMap(e)).toList();
          } else {
            _products = List.from(_defaultProducts);
          }
        } catch (e) {
          _products = List.from(_defaultProducts);
        }
      } else {
        _products = List.from(_defaultProducts);
      }
      _saveProductsToStorage();
    }
    notifyListeners();
  }

  Future<void> _saveProductsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _products.map((p) => p.toMap()).toList();
    await prefs.setString('master_products', jsonEncode(data));
  }

  // Tambah Produk Baru
  Future<void> addProduct(String name, double price, String imageUrl) async {
    final newId = DateTime.now().millisecondsSinceEpoch;
    
    String finalUrl = imageUrl.trim();
    if (finalUrl.isEmpty) {
      finalUrl = 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80';
    } else if (kIsWeb && !finalUrl.startsWith('https://corsproxy.io/?') && !finalUrl.startsWith('data:')) {
      finalUrl = 'https://corsproxy.io/?${Uri.encodeComponent(finalUrl)}';
    }

    final newProduct = Product(
      id: newId,
      name: name,
      price: price,
      imageUrl: finalUrl,
    );

    _products.add(newProduct);
    await _saveProductsToStorage();

    if (!kIsWeb) {
      try {
        final db = await DBHelper.database;
        await db.insert('master_products', newProduct.toMap());
      } catch (e) {
        // Ignored
      }
    }

    notifyListeners();
  }

  // EDIT PRODUK (Metode ini yang memperbaiki error)
  Future<void> editProduct(int id, String name, double price, String imageUrl) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      String finalUrl = imageUrl.trim();
      if (finalUrl.isEmpty) {
        finalUrl = _products[index].imageUrl;
      } else if (kIsWeb && !finalUrl.startsWith('https://corsproxy.io/?') && !finalUrl.startsWith('data:')) {
        finalUrl = 'https://corsproxy.io/?${Uri.encodeComponent(finalUrl)}';
      }

      _products[index] = Product(
        id: id,
        name: name,
        price: price,
        imageUrl: finalUrl,
      );

      await _saveProductsToStorage();

      if (!kIsWeb) {
        try {
          final db = await DBHelper.database;
          await db.update(
            'master_products',
            _products[index].toMap(),
            where: 'id = ?',
            whereArgs: [id],
          );
        } catch (e) {
          // Ignored
        }
      }

      notifyListeners();
    }
  }

  // Hapus Produk
  Future<void> deleteProduct(int productId) async {
    _products.removeWhere((p) => p.id == productId);
    await _saveProductsToStorage();

    if (!kIsWeb) {
      try {
        final db = await DBHelper.database;
        await db.delete('master_products', where: 'id = ?', whereArgs: [productId]);
      } catch (e) {
        // Ignored
      }
    }

    notifyListeners();
  }

  // Fetch Keranjang
  Future<void> fetchCart() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCart = prefs.getString('local_cart');

    if (savedCart != null && savedCart.isNotEmpty) {
      final List list = jsonDecode(savedCart);
      _items = list.map((e) => CartItem.fromMap(e)).toList();
    } else if (!kIsWeb) {
      try {
        final db = await DBHelper.database;
        final data = await db.query('local_cart');
        _items = data.map((e) => CartItem.fromMap(e)).toList();
      } catch (e) {
        // Ignored
      }
    }
    notifyListeners();
  }

  Future<void> _saveCartToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((item) => item.toMap()).toList();
    await prefs.setString('local_cart', jsonEncode(data));
  }

  Future<void> addToCart(Product product) async {
    final index = _items.indexWhere((e) => e.productId == product.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: 1,
      ));
    }

    await _saveCartToStorage();

    if (!kIsWeb) {
      try {
        final db = await DBHelper.database;
        if (index != -1) {
          await db.update('local_cart', {'quantity': _items[index].quantity}, where: 'id = ?', whereArgs: [_items[index].id]);
        } else {
          await db.insert('local_cart', _items.last.toMap());
        }
      } catch (e) {
        // Ignored
      }
    }

    notifyListeners();
  }

  Future<void> updateQuantity(int cartId, int quantity) async {
    if (quantity <= 0) {
      _items.removeWhere((item) => item.id == cartId);
    } else {
      final index = _items.indexWhere((item) => item.id == cartId);
      if (index != -1) {
        _items[index].quantity = quantity;
      }
    }

    await _saveCartToStorage();

    if (!kIsWeb) {
      try {
        final db = await DBHelper.database;
        if (quantity <= 0) {
          await db.delete('local_cart', where: 'id = ?', whereArgs: [cartId]);
        } else {
          await db.update('local_cart', {'quantity': quantity}, where: 'id = ?', whereArgs: [cartId]);
        }
      } catch (e) {
        // Ignored
      }
    }

    notifyListeners();
  }
}