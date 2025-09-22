import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TideCell extends StatelessWidget {
  final Map<String, dynamic> tide;
  final DateFormat tf;

  const TideCell({super.key, required this.tide, required this.tf});

  @override
  Widget build(BuildContext context) {
    final type = tide['type'];
    final time = tf.format(DateTime.parse(tide['time']));
    final height = tide['height']?.toStringAsFixed(2) ?? "";

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            "$type $time",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (height.isNotEmpty)
            Text("$height m", style: const TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }
}
