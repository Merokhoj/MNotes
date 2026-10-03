import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

/// Modal dialog for inserting customizable tables with interactive grid selection
/// and manual Row / Column counter steppers.
class InsertTableDialog extends StatefulWidget {
  const InsertTableDialog({super.key});

  static Future<({int rows, int cols})?> show(BuildContext context) {
    return showDialog<({int rows, int cols})>(
      context: context,
      builder: (ctx) => const InsertTableDialog(),
    );
  }

  @override
  State<InsertTableDialog> createState() => _InsertTableDialogState();
}

class _InsertTableDialogState extends State<InsertTableDialog> {
  int _rows = 3;
  int _cols = 3;
  int _hoverRows = 0;
  int _hoverCols = 0;

  static const int _maxGridCols = 8;
  static const int _maxGridRows = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border.withOpacity(0.4)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(PhosphorIcons.table(PhosphorIconsStyle.bold),
                      color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Insert Table',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive Visual Grid Selector (up to 8x8)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surface2.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: colors.border.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      _hoverRows > 0 && _hoverCols > 0
                          ? '$_hoverCols Columns × $_hoverRows Rows'
                          : '$_cols Columns × $_rows Rows',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int r = 1; r <= _maxGridRows; r++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int c = 1; c <= _maxGridCols; c++) ...[
                              MouseRegion(
                                onEnter: (_) => setState(() {
                                  _hoverRows = r;
                                  _hoverCols = c;
                                }),
                                onExit: (_) => setState(() {
                                  _hoverRows = 0;
                                  _hoverCols = 0;
                                }),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _rows = r;
                                      _cols = c;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(3),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                    decoration: BoxDecoration(
                                      color: (_hoverRows >= r && _hoverCols >= c) ||
                                              (_hoverRows == 0 && _rows >= r && _cols >= c)
                                          ? colors.primary.withOpacity(0.35)
                                          : colors.surface,
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: (_hoverRows >= r && _hoverCols >= c) ||
                                                (_hoverRows == 0 && _rows >= r && _cols >= c)
                                            ? colors.primary
                                            : colors.border.withOpacity(0.6),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Manual Numeric Steppers for Custom Dimensions
              Row(
                children: [
                  Expanded(
                    child: _buildDimensionStepper(
                      label: 'Columns',
                      value: _cols,
                      minValue: 1,
                      maxValue: 20,
                      onChanged: (val) => setState(() => _cols = val),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDimensionStepper(
                      label: 'Rows',
                      value: _rows,
                      minValue: 1,
                      maxValue: 50,
                      onChanged: (val) => setState(() => _rows = val),
                      colors: colors,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop((rows: _rows, cols: _cols));
                    },
                    icon: const Icon(Icons.table_chart_rounded, size: 16),
                    label: const Text('Insert Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionStepper({
    required String label,
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
    required dynamic colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: colors.surface2.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: colors.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: value > minValue ? () => onChanged(value - 1) : null,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppSpacing.radiusSm)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.remove_rounded,
                      size: 14, color: value > minValue ? colors.textPrimary : colors.textTertiary),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: value < maxValue ? () => onChanged(value + 1) : null,
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(AppSpacing.radiusSm)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.add_rounded,
                      size: 14, color: value < maxValue ? colors.textPrimary : colors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
