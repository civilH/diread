import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/book.dart';
import '../../providers/reader_provider.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, reader, _) {
        final settings = reader.settings;
        final isPdf = reader.currentBook?.fileType == BookType.pdf;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  'Reading Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),

                // Theme - available for both PDF and EPUB
                _buildSection(
                  context,
                  'Background Theme',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReadingTheme.values.map((theme) {
                      return _buildThemeChip(
                        context,
                        theme,
                        settings.theme,
                        () => reader.updateTheme(theme),
                      );
                    }).toList(),
                  ),
                ),

                // Scroll Direction - available for both PDF and EPUB
                _buildSection(
                  context,
                  'Scroll Direction',
                  Row(
                    children: ScrollDirection.values.map((direction) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: direction != ScrollDirection.values.last ? 8 : 0,
                          ),
                          child: _buildScrollDirectionOption(
                            context,
                            direction,
                            settings.scrollDirection,
                            () => reader.updateScrollDirection(direction),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Font settings only for EPUB
                if (!isPdf) ...[
                  // Font Size
                  _buildSection(
                    context,
                    'Font Size',
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.text_decrease),
                          onPressed: settings.fontSize > AppConfig.minFontSize
                              ? () => reader.updateFontSize(settings.fontSize - 2)
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: settings.fontSize,
                            min: AppConfig.minFontSize,
                            max: AppConfig.maxFontSize,
                            divisions: 10,
                            label: '${settings.fontSize.toInt()}',
                            onChanged: (value) => reader.updateFontSize(value),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_increase),
                          onPressed: settings.fontSize < AppConfig.maxFontSize
                              ? () => reader.updateFontSize(settings.fontSize + 2)
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // Font Family
                  _buildSection(
                    context,
                    'Font Style',
                    Row(
                      children: [
                        _buildFontOption(
                          context,
                          'Default',
                          'default',
                          settings.fontFamily,
                          () => reader.updateFontFamily('default'),
                        ),
                        const SizedBox(width: 12),
                        _buildFontOption(
                          context,
                          'Serif',
                          'serif',
                          settings.fontFamily,
                          () => reader.updateFontFamily('serif'),
                          fontFamily: 'serif',
                        ),
                        const SizedBox(width: 12),
                        _buildFontOption(
                          context,
                          'Sans',
                          'sans-serif',
                          settings.fontFamily,
                          () => reader.updateFontFamily('sans-serif'),
                        ),
                      ],
                    ),
                  ),

                  // Line Height
                  _buildSection(
                    context,
                    'Line Spacing',
                    Row(
                      children: [
                        _buildSpacingOption(
                          context,
                          'Tight',
                          1.2,
                          settings.lineHeight,
                          () => reader.updateLineHeight(1.2),
                        ),
                        const SizedBox(width: 12),
                        _buildSpacingOption(
                          context,
                          'Normal',
                          1.6,
                          settings.lineHeight,
                          () => reader.updateLineHeight(1.6),
                        ),
                        const SizedBox(width: 12),
                        _buildSpacingOption(
                          context,
                          'Relaxed',
                          2.0,
                          settings.lineHeight,
                          () => reader.updateLineHeight(2.0),
                        ),
                      ],
                    ),
                  ),

                  // Margins
                  _buildSection(
                    context,
                    'Margins',
                    Row(
                      children: [
                        _buildMarginOption(
                          context,
                          'Small',
                          8,
                          settings.margin,
                          () => reader.updateMargin(8),
                        ),
                        const SizedBox(width: 12),
                        _buildMarginOption(
                          context,
                          'Medium',
                          16,
                          settings.margin,
                          () => reader.updateMargin(16),
                        ),
                        const SizedBox(width: 12),
                        _buildMarginOption(
                          context,
                          'Large',
                          24,
                          settings.margin,
                          () => reader.updateMargin(24),
                        ),
                      ],
                    ),
                  ),
                ],

                // Info text for PDF
                if (isPdf)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Note: Font settings are not available for PDF files as they preserve the original document formatting.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeChip(
    BuildContext context,
    ReadingTheme theme,
    ReadingTheme currentTheme,
    VoidCallback onTap,
  ) {
    final isSelected = theme == currentTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              theme.displayName,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollDirectionOption(
    BuildContext context,
    ScrollDirection direction,
    ScrollDirection currentDirection,
    VoidCallback onTap,
  ) {
    final isSelected = direction == currentDirection;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              direction.icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              direction.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFontOption(
    BuildContext context,
    String label,
    String value,
    String currentValue,
    VoidCallback onTap, {
    String? fontFamily,
  }) {
    final isSelected = value == currentValue;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpacingOption(
    BuildContext context,
    String label,
    double value,
    double currentValue,
    VoidCallback onTap,
  ) {
    final isSelected = (value - currentValue).abs() < 0.1;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.format_line_spacing,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarginOption(
    BuildContext context,
    String label,
    double value,
    double currentValue,
    VoidCallback onTap,
  ) {
    final isSelected = (value - currentValue).abs() < 1;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
