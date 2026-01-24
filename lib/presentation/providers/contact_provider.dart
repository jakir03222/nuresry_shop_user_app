import 'package:flutter/foundation.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/services/api_service.dart';

class ContactProvider with ChangeNotifier {
  final List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ContactModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getContacts();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        final list = data
            .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
            .where((c) => c.isActive)
            .toList();
        list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _contacts.clear();
        _contacts.addAll(list);
      } else {
        _errorMessage =
            response['message'] as String? ?? 'Failed to load contacts';
        _contacts.clear();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _contacts.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
