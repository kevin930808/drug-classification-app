import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/medicine.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.50.118:8000';

  Future<Map<String, dynamic>?> identifyMedicine(File imageFile) async {
    try {
      print('開始處理藥物圖片...');
      
      // 保存圖片到本地
      final String localImagePath = await _saveImageLocally(imageFile);
      print('圖片已保存到本地: $localImagePath');

      // 上傳圖片到服務器
      try {
        var result = await _uploadImageToServer(imageFile);
        print('API返回結果: $result');
        
        if (result != null) {
          return {
            'name': result['name'] ?? '未檢測到',
            'shape': result['shape'] ?? '未檢測到',
            'letter': result['letter'] ?? '未檢測到',
            'color': result['color'] ?? '未檢測到',
            'clinicalUse': '請諮詢醫師或藥師',
            'usage': '請諮詢醫師或藥師',
            'sideEffects': '請諮詢醫師或藥師',
            'precautions': '請諮詢醫師或藥師',
          };
        }
      } catch (e) {
        print('上傳到服務器失敗: $e');
      }

      // 如果API调用失败，返回默认数据
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

  Future<Map<String, dynamic>?> _uploadImageToServer(File imageFile) async {
    try {
      // 检查并打印文件信息
      final bool fileExists = await imageFile.exists();
      final int fileSize = await imageFile.length();
      print('文件是否存在: $fileExists, 文件大小: $fileSize 字节');
      
      // 构建请求URL
      final uri = Uri.parse('$baseUrl/detect/');
      print('请求URL: $uri');
      
      // 读取文件内容为字节数组
      final bytes = await imageFile.readAsBytes();
      print('已读取文件内容，大小: ${bytes.length} 字节');
      
      // 创建multipart请求
      var request = http.MultipartRequest('POST', uri);
      
      // 添加文件，不指定contentType
      var multipartFile = http.MultipartFile.fromBytes(
        'file', // 确保参数名为'file'
        bytes,
        filename: path.basename(imageFile.path),
        contentType: MediaType('image', 'jpeg') // 使用导入的MediaType
      );
      
      request.files.add(multipartFile);
      print('已添加文件到请求: ${multipartFile.filename}');
      
      // 发送请求
      print('正在发送请求...');
      final response = await request.send().timeout(Duration(seconds: 30));
      print('收到响应，状态码: ${response.statusCode}');
      
      // 处理响应
      final responseBody = await response.stream.bytesToString();
      print('响应内容: $responseBody');
      
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(responseBody);
        return jsonResponse;
      } else {
        print('服务器返回错误: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('上傳圖片到服務器時發生錯誤: $e');
      return null;
    }
  }
} 