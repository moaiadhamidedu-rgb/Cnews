import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import '../../Logic/prediction_provider.dart';
import '../../data/models/usd_syp_prediction.dart';

class UsdSypPredictionCard extends StatelessWidget {
  const UsdSypPredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PredictionProvider>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: switch (provider.status) {
          PredictionStatus.initial ||
          PredictionStatus.loading => _LoadingState(isArabic: isArabic),
          PredictionStatus.error => _ErrorState(
            isArabic: isArabic,
            onRetry: provider.loadPrediction,
          ),
          PredictionStatus.success => _PredictionContent(
            prediction: provider.prediction!,
            isArabic: isArabic,
            onRefresh: provider.loadPrediction,
          ),
        },
      ),
    );
  }
}

class _PredictionContent extends StatelessWidget {
  const _PredictionContent({
    required this.prediction,
    required this.isArabic,
    required this.onRefresh,
  });

  final UsdSypPrediction prediction;
  final bool isArabic;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = _DirectionStyle.from(prediction.direction, isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.show_chart_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'اتجاه الدولار القادم' : 'Next USD outlook',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isArabic ? 'تحديث التوقع' : 'Refresh prediction',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.55,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _RateValue(
                  label: isArabic ? 'آخر سعر مسجل' : 'Latest recorded rate',
                  value: prediction.currentRate,
                  isArabic: isArabic,
                  emphasized: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: direction.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.ltr,
                        children: [
                          Icon(
                            direction.icon,
                            size: 17,
                            color: direction.color,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${prediction.changePercent.abs().toStringAsFixed(4)}%',
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: direction.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      direction.shortLabel,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: direction.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _RateValue(
                  label: isArabic ? 'السعر المتوقع' : 'Predicted rate',
                  value: prediction.predictedNextRate,
                  isArabic: isArabic,
                  emphasized: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(direction.icon, size: 20, color: direction.color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                direction.description(
                  prediction.change.abs(),
                  prediction.changePercent.abs(),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: direction.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _InfoItem(
              icon: Icons.calendar_today_outlined,
              text:
                  '${isArabic ? "آخر تحديث للبيانات" : "Latest data update"}: \u2066${DateFormat('yyyy-MM-dd').format(prediction.asOfDate)}\u2069',
            ),
          ],
        ),
      ],
    );
  }
}

class _RateValue extends StatelessWidget {
  const _RateValue({
    required this.label,
    required this.value,
    required this.isArabic,
    required this.emphasized,
  });

  final String label;
  final double value;
  final bool isArabic;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value.toStringAsFixed(2),
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: emphasized ? theme.colorScheme.primary : null,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isArabic ? 'ل.س جديدة لكل 1 دولار' : 'New SYP per 1 USD',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'جاري جلب توقع USD/SYP من الخادم...'
                  : 'Loading USD/SYP prediction from the server...',
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.isArabic, required this.onRetry});

  final bool isArabic;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.cloud_off_rounded, size: 38, color: theme.colorScheme.error),
        const SizedBox(height: 8),
        Text(
          isArabic
              ? 'لم نتمكن من جلب توقع USD/SYP من الخادم.'
              : 'We could not load the USD/SYP prediction from the server.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isArabic
              ? 'تحقق من الاتصال ثم حاول مرة أخرى.'
              : 'Check your connection and try again.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(isArabic ? 'إعادة المحاولة' : 'Try again'),
        ),
      ],
    );
  }
}

class _DirectionStyle {
  const _DirectionStyle({
    required this.icon,
    required this.color,
    required this.shortLabel,
    required this.isArabic,
    required this.direction,
  });

  final IconData icon;
  final Color color;
  final String shortLabel;
  final bool isArabic;
  final String direction;

  factory _DirectionStyle.from(String direction, bool isArabic) {
    return switch (direction) {
      'up' => _DirectionStyle(
        icon: Icons.trending_up_rounded,
        color: Colors.red.shade700,
        shortLabel: isArabic ? 'ارتفاع متوقع' : 'Expected increase',
        isArabic: isArabic,
        direction: direction,
      ),
      'down' => _DirectionStyle(
        icon: Icons.trending_down_rounded,
        color: Colors.green.shade700,
        shortLabel: isArabic ? 'انخفاض متوقع' : 'Expected decrease',
        isArabic: isArabic,
        direction: direction,
      ),
      _ => _DirectionStyle(
        icon: Icons.trending_flat_rounded,
        color: Colors.blueGrey.shade700,
        shortLabel: isArabic ? 'استقرار متوقع' : 'Expected stability',
        isArabic: isArabic,
        direction: direction,
      ),
    };
  }

  String description(double absoluteChange, double absolutePercent) {
    if (direction == 'unchanged') {
      return isArabic
          ? 'لا يتوقع النموذج تغيرًا ملحوظًا في الرصد القادم.'
          : 'The model expects no meaningful change in the next observation.';
    }
    final isUp = direction == 'up';
    if (isArabic) {
      final movement = isUp ? 'الارتفاع المتوقع' : 'الانخفاض المتوقع';
      return '$movement: ${absoluteChange.toStringAsFixed(2)} ل.س جديدة (${absolutePercent.toStringAsFixed(2)} بالمئة).';
    }
    final verb = isUp ? 'increase' : 'decrease';
    return 'Expected $verb of about ${absolutePercent.toStringAsFixed(2)}% (${absoluteChange.toStringAsFixed(2)} new SYP).';
  }
}
