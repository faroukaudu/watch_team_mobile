import 'package:flutter/material.dart';

class PostOrder {
  final String id;
  final String title;
  final String? status;
  final DateTime? createdAt;

  PostOrder({required this.id, required this.title, this.status, this.createdAt});

  factory PostOrder.fromJson(Map<String, dynamic> json) {
    return PostOrder(
      id: json["_id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "Untitled",
      status: json["status"]?.toString(),
      createdAt: json["createdAt"] != null ? DateTime.tryParse(json["createdAt"]) : null,
    );
  }
}
