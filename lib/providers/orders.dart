import 'package:flutter/foundation.dart';
import './cart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime date;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.date,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];

  Future<void> fetchAndSetOrders() async {
    const url = 'https://mykart-fddb0.firebaseio.com/orders.json';
    final response = await http.get(url);
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    final List<OrderItem> loadedOrders = [];
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(
        OrderItem(
          id: orderId,
          amount: orderData['amount'],
          products: (orderData['products'] as List<dynamic>)
              .map(
                (cartItem) => CartItem(
                  id: cartItem['id'],
                  title: cartItem['title'],
                  quantity: cartItem['quantity'],
                  price: cartItem['price'],
                ),
              )
              .toList(),
          date: DateTime.parse(orderData['date']),
        ),
      );
    });
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> products, double total) async {
    var timeStamp = DateTime.now();
    const url = 'https://mykart-fddb0.firebaseio.com/orders.json';
    final response = await http.post(
      url,
      body: json.encode({
        'date': timeStamp.toIso8601String(),
        'products': products
            .map((cartItem) => {
                  'id': cartItem.id,
                  'title': cartItem.title,
                  'quantity': cartItem.quantity,
                  'price': cartItem.price,
                })
            .toList(),
        'amount': total,
      }),
    );
    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        products: products,
        date: timeStamp,
      ),
    );
    notifyListeners();
  }

  List<OrderItem> get orders {
    return [..._orders];
  }
}