import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'dart:io';
import '../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;
  final StorageService storageService;

  const MedicineDetailScreen({
    super.key,
    required this.medicine,
    required this.storageService,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  bool _isFrequentlyUsed = false;

  @override
  void initState() {
    super.initState();
    _checkFrequentlyUsedStatus();
  }

  Future<void> _checkFrequentlyUsedStatus() async {
    final isFrequentlyUsed = await widget.storageService.isFrequentlyUsed(widget.medicine);
    if (mounted) {
      setState(() {
        _isFrequentlyUsed = isFrequentlyUsed;
      });
    }
  }

  Future<void> _toggleFrequentlyUsed() async {
    if (_isFrequentlyUsed) {
      await widget.storageService.removeFromFrequentlyUsed(widget.medicine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已從常用藥物中移除'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 0, top: 20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await widget.storageService.addToFrequentlyUsed(widget.medicine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已添加到常用藥物'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 0, top: 20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    _checkFrequentlyUsedStatus();
  }

  Widget _buildClinicalInfo(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, {
    IconData? icon,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('藥物資訊'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _isFrequentlyUsed ? Icons.star : Icons.star_border,
              color: _isFrequentlyUsed ? Colors.amber : Colors.white,
              size: 32,
            ),
            onPressed: _toggleFrequentlyUsed,
            tooltip: _isFrequentlyUsed ? '從常用藥物中移除' : '增加到常用藥物',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 上半部分：圖片和臨床資訊的行布局
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左側藥物圖片
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: widget.medicine.localImagePath != null && File(widget.medicine.localImagePath!).existsSync()
                                ? Image.file(
                                    File(widget.medicine.localImagePath!),
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    colorBlendMode: BlendMode.srcOver,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 60,
                                          color: Colors.red,
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.medication,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 右側臨床資訊
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildClinicalInfo('主要功效', 
                              widget.medicine.clinicalUse ?? '測試',
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildClinicalInfo('可能副作用', 
                              widget.medicine.sideEffects ?? '測試',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 下半部分：其他藥物資訊
                  _buildInfoSection('藥物名稱', widget.medicine.name),
                  _buildInfoSection('使用方法', widget.medicine.usage, 
                    icon: Icons.access_time,
                    backgroundColor: Colors.blue.shade50,
                  ),
                  _buildInfoSection('注意事項', widget.medicine.precautions,
                    icon: Icons.warning_amber,
                    backgroundColor: Colors.orange.shade50,
                  ),
                ],
              ),
            ),
          ),
          // 底部按鈕
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleFrequentlyUsed,
                    icon: Icon(
                      _isFrequentlyUsed ? Icons.star : Icons.star_border,
                      size: 24,
                    ),
                    label: Text(
                      _isFrequentlyUsed ? '從常用藥物中移除' : '增加到常用藥物',
                      style: const TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: _isFrequentlyUsed ? Colors.orange : Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已回報藥物資訊錯誤'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(bottom: 0, top: 20),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Future.delayed(
                        const Duration(seconds: 2),
                        () => Navigator.of(context).popUntil((route) => route.isFirst),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: const Text('回報資訊錯誤'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: const Text('返回拍照'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 