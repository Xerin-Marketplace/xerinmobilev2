import 'package:flutter/material.dart';

import '../theme/country_data.dart';
import '../theme/uicons.dart';

class CountryPickerField extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onSelected;
  final ColorScheme? colorScheme;

  const CountryPickerField({
    super.key,
    required this.selectedCountry,
    required this.onSelected,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = colorScheme ?? Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showCountryPicker(context),
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedCountry.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              selectedCountry.dialCode,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Uicons.angleDown, size: 16, color: scheme.primary),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _CountryPickerSheet(
          selectedCountry: selectedCountry,
          onSelected: (country) {
            Navigator.of(ctx).pop();
            onSelected(country);
          },
        );
      },
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onSelected;

  const _CountryPickerSheet({
    required this.selectedCountry,
    required this.onSelected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Country> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = CountryData.countries;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = CountryData.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: height * 0.75,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select Country',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search country or dial code...',
                  prefixIcon: const Icon(Uicons.search, size: 20),
                  filled: true,
                  fillColor: scheme.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (ctx, index) {
                  final country = _filtered[index];
                  final isSelected =
                      country.isoCode == widget.selectedCountry.isoCode;
                  return ListTile(
                    leading: Text(country.flag,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? scheme.primary
                            : scheme.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.dialCode,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Uicons.checkCircle,
                              size: 18, color: scheme.primary),
                        ],
                      ],
                    ),
                    onTap: () => widget.onSelected(country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
