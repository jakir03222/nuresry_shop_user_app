import 'package:flutter/foundation.dart';

class FavoriteProvider with ChangeNotifier {
  final List<String> _favoriteIds = [];

  List<String> get favoriteIds => _favoriteIds;
  
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  void toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
  }

  void addToFavorites(String productId) {
    if (!_favoriteIds.contains(productId)) {
      _favoriteIds.add(productId);
      notifyListeners();
    }
  }

  void removeFromFavorites(String productId) {
    _favoriteIds.remove(productId);
    notifyListeners();
  }

  void clearFavorites() {
    _favoriteIds.clear();
    notifyListeners();
  }
}
