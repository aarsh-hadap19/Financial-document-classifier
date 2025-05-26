import 'package:flutter/material.dart';

class ClassificationChip extends StatelessWidget {
  final String? classification;
  final bool isProcessing;

  const ClassificationChip({
    super.key,
    this.classification,
    this.isProcessing = false,
  });

  Color _getClassificationColor(String classification, BuildContext context) {
    switch (classification.toLowerCase()) {
      case 'invoice':
        return Colors.orange;
      case 'receipt':
        return Colors.green;
      case 'bank statement':
        return Colors.blue;
      case 'tax document':
        return Colors.purple;
      case 'insurance document':
        return Colors.teal;
      case 'contract':
        return Colors.indigo;
      case 'financial report':
        return Colors.amber;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getClassificationIcon(String classification) {
    switch (classification.toLowerCase()) {
      case 'invoice':
        return Icons.receipt_long;
      case 'receipt':
        return Icons.receipt;
      case 'bank statement':
        return Icons.account_balance;
      case 'tax document':
        return Icons.gavel;
      case 'insurance document':
        return Icons.security;
      case 'contract':
        return Icons.description;
      case 'financial report':
        return Icons.bar_chart;
      default:
        return Icons.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Classifying...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (classification == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'Classification Failed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final color = _getClassificationColor(classification!, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getClassificationIcon(classification!),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            classification!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}