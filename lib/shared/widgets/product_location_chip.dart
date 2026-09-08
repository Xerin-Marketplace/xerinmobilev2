import 'package:flutter/material.dart';

class ProductLocationChip extends StatelessWidget {
  final String? location;
  final String? country;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;

  const ProductLocationChip({
    super.key,
    this.location,
    this.country,
    this.fontSize = 10,
    this.iconSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  });

  String? get _countryName {
    final c = country ?? location;
    if (c == null || c.isEmpty) return null;
    return c;
  }

  String get _flagEmoji {
    final c = _countryName?.toLowerCase() ?? '';
    if (c.contains('tanzania')) return '🇹🇿';
    if (c.contains('kenya')) return '🇰🇪';
    if (c.contains('uganda')) return '🇺🇬';
    if (c.contains('rwanda')) return '🇷🇼';
    if (c.contains('china')) return '🇨🇳';
    if (c.contains('dubai') || c.contains('uae') || c.contains('emirates')) return '🇦🇪';
    if (c.contains('turkey') || c.contains('türkiye')) return '🇹🇷';
    if (c.contains('nigeria')) return '🇳🇬';
    if (c.contains('ghana')) return '🇬🇭';
    if (c.contains('south africa')) return '🇿🇦';
    if (c.contains('india')) return '🇮🇳';
    if (c.contains('usa') || c.contains('united states')) return '🇺🇸';
    if (c.contains('uk') || c.contains('united kingdom')) return '🇬🇧';
    return '🌍';
  }

  String? get _regionText {
    if (location == null || location!.isEmpty) return null;
    final parts = location!.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final countryName = _countryName;
    final region = _regionText;

    if (countryName == null && region == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (countryName != null) ...[
            Text(_flagEmoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                countryName,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (countryName != null && region != null) ...[
            Text(
              ' · ',
              style: TextStyle(
                fontSize: fontSize,
                color: cs.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ],
          if (region != null) ...[
            Flexible(
              child: Text(
                'Region: $region',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
