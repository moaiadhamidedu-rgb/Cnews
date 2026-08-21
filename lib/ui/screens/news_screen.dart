import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Logic/news_provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final newsLogic = Provider.of<NewsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'المركز الإخباري الاقتصادي' : 'Financial News Center'),
        centerTitle: true,
      ),
      body: newsLogic.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: newsLogic.loadNews,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: newsLogic.newsList.length,
              itemBuilder: (context, index) {
                final item = newsLogic.newsList[index];
                final isExpanded = newsLogic.expandedIndex == index;
                
                final title = isArabic ? item['title_ar'] : item['title_en'];
                final desc = isArabic ? item['desc_ar'] : item['desc_en'];
                final tag = isArabic ? item['tag_ar'] : item['tag_en'];

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
                      )
                    ],
                    border: Border.all(
                      color: isExpanded 
                          ? theme.colorScheme.primary.withValues(alpha: 0.3) 
                          : theme.colorScheme.outline.withValues(alpha: 0.05),
                      width: isExpanded ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => newsLogic.toggleExpansion(index),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
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
                              Text(item['date'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              height: 1.3,
                              color: theme.colorScheme.primary, // Distinct Title Color
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            desc,
                            maxLines: isExpanded ? 100 : 2,
                            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isExpanded ? Colors.grey.shade800 : Colors.grey.shade600, // Distinct Text Color
                              fontSize: 14, 
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                isExpanded 
                                    ? (isArabic ? 'إغلاق التفاصيل' : 'Close Details')
                                    : (isArabic ? 'عرض التفاصيل' : 'View Details'),
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Icon(
                                isExpanded 
                                    ? Icons.keyboard_arrow_up_rounded 
                                    : (isArabic ? Icons.keyboard_arrow_left_rounded : Icons.keyboard_arrow_right_rounded), 
                                size: 20,
                                color: theme.colorScheme.secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}
