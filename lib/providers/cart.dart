import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;

  CartItem({
    @required this.id,
    @required this.title,
    @required this.quantity,
    @required this.price,
  });
}

class Cart with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, prod) => total += (prod.price * prod.quantity));
    return total;
  }

  void addItem(String productId, String title, double price) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (oldItem) => CartItem(
          id: oldItem.id,
          title: oldItem.title,
          price: oldItem.price,
          quantity: oldItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          title: title,
          price: price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  int get itemCount {
    return _items.length;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (items[productId].quantity > 1) {
      _items.update(
          productId,
          (oldItem) => CartItem(
                id: oldItem.id,
                title: oldItem.title,
                quantity: oldItem.quantity - 1,
                price: oldItem.price,
              ));
    } else {
      _items.remove(productId);
    }
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
}
