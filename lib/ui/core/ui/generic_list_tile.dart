import 'package:flutter/material.dart';

class GenericChipTile<T> extends StatelessWidget {
  final T value;

  /// A function that takes a value of type T and returns its display label (e.g., emoji).
  final String Function(T value) labelGetter;

  /// A function that takes a value of type T and returns its display name (used if title is null).
  final String Function(T value) nameGetter;

  /// The color to use when this tile is selected.
  final Color selectedColor;

  /// An optional custom title widget. If null, nameGetter(value) will be used.
  final Widget? titleWidget;

  /// Called when the user selects this tile.
  final ValueChanged<T> onChanged;

  /// The padding inside the tile.
  final EdgeInsetsGeometry padding;

  /// The border radius of the tile.
  final double borderRadius;

  /// Whether this tile is currently selected.
  final bool isSelected;

  const GenericChipTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.labelGetter,
    required this.nameGetter,
    required this.selectedColor,
    required this.isSelected,
    this.titleWidget,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ), // Adjusted padding
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor =
        isSelected ? selectedColor : Theme.of(context).colorScheme.onSurface;
    final effectiveBackgroundColor =
        isSelected ? selectedColor.withValues(alpha: .25) : Colors.transparent;

    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      onTap: () => onChanged(value), // Pass the actual value of type T
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          border: Border.all(color: effectiveLabelColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Important for chip-like behavior
          children: [
            Text(
              labelGetter(value), // Use the getter for the label
              style: TextStyle(
                color: effectiveLabelColor,
                fontWeight: FontWeight.bold,
                fontSize:
                    Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .fontSize, // You might want to make this configurable too
              ),
            ),
            const SizedBox(width: 8), // Spacing between label and title
            titleWidget ??
                Text(
                  nameGetter(value), // Use the getter for the name/title
                  style: TextStyle(
                    color: effectiveLabelColor,
                    fontSize:
                        Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .fontSize, // You might want to make this configurable too
                    // Consider if title should also be bold or have different styling
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
