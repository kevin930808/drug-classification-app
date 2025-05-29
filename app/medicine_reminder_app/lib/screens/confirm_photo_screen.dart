import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

class ConfirmPhotoScreen extends StatelessWidget {
  final XFile photoFile;

  const ConfirmPhotoScreen({super.key, required this.photoFile});

  Future<File> _processImage() async {
    // 讀取原始圖片
    final File originalFile = File(photoFile.path);
    final Uint8List imageBytes = await originalFile.readAsBytes();
    
    // 解碼圖片
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return originalFile;
    
    // 創建新的圖片文件
    final String newPath = '${originalFile.parent.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File newFile = File(newPath);
    
    // 保存處理後的圖片
    await newFile.writeAsBytes(img.encodeJpg(originalImage, quality: 100));
    
    return newFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('確認照片'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 警語區域
          Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade300, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '請確認以下事項',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 藥物是否清晰可見\n• 藥物是否擺放正確\n• 光線是否充足',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.5,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          // 照片預覽
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 4/5,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: FutureBuilder<File>(
                      future: _processImage(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('載入圖片失敗: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: Text('無法載入圖片'));
                        }
                        return Image.file(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 按鈕區域
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('重新拍攝'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('確認傳送'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 