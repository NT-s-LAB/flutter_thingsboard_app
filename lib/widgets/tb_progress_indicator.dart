import 'dart:math';
import 'package:flutter/material.dart';

/// Một widget spinner hiện đại, vẽ một cung tròn "thở" và xoay trên một vòng tròn nền.
/// Hiệu ứng được thiết kế để mượt mà và tinh tế.
///
/// LƯU Ý: Vì đây là một StatefulWidget có animation, bạn không thể khởi tạo nó
/// với từ khóa `const`. Hãy đảm bảo xóa `const` ở những nơi bạn sử dụng widget này.
class TbProgressIndicator extends StatefulWidget {
  const TbProgressIndicator({
    super.key,
    this.size = 36.0,
    this.color,
    this.strokeWidth = 3.5, // Tăng nhẹ độ dày cho nét vẽ rõ ràng hơn
  });

  /// Kích thước (chiều rộng và chiều cao) của spinner.
  final double size;

  /// Màu của spinner. Nếu không được cung cấp, nó sẽ dùng màu `primaryColor` của theme.
  final Color? color;

  /// Độ dày của nét vẽ cung tròn.
  final double strokeWidth;

  @override
  State<TbProgressIndicator> createState() => _TbProgressIndicatorState();
}

class _TbProgressIndicatorState extends State<TbProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweepAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // Giảm thời gian để animation nhanh và dứt khoát hơn
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Hoạt ảnh điều khiển độ dài của cung tròn ("thở").
    // Sử dụng đường cong `easeInOutSine` để chuyển động cực kỳ mượt mà.
    _sweepAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: pi * 1.6)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: pi * 1.6, end: 0.2)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50.0,
      ),
    ]).animate(_controller);

    // Hoạt ảnh điều khiển sự xoay tròn của cung.
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color spinnerColor = widget.color ?? Theme.of(context).primaryColor;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        // AnimatedBuilder sẽ lắng nghe controller và vẽ lại mỗi khi giá trị animation thay đổi.
        // Bằng cách này, chúng ta không cần dùng đến RotationTransition.
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ModernArcPainter(
                startAngle: _rotationAnimation.value,
                sweepAngle: _sweepAnimation.value,
                color: spinnerColor,
                strokeWidth: widget.strokeWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lớp CustomPainter được thiết kế lại để vẽ cả vòng tròn nền và cung tròn chuyển động.
class _ModernArcPainter extends CustomPainter {
  const _ModernArcPainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    required this.strokeWidth,
  });

  final double startAngle;
  final double sweepAngle;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Vẽ vòng tròn nền mờ.
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2) // Màu nhạt hơn
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 2. Vẽ cung tròn chính đang chuyển động.
    final foregroundPaint = Paint()
      ..color = color // Màu đầy đủ
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Bo tròn hai đầu

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle - (pi / 2), sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernArcPainter oldDelegate) {
    // Vẽ lại mỗi khi có sự thay đổi về góc hoặc màu sắc.
    return oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.color != color;
  }
}

