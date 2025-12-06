import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Laravel API returns: { success, message, data: { user, access_token, token_type } }
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final token = data['access_token'];

          // Save token
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);
          }

          return {
            'success': true,
            'message': responseData['message'] ?? 'Login berhasil',
            'data': data,
          };
        }

        return {'success': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String namaUsaha,
    required String nomorTelepon,
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Attempting to register to: $baseUrl/register');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nama_lengkap': namaLengkap,
              'nama_usaha': namaUsaha,
              'nomor_telepon': nomorTelepon,
              'email': email,
              'password': password,
              'password_confirmation': password,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Pastikan Laravel server running di http://localhost:8000',
              );
            },
          );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Laravel API returns: { success, message, data: { user, access_token, token_type } }
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final token = data['access_token'];

          // Save token
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);
          }

          return {
            'success': true,
            'message': responseData['message'] ?? 'Registrasi berhasil',
            'data': data,
          };
        }

        return {'success': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Register gagal: ${response.body}',
        };
      }
    } catch (e) {
      print('🔴 Register error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get current user data
  Future<Map<String, dynamic>> getUser() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData['data'] ?? responseData};
      } else {
        return {'success': false, 'message': 'Failed to get user data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String namaLengkap,
    required String namaUsaha,
    required String nomorTelepon,
    String? imagePath,
    List<int>? imageBytes, // Add imageBytes parameter for web
    String? imageFileName,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final uri = Uri.parse('$baseUrl/user/update');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['nama_lengkap'] = namaLengkap;
      request.fields['nama_usaha'] = namaUsaha;
      request.fields['nomor_telepon'] = nomorTelepon;

      // Handle image upload
      if (imageBytes != null && imageFileName != null) {
        // For web: use bytes directly
        print('📤 Uploading image from bytes: $imageFileName');
        final multipartFile = http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: imageFileName,
        );
        request.files.add(multipartFile);
      } else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
        // For mobile: read file from path
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            print('📤 Uploading image from file: $imagePath');
            final multipartFile = http.MultipartFile.fromBytes(
              'photo',
              bytes,
              filename: imagePath.split('/').last,
            );
            request.files.add(multipartFile);
          } else {
            print('⚠️ File does not exist: $imagePath');
          }
        } catch (e) {
          print('⚠️ Error reading image file: $e');
          return {'success': false, 'message': 'Failed to read image file: $e'};
        }
      }

      print('📤 Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData['data']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('❌ Error in updateProfile: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get all transactions
  Future<List<Transaction>> getTransactions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> transactionsJson = data['data'] ?? data;
        return transactionsJson
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Search transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/search?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> transactionsJson = data['data'] ?? data;
        return transactionsJson
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to search transactions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Add transaction
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: headers,
        body: jsonEncode(transaction.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to add transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update transaction
  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/${transaction.id}'),
        headers: headers,
        body: jsonEncode({
          'title': transaction.title,
          'type': transaction.type,
          'category': transaction.category,
          'amount': transaction.amount,
          'date_time': transaction.dateTime.toIso8601String(),
          'notes': transaction.notes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data['data']);
      } else {
        throw Exception('Failed to update transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get transaction by ID
  Future<Transaction> getTransaction(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to load transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ========== PRODUCT METHODS ==========

  // Get all products
  Future<List<Product>> getProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsJson = data['data'] as List;
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Add product
  Future<Product> addProduct(Product product) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: headers,
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to add product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(String id, Product product) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get product by ID
  Future<Product> getProduct(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Reset all transactions
  Future<void> resetTransactions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/reset'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset transactions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Import transactions
  Future<Map<String, dynamic>> importTransactions(
    List<Transaction> transactions,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/import'),
        headers: headers,
        body: jsonEncode({
          'transactions': transactions.map((t) => t.toJson()).toList(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Import failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
