import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

class StorageService {
  final SharedPreferences _prefs;
  static const String _historyKey = 'medicine_history';
  static const String _frequentlyUsedKey = 'frequently_used_medicines';

  StorageService(this._prefs);

  Future<void> addToHistory(Medicine medicine) async {
    final List<String> history = _prefs.getStringList(_historyKey) ?? [];
    final String medicineJson = json.encode(medicine.toJson());
    
    // 檢查是否已存在相同時間戳的記錄
    if (!history.any((item) => isSameMedicine(json.decode(item), medicine))) {
      history.add(medicineJson);
      await _prefs.setStringList(_historyKey, history);
    }
  }

  Future<List<Medicine>> getHistory() async {
    final List<String> history = _prefs.getStringList(_historyKey) ?? [];
    return history
        .map((item) => Medicine.fromJson(json.decode(item)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> removeFromHistory(Medicine medicine) async {
    final List<String> history = _prefs.getStringList(_historyKey) ?? [];
    history.removeWhere((item) => isSameMedicine(json.decode(item), medicine));
    await _prefs.setStringList(_historyKey, history);
  }

  bool isSameMedicine(Map<String, dynamic> itemJson, Medicine medicine) {
    return itemJson['timestamp'] == medicine.timestamp?.toIso8601String();
  }

  Future<void> addToFrequentlyUsed(Medicine medicine) async {
    final List<String> frequentlyUsed = _prefs.getStringList(_frequentlyUsedKey) ?? [];
    final String medicineJson = json.encode(medicine.toJson());
    
    if (!frequentlyUsed.any((item) => isSameMedicine(json.decode(item), medicine))) {
      frequentlyUsed.add(medicineJson);
      await _prefs.setStringList(_frequentlyUsedKey, frequentlyUsed);
    }
  }

  Future<List<Medicine>> getFrequentlyUsedMedicines() async {
    final List<String> frequentlyUsed = _prefs.getStringList(_frequentlyUsedKey) ?? [];
    return frequentlyUsed
        .map((item) => Medicine.fromJson(json.decode(item)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> removeFromFrequentlyUsed(Medicine medicine) async {
    final List<String> frequentlyUsed = _prefs.getStringList(_frequentlyUsedKey) ?? [];
    frequentlyUsed.removeWhere((item) => isSameMedicine(json.decode(item), medicine));
    await _prefs.setStringList(_frequentlyUsedKey, frequentlyUsed);
  }

  Future<bool> isFrequentlyUsed(Medicine medicine) async {
    final List<String> frequentlyUsed = _prefs.getStringList(_frequentlyUsedKey) ?? [];
    return frequentlyUsed.any((item) => isSameMedicine(json.decode(item), medicine));
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<void> clearFrequentlyUsed() async {
    await _prefs.remove(_frequentlyUsedKey);
  }
} 