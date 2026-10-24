import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

/// 带标题的内容卡片。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MiuixCard(
        insideMargin: EdgeInsets.zero,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: MiuixText(
                          title!,
                          style: MiuixTheme.of(context).textStyles.subtitle,
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 圆角图标底座。
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final MiuixColors c = MiuixTheme.of(context).colors;
    final Color base = color ?? c.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.42),
      ),
      child: MiuixIcon(icon: icon, size: iconSize, tint: base),
    );
  }
}

/// 小型状态标签。
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            MiuixIcon(icon: icon!, size: 13, tint: color),
            const SizedBox(width: 4),
          ],
          MiuixText(
            label,
            fontSize: 12,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// 滑杆行：标题 + 数值 + 滑块。
class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.suffix = '',
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final MiuixTextStyles t = MiuixTheme.of(context).textStyles;
    final MiuixColors c = MiuixTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: MiuixText(title, style: t.body1)),
            MiuixText(
              '${value.round()}$suffix',
              style: t.body2,
              color: c.onSurfaceVariantSummary,
            ),
          ],
        ),
        const SizedBox(height: 2),
        MiuixSlider(
          value: value,
          min: min,
          max: max,
          onValueChanged: onChanged,
          onValueChangeFinished: onChangeEnd == null
              ? null
              : () => onChangeEnd!(value),
        ),
      ],
    );
  }
}
