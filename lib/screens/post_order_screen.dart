import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/post_order.dart';
import '../widgets/empty_state.dart';

class PostOrdersScreen extends StatefulWidget {
  const PostOrdersScreen({super.key});
  // const EmptyPostOrders({super.key});

  @override
  State<PostOrdersScreen> createState() => _PostOrdersScreenState();
}

class _PostOrdersScreenState extends State<PostOrdersScreen> {
  static const String BASE_URL = "http://YOUR_SERVER_IP:9000"; // change this

  late Future<List<PostOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchPostOrders();
  }

  Future<List<PostOrder>> fetchPostOrders() async {
    final uri = Uri.parse("$BASE_URL/post-orders");

    final res = await http.get(uri, headers: {
      "Content-Type": "application/json",
      // if you use auth token/cookie, include here
    });

    if (res.statusCode != 200) return [];

    final decoded = jsonDecode(res.body);
    final data = decoded["data"];

    if (data == null || data is! List) return [];

    return data.map<PostOrder>((e) => PostOrder.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C3EF3),
        title: const Text("Post Orders", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<PostOrder>>(
        future: _future,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Empty OR error
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const EmptyPostOrders();
          }

          // List
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = fetchPostOrders());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final o = orders[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F3A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              o.status ?? "Pending",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
