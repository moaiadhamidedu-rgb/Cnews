import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../Logic/news_provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Widget _buildSentimentBadge(int sentiment, bool isArabic) {
    IconData icon;
    Color color;
    String label;

    if (sentiment == 1) {
      icon = Icons.trending_up_rounded;
      color = Colors.green;
      label = isArabic ? 'إيجابي' : 'Positive';
    } else if (sentiment == -1) {
      icon = Icons.trending_down_rounded;
      color = Colors.red;
      label = isArabic ? 'سلبي' : 'Negative';
    } else {
      icon = Icons.trending_flat_rounded;
      color = Colors.orange;
      label = isArabic ? 'محايد' : 'Neutral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareNews(
    Map<String, dynamic> item,
    String title,
    bool isArabic,
  ) {
    final url = item['source_url']?.toString() ?? '';
    return SharePlus.instance.share(
      ShareParams(
        text: '$title${url.isEmpty ? '' : '\n$url'}',
        subject: isArabic ? 'خبر اقتصادي' : 'Economic news',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final newsLogic = Provider.of<NewsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'المركز الإخباري الاقتصادي' : 'Financial News Center',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: newsLogic.isLoading ? null : newsLogic.loadNews,
            tooltip: isArabic ? 'تحديث الأخبار' : 'Refresh news',
          ),
        ],
      ),
      body: newsLogic.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: newsLogic.loadNews,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount:
                    newsLogic.newsList.length +
                    (newsLogic.errorMessage == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (newsLogic.errorMessage != null && index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? newsLogic.errorMessage!
                                  : 'Could not refresh news. Showing the latest saved copy.',
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final newsIndex =
                      index - (newsLogic.errorMessage == null ? 0 : 1);
                  final item = newsLogic.newsList[newsIndex];
                  final isExpanded = newsLogic.expandedIndex == newsIndex;

                  final title =
                      (isArabic ? item['title_ar'] : item['title_en'])
                          ?.toString() ??
                      '';
                  final rawDescription =
                      (isArabic ? item['desc_ar'] : item['desc_en'])
                          ?.toString() ??
                      '';
                  final desc = rawDescription.isEmpty
                      ? (isArabic
                            ? 'اضغط لقراءة الخبر من المصدر.'
                            : 'Open the original source for full details.')
                      : rawDescription;
                  final tag =
                      (isArabic ? item['tag_ar'] : item['tag_en'])
                          ?.toString() ??
                      '';
                  final sourceName = item['source_name']?.toString() ?? '';
                  final imageUrl = item['image_url']?.toString() ?? '';

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: isExpanded
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.outline.withValues(alpha: 0.05),
                        width: isExpanded ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => newsLogic.toggleExpansion(newsIndex),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NewsImage(imageUrl: imageUrl, tag: tag),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildSentimentBadge(
                                          newsLogic.analyzeSentiment(
                                            title + desc,
                                          ),
                                          isArabic,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      item['date']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                if (sourceName.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.public_rounded,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${isArabic ? "المصدر" : "Source"}: $sourceName',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  desc,
                                  maxLines: isExpanded ? 100 : 2,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isExpanded
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade600,
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: isArabic
                                          ? 'مشاركة الخبر'
                                          : 'Share news',
                                      onPressed: () =>
                                          _shareNews(item, title, isArabic),
                                      icon: const Icon(Icons.ios_share_rounded),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          isExpanded
                                              ? (isArabic
                                                    ? 'إغلاق التفاصيل'
                                                    : 'Close Details')
                                              : (isArabic
                                                    ? 'عرض التفاصيل'
                                                    : 'View Details'),
                                          style: TextStyle(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : (isArabic
                                                    ? Icons
                                                          .keyboard_arrow_left_rounded
                                                    : Icons
                                                          .keyboard_arrow_right_rounded),
                                          size: 20,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _NewsImage extends StatelessWidget {
  const _NewsImage({required this.imageUrl, required this.tag});

  final String imageUrl;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.analytics_rounded,
          size: 54,
          color: theme.colorScheme.primary,
        ),
      ),
    );
    if (imageUrl.isEmpty) return fallback;
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2.5),
              ),
      ),
    );
  }
}
