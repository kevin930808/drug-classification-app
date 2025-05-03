import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'package:camera/camera.dart';

// 全局变量存储相机列表
List<CameraDescription> cameras = [];

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置应用只能竖屏显示
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 初始化相機
  cameras = await availableCameras();
  
  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // 初始化 StorageService
  final storageService = StorageService(prefs);
  
  // 运行应用
  runApp(MyApp(storageService: storageService));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '藥物提醒',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // 禁用可能导致着色器问题的水波纹效果
        splashFactory: NoSplash.splashFactory,
        // 禁用高光效果
        highlightColor: Colors.transparent,
        // 添加其他主题配置
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _status = '正在初始化...';
  late final StorageService _storageService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // 立即显示初始状态
      if (mounted) {
        setState(() {
          _progress = 0.1;
          _status = '正在初始化...';
        });
      }
      
      // 更新状态 - 初始化存储服务
      _updateProgress(0.2, '初始化存儲服務...');
      _storageService = StorageService(await SharedPreferences.getInstance());
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟加载时间
      
      // 更新状态 - 检查相机权限
      _updateProgress(0.4, '檢查相機權限...');
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟加载时间
      
      // 更新状态 - 初始化相机
      _updateProgress(0.6, '初始化相機...');
      try {
        cameras = await availableCameras();
      } catch (e) {
        _updateProgress(0.6, '無法獲取相機: $e');
        await Future.delayed(const Duration(seconds: 1));
      }
      
      // 更新状态 - 加载用户数据
      _updateProgress(0.8, '載入用戶數據...');
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟加载时间
      
      // 更新状态 - 完成
      _updateProgress(1.0, '準備就緒！');
      await Future.delayed(const Duration(milliseconds: 500)); // 短暂延迟
      
      // 加载完成，导航到主页
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(storageService: _storageService),
          ),
        );
      }
    } catch (e) {
      // 处理错误
      _updateProgress(0.0, '初始化失敗: $e', isError: true);
      
      // 显示重试按钮
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _updateProgress(double progress, String message, {bool isError = false}) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _status = message;
      });
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 应用标志和名称 - 即使动画未完成也显示
            Opacity(  // 使用固定的不透明度而不是动画
              opacity: 1.0,
              child: Icon(
                Icons.medication_outlined,
                size: 120,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '藥物辨識助手',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '幫助您識別藥物並獲取用藥資訊',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            // 加载状态和进度条
            if (_isLoading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    // 加载信息
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 进度条
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.blue,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 10),
                    // 显示进度百分比
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 如果加载失败，显示重试按钮
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _initializeApp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('重新嘗試'),
              ),
            ],
            const Spacer(),
            // 底部版本信息
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'v1.0.0 © 2023 藥物辨識系統',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 