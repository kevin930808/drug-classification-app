import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/medicine.dart';

class ApiService {
  static const String baseUrl = 'https://api.imgbb.com/1/upload';
  static const String apiKey = 'df5b39833a7c5fcd28a7f78f9ce481d0';

  Future<Map<String, dynamic>?> identifyMedicine(File imageFile) async {
    try {
      print('開始處理藥物圖片...');
      
      // 保存圖片到本地
      final String localImagePath = await _saveImageLocally(imageFile);
      print('圖片已保存到本地: $localImagePath');

      // 上傳圖片到服務器（如果有網絡）
      String? remoteImageUrl;
      try {
        remoteImageUrl = await _uploadImageToServer(imageFile);
        print('圖片已上傳到服務器: $remoteImageUrl');
      } catch (e) {
        print('上傳到服務器失敗，將使用本地圖片: $e');
      }

      // 模擬 API 響應
      await Future.delayed(const Duration(seconds: 2));
      
      return {
        'name': '普拿疼',
        'clinicalUse': '退燒止痛',
        'usage': '每次1-2錠，每4-6小時一次',
        'sideEffects': '可能出現噁心、嘔吐等症狀',
        'precautions': '請勿超過每日最大劑量8錠，若有肝腎功能異常者請諮詢醫師',
      };
    } catch (e, stackTrace) {
      print('發生錯誤: $e');
      print('錯誤堆疊: $stackTrace');
      throw Exception('處理藥物圖片時發生錯誤: $e');
    }
  }

  Future<String> _saveImageLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'medicine_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('保存圖片到本地時發生錯誤: $e');
      throw Exception('無法保存圖片到本地');
    }
  }

  Future<String?> _uploadImageToServer(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl?key=$apiKey'),
      );

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: 'medicine_image.jpg',
          ),
        );
      } else {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        request.files.add(
          http.MultipartFile(
            'image',
            stream,
            length,
            filename: 'medicine_image.jpg',
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'].containsKey('url')) {
          return jsonResponse['data']['url'];
        }
      }
      return null;
    } catch (e) {
      print('上傳圖片到服務器時發生錯誤: $e');
      return null;
    }
  }
} 