import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // IMPORTANT: we'll explain this URL choice below
  static const String baseUrl = "https://medifind-backend-jhzx.onrender.com";

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phone,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> createRequest(
    String customerId,
    String category,
    String itemText,
    double longitude,
    double latitude,
    String? imageUrl,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requests/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'category': category,
        'itemText': itemText,
        'location': {
          'coordinates': [longitude, latitude],
        },
        if (imageUrl != null) 'itemImageUrl': imageUrl,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> getResponsesForRequest(
    String requestId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/responses/request/$requestId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> selectShop(
    String requestId,
    String shopId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/requests/$requestId/select'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'shopId': shopId}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> getChatMessages(String requestId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chats/request/$requestId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String requestId,
    String senderId,
    String senderRole,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestId': requestId,
        'senderId': senderId,
        'senderRole': senderRole,
        'message': message,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> getMyRequests(String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/requests/customer/$customerId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': 'Failed to load requests'};
    }
  }

  static Future<Map<String, dynamic>> getRequestsForShop(String shopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/requests/for-shop/$shopId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> acceptRequest(
    String requestId,
    String shopId,
    String? priceInfo,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/responses/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestId': requestId,
        'shopId': shopId,
        if (priceInfo != null && priceInfo.isNotEmpty) 'priceInfo': priceInfo,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> getShopByOwner(String ownerId) async {
    final response = await http.get(Uri.parse('$baseUrl/shops/owner/$ownerId'));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> registerShop(
    String ownerId,
    String shopName,
    String category,
    String address,
    double longitude,
    double latitude,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shops/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ownerId': ownerId,
        'shopName': shopName,
        'category': category,
        'address': address,
        'location': {
          'coordinates': [longitude, latitude],
        },
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> toggleShopOpen(String shopId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/shops/$shopId/toggle-open'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> blockCustomer(
    String shopId,
    String customerId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/shops/$shopId/block'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> submitRating(
    String requestId,
    String shopId,
    String customerId,
    int ratingValue,
    String? comment,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ratings/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestId': requestId,
        'shopId': shopId,
        'customerId': customerId,
        'ratingValue': ratingValue,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> getPeakHours() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/peak-hours'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': 'Failed to load'};
    }
  }

  static Future<Map<String, dynamic>> getDemandTrend() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/demand-trend'),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': 'Failed to load'};
    }
  }

  static Future<void> saveFcmToken(String userId, String fcmToken) async {
    await http.patch(
      Uri.parse('$baseUrl/users/$userId/fcm-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fcmToken': fcmToken}),
    );
  }
}
