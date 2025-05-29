import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/medicine.dart';
import 'medicine_detail_screen.dart';
import 'history_screen.dart';
import 'confirm_photo_screen.dart';
import 'frequently_used_screen.dart';
import '../main.dart' show cameras;
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;
  bool _hasInternet = true;
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _flashAnimationController;
  late Animation<double> _flashOpacityAnimation;
  late AnimationController _rotationAnimationController;
  late Animation<double> _rotationAnimation;
  bool _showGuideline = true;  // 控制警語顯示

  // 定義全局狀態文本變量
  String _statusMessage = '準備就緒，請將藥物放置在框內';
  bool _isError = false;

  // 更新狀態文本的方法
  void _updateStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isError = isError;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkConnectivity();
    _setupConnectivityListener();
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _flashOpacityAnimation = Tween<double>(begin: 0.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _flashAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.linear,
      ),
    );
    
    // 5秒後自動隱藏警語
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showGuideline = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isCameraInitialized && cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有可用的相機')),
      );
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (cameras.isEmpty) {
        return;
      }

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,  // 使用高解析度預設值
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController.initialize();
      
      // 優化相機設定
      await _cameraController.setFocusMode(FocusMode.auto);
      await _cameraController.setExposureMode(ExposureMode.auto);
      await _cameraController.setFlashMode(FlashMode.auto);
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('相機初始化失敗: $e')),
        );
      }
    }
  }

  // 模擬藥物數據
  Medicine _getMockMedicine() {
    return Medicine(
      name: '普拿疼',
      clinicalUse: '退燒止痛',
      usage: '每次1-2錠，每4-6小時一次',
      sideEffects: '可能出現噁心、嘔吐等症狀',
      precautions: '請勿超過每日最大劑量8錠，若有肝腎功能異常者請諮詢醫師',
      timestamp: DateTime.now(),
    );
  }

  Future<String> _saveImageToLocal(XFile imageFile) async {
    final String fileName = 'medicine_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String localPath = '${(await getApplicationDocumentsDirectory()).path}/$fileName';
    await File(imageFile.path).copy(localPath);
    return localPath;
  }

  Future<void> _processImage(XFile imageFile) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 保存图片到本地
      final String localPath = await _saveImageToLocal(imageFile);
      
      // 调用API识别药品
      final Map<String, dynamic>? response = await _apiService.identifyMedicine(File(imageFile.path));
      
      if (response != null) {
        final medicine = Medicine(
          name: response['name'] as String? ?? '未知藥品',
          clinicalUse: response['clinicalUse'] as String? ?? '未知',
          usage: response['usage'] as String? ?? '未知',
          sideEffects: response['sideEffects'] as String? ?? '未知',
          precautions: response['precautions'] as String? ?? '未知',
          localImagePath: localPath,
          timestamp: DateTime.now(),
        );

        // 添加到历史记录
        await widget.storageService.addToHistory(medicine);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailScreen(
                medicine: medicine,
                storageService: widget.storageService,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('識別失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) {
      _updateStatus('相機未準備好', isError: true);
      return;
    }
    
    // 添加觸覺反饋
    HapticFeedback.mediumImpact();
    
    // 立即更新狀態
    _updateStatus('拍攝中...');
    
    try {
      // 閃光效果
      _flashAnimationController.forward().then((_) {
        _flashAnimationController.reverse();
      });
      
      setState(() {
        _isLoading = true;
      });
      
      // 開始旋轉動畫
      _rotationAnimationController.repeat();
      
      // 捕獲圖像
      final XFile photo = await _cameraController.takePicture();
      
      if (mounted) {
        // 停止旋轉動畫
        _rotationAnimationController.stop();
        
        setState(() {
          _isLoading = false;
        });
        
        // 導航到確認頁面
        final bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmPhotoScreen(photoFile: photo),
          ),
        );
        
        if (result == true) {
          await _processImage(photo);
        } else {
          _updateStatus('已取消，請重新拍攝');
        }
        
        _updateStatus('準備就緒，請將藥物放置在框內');
      }
    } catch (e) {
      _rotationAnimationController.stop();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _updateStatus('拍照失敗: $e', isError: true);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.mediumImpact();
    
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
    
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bool? result = await Navigator.push<bool>(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) {
              return FadeTransition(
                opacity: animation,
                child: ConfirmPhotoScreen(photoFile: image),
              );
            },
          ),
        );
        
        if (result == true) {
          await _processImage(image);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選擇照片失敗: $e')),
        );
      }
    }
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(storageService: widget.storageService),
      ),
    );
  }

  void _showFrequentlyUsed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FrequentlyUsedScreen(storageService: widget.storageService),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 4/5,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController.value.previewSize!.height,
                  height: _cameraController.value.previewSize!.width,
                  child: CameraPreview(
                    _cameraController,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) => _onViewFinderTap(details, constraints),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_cameraController.value.isInitialized) {
      final CameraController cameraController = _cameraController;
      final Offset offset = Offset(
        details.localPosition.dx / constraints.maxWidth,
        details.localPosition.dy / constraints.maxHeight,
      );
      cameraController.setExposurePoint(offset);
      cameraController.setFocusPoint(offset);
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      setState(() {
        _hasInternet = result != ConnectivityResult.none;
      });
      if (!_hasInternet && mounted) {
        _showNoInternetDialog();
      }
    } catch (e) {
      print('連線檢查錯誤: $e');
    }
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _hasInternet = result != ConnectivityResult.none;
      });
      if (!_hasInternet && mounted) {
        _showNoInternetDialog();
      }
    });
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('網路連線提醒'),
          content: const Text('請確保設備已連接網路，以便進行藥物辨識。離線狀態下仍可查看歷史紀錄。'),
          actions: <Widget>[
            TextButton(
              child: const Text('確定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _flashAnimationController.dispose();
    _rotationAnimationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('藥物辨識系統'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 頂部狀態提示區域
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  color: _isError ? Colors.red.shade100 : Colors.blue.shade100,
                  child: Row(
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.info_outline,
                        color: _isError ? Colors.red : Colors.blue,
                        size: 28,  // 放大圖示
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 18,  // 放大字體
                            fontWeight: FontWeight.bold,
                            color: _isError ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 調整預覽框大小
                AspectRatio(
                  aspectRatio: 4/5,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildCameraPreview(),
                          // 在預覽框頂部添加警語
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              color: Colors.red.withOpacity(0.7),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                        size: 24,  // 放大圖示
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '拍攝提醒',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,  // 放大字體
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '請將單顆藥品放置框內，刻字面朝上',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,  // 放大字體
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 添加閃光效果層
                          AnimatedBuilder(
                            animation: _flashOpacityAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _flashOpacityAnimation.value,
                                child: Container(
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),  // 減少上方間距
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _buttonScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _captureImage,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(15),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _isLoading ? '識別中...' : '點擊拍照',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: ElevatedButton.icon(
                                onPressed: _pickFromGallery,
                                icon: const Icon(Icons.photo_library, size: 24),
                                label: const Text(
                                  '相簿',
                                  style: TextStyle(fontSize: 20),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: ElevatedButton.icon(
                                onPressed: _showHistory,
                                icon: const Icon(Icons.history, size: 24),
                                label: const Text(
                                  '歷史',
                                  style: TextStyle(fontSize: 20),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: ElevatedButton.icon(
                                onPressed: _showFrequentlyUsed,
                                icon: const Icon(Icons.star, size: 24),
                                label: const Text(
                                  '常用',
                                  style: TextStyle(fontSize: 20),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            // 使用完全覆蓋的遮罩，確保用戶看不到預覽框的變化
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: const CircularProgressIndicator(
                                  color: Colors.blue,
                                  strokeWidth: 3,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 