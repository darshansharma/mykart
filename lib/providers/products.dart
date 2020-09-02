import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './product.dart';
import '../models/http_exception.dart';
import 'dart:convert';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favouriteItems {
    return items.where((prod) => prod.isFavourite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((product) => product.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    String filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url =
        'https://mykart-fddb0.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      var resp = await http.get(url);
      final extractedData = json.decode(resp.body) as Map<String, dynamic>;
      List<Product> loadedProducts = [];
      if (extractedData == null) {
        return;
      }
      url =
          'https://mykart-fddb0.firebaseio.com/userFavourites/$userId.json?auth=$authToken';
      final favouriteProductsResponse = await http.get(url);
      final favData = json.decode(favouriteProductsResponse.body);
      extractedData.forEach((prodId, product) {
        loadedProducts.add(Product(
          id: prodId,
          title: product['title'],
          description: product['description'],
          price: product['price'],
          imageUrl: product['imageUrl'],
          isFavourite: favData == null ? false : favData[prodId] ?? false,
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      print(error);
      throw (error);
    }
  }

  Future<void> addProduct(Product product) {
    var url =
        'https://mykart-fddb0.firebaseio.com/products.json?auth=$authToken';
    return http
        .post(url,
            body: json.encode({
              'title': product.title,
              'description': product.description,
              'price': product.price,
              'imageUrl': product.imageUrl,
              'creatorId': userId,
            }))
        .then((response) {
      var newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _items.add(newProduct);
      notifyListeners();
    }).catchError((error) {
      throw (error);
    });
  }

  Future<void> updateProduct(String productId, Product product) async {
    var index = _items.indexWhere((prod) => prod.id == productId);
    final url =
        'https://mykart-fddb0.firebaseio.com/products/$productId.json?auth=$authToken';
    if (index >= 0) {
      await http.patch(url,
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl
          }));
      _items[index] = product;
      notifyListeners();
    } else {
      print('Can not updated product. Existing product not found');
    }
  }

  Future<void> removeProduct(String id) async {
    final url =
        'https://mykart-fddb0.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);
    var existingProduct = _items[existingProductIndex];
    final response = await http.delete(url);
    _items.removeAt(existingProductIndex);
    notifyListeners();
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Unable to delete product!!');
    }
    existingProduct = null;
  }
}
