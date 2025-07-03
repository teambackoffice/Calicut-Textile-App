import 'dart:ui';

import 'package:flutter/material.dart';

class ColorsResponse {
  final bool success;
  final List<String> data;

  ColorsResponse({
    required this.success,
    required this.data,
  });

  factory ColorsResponse.fromJson(Map<String, dynamic> json) {
    return ColorsResponse(
      success: json['message']['success'] ?? false,
      data: List<String>.from(json['message']['data'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': {
        'success': success,
        'data': data,
      }
    };
  }
}

// models/color_item.dart
class ColorItem {
  final String name;
  final String displayName;
  final Color? color;

  ColorItem({
    required this.name,
    required this.displayName,
    this.color,
  });

  factory ColorItem.fromName(String name) {
    return ColorItem(
      name: name,
      displayName: name,
     
    );
  }

  // static Color? _getColorFromName(String colorName) {
  //   switch (colorName.toLowerCase()) {
  //     case 'red':
  //       return Colors.red;
  //     case 'green':
  //       return Colors.green;
  //     case 'blue':
  //       return Colors.blue;
  //     case 'black':
  //       return Colors.black;
  //     case 'white':
  //       return Colors.white;
  //     case 'meroon':
  //       return Color(0xFF800000);
  //     case 'pink':
  //       return Colors.pink;
  //     case 'purple':
  //       return Colors.purple;
  //     case 'yellow':
  //       return Colors.yellow;
  //     case 'grey':
  //       return Colors.grey;
  //     case 'beige':
  //       return Color(0xFFF5F5DC);
  //     case 'brown':
  //       return Colors.brown;
  //     case 'gold':
  //       return Color(0xFFFFD700);
  //     case 'rose gold':
  //       return Color(0xFFE8B4A0);
  //     case 'silver':
  //       return Color(0xFFC0C0C0);
  //     case 'l green':
  //       return Colors.lightGreen;
  //     case 'r blue':
  //       return Colors.blue[600];
  //     case 'navy blue':
  //       return Color(0xFF000080);
  //     case 'orange':
  //       return Colors.orange;
  //     case 'copper':
  //       return Color(0xFFB87333);
  //     case 'peacock blue':
  //       return Color(0xFF005F69);
  //     case 'violet':
  //       return Color(0xFF8A2BE2);
  //     case 'bottle green':
  //       return Color(0xFF006A4E);
  //     case 'magenta':
  //       return Colors;
  //     case 'aqua blue':
  //       return Color(0xFF00FFFF);
  //     default:
  //       return null;
  //   }
  // }
}
