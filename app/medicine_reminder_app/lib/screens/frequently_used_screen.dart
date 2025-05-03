import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import 'medicine_detail_screen.dart';

class FrequentlyUsedScreen extends StatefulWidget {
  final StorageService storageService;

  const FrequentlyUsedScreen({super.key, required this.storageService});

  @override
  State<FrequentlyUsedScreen> createState() => _FrequentlyUsedScreenState();
}

class _FrequentlyUsedScreenState extends State<FrequentlyUsedScreen> {
  List<Medicine> _frequentlyUsedMedicines = [];

  @override
  void initState() {
    super.initState();
    _loadFrequentlyUsedMedicines();
  }

  Future<void> _loadFrequentlyUsedMedicines() async {
    final medicines = await widget.storageService.getFrequentlyUsedMedicines();
    setState(() {
      _frequentlyUsedMedicines = medicines;
    });
  }

  Future<void> _removeMedicine(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('移除常用藥物'),
          content: const Text('確定要將此藥物從常用清單中移除嗎？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('確定'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.storageService.removeFromFrequentlyUsed(medicine);
      await _loadFrequentlyUsedMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('常用藥物'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _frequentlyUsedMedicines.isEmpty
                ? const Center(
                    child: Text(
                      '暫無常用藥物',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _frequentlyUsedMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _frequentlyUsedMedicines[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicineDetailScreen(
                                  medicine: medicine,
                                  storageService: widget.storageService,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 左側圖片
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: medicine.localImagePath != null
                                        ? Image.file(
                                            File(medicine.localImagePath!),
                                            fit: BoxFit.cover,
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.medication,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // 右側資訊
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              medicine.name,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => _removeMedicine(medicine),
                                            tooltip: '從常用藥物中移除',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '主要功效：${medicine.clinicalUse ?? '測試'}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '使用方法：${medicine.usage}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('返回'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 