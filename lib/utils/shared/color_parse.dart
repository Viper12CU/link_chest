import 'dart:ui';

class ColorParse {
  Color toColor(String colorString) {
    final color = Color(
      int.parse(colorString.replaceFirst('#', ''), radix: 16),
    );
    return color;
  }



  String toColorString(Color color) {
    final colorStr = '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
    return colorStr;
  }
}
