class ProcessedImage {
  final String id;
  final String data;
  final int timestamp;
  final String name;

  ProcessedImage({
    required this.id,
    required this.data,
    required this.timestamp,
    required this.name,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'timestamp': timestamp,
      'name': name,
    };
  }

  // Create from JSON
  factory ProcessedImage.fromJson(Map<String, dynamic> json) {
    return ProcessedImage(
      id: json['id'],
      data: json['data'],
      timestamp: json['timestamp'],
      name: json['name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessedImage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}