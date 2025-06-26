import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/assets.dart';

/// Widget helper để hiển thị SVG assets
class SvgAsset extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final String? semanticsLabel;
  final bool allowDrawingOutsideViewBox;
  final Widget? placeholderBuilder;

  const SvgAsset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.semanticsLabel,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
  });

  /// Constructor cho Kienlongbank icon
  const SvgAsset.kienlongbankIcon({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.semanticsLabel,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
  }) : assetPath = AssetsLogos.kienlongbankIcon;

  /// Constructor cho Kienlongbank logo
  const SvgAsset.kienlongbankLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.semanticsLabel,
    this.allowDrawingOutsideViewBox = false,
    this.placeholderBuilder,
  }) : assetPath = AssetsLogos.kienlongbankLogo;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      semanticsLabel: semanticsLabel,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder != null
          ? (context) => placeholderBuilder!
          : null,
    );
  }
}

/// Extension để dễ dàng tạo SvgAsset từ string
extension SvgAssetString on String {
  /// Tạo SvgAsset từ asset path
  SvgAsset toSvgAsset({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    String? semanticsLabel,
  }) {
    return SvgAsset(
      this,
      width: width,
      height: height,
      fit: fit,
      color: color,
      semanticsLabel: semanticsLabel,
    );
  }

  /// Kiểm tra xem string có phải là SVG path không
  bool get isSvgPath => Assets.isSvgFile(this);
}

/// Helper methods cho SVG
class SvgHelper {
  SvgHelper._();

  /// Tạo SvgAsset với kích thước cố định
  static Widget icon(
    String assetPath, {
    double size = 24,
    Color? color,
  }) {
    return SvgAsset(
      assetPath,
      width: size,
      height: size,
      color: color,
    );
  }

  /// Tạo logo với kích thước responsive
  static Widget logo(
    String assetPath, {
    double? width,
    double? height,
    Color? color,
  }) {
    return SvgAsset(
      assetPath,
      width: width,
      height: height,
      color: color,
      fit: BoxFit.contain,
    );
  }

  /// Kienlongbank icon với kích thước cố định
  static Widget kienlongbankIcon({
    double size = 24,
    Color? color,
  }) {
    return SvgAsset.kienlongbankIcon(
      width: size,
      height: size,
      color: color,
    );
  }

  /// Kienlongbank logo với kích thước responsive
  static Widget kienlongbankLogo({
    double? width,
    double? height,
    Color? color,
  }) {
    return SvgAsset.kienlongbankLogo(
      width: width,
      height: height,
      color: color,
    );
  }
} 