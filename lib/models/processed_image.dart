import 'dart:convert';

class ProcessedImage {
  final String id;
  final String data;
  final int timestamp;

  ProcessedImage({
    required this.id,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'timestamp': timestamp,
    };
  }

  factory ProcessedImage.fromJson(Map<String, dynamic> json) {
    return ProcessedImage(
      id: json['id'],
      data: json['data'],
      timestamp: json['timestamp'],
    );
  }
}