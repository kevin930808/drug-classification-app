class Medicine {
  final String name;
  final String clinicalUse;
  final String usage;
  final String sideEffects;
  final String precautions;
  String? _localImagePath;
  DateTime? _timestamp;

  Medicine({
    required this.name,
    required this.clinicalUse,
    required this.usage,
    required this.sideEffects,
    required this.precautions,
    String? localImagePath,
    DateTime? timestamp,
  }) : _localImagePath = localImagePath,
       _timestamp = timestamp;

  String? get localImagePath => _localImagePath;
  DateTime? get timestamp => _timestamp;

  set localImagePath(String? value) {
    _localImagePath = value;
  }

  set timestamp(DateTime? value) {
    _timestamp = value;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'clinicalUse': clinicalUse,
      'usage': usage,
      'sideEffects': sideEffects,
      'precautions': precautions,
      'localImagePath': _localImagePath,
      'timestamp': _timestamp?.toIso8601String(),
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'] ?? '',
      clinicalUse: json['clinicalUse'] ?? '',
      usage: json['usage'] ?? '',
      sideEffects: json['sideEffects'] ?? '',
      precautions: json['precautions'] ?? '',
      localImagePath: json['localImagePath'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }
} 