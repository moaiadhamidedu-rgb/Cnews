import 'dart:async';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

abstract interface class NewsApi {
  Future<List<Map<String, dynamic>>> fetchLatestNews();
}

class NewsService implements NewsApi {
  NewsService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _alJazeeraEconomy = Uri.parse(
    'https://www.aljazeera.net/ebusiness/',
  );
  static final Uri _ecbFeed = Uri.parse(
    'https://www.ecb.europa.eu/rss/press.html',
  );

  final http.Client _client;

  @override
  Future<List<Map<String, dynamic>>> fetchLatestNews() async {
    final results = await Future.wait([
      _fetchAlJazeera().catchError((_) => <Map<String, dynamic>>[]),
      _fetchEcb().catchError((_) => <Map<String, dynamic>>[]),
    ]);
    final combined = results.expand((items) => items).toList();
    combined.sort(
      (left, right) => (right['published_at']?.toString() ?? '').compareTo(
        left['published_at']?.toString() ?? '',
      ),
    );
    if (combined.isEmpty) {
      throw const NewsRequestException('No live news source was available');
    }
    return combined;
  }

  Future<List<Map<String, dynamic>>> _fetchAlJazeera() async {
    final response = await _get(_alJazeeraEconomy);
    final document = html_parser.parse(response.body);
    final cards = document
        .querySelectorAll('article')
        .where(
          (article) => article.querySelector('.article-card__title') != null,
        );

    final items = <Map<String, dynamic>>[];
    for (final card in cards) {
      final title = card.querySelector('.article-card__title')?.text.trim();
      final relativeUrl = card
          .querySelector('a.article-card__link')
          ?.attributes['href'];
      if (title == null || title.isEmpty || relativeUrl == null) continue;

      final articleUrl = _alJazeeraEconomy.resolve(relativeUrl);
      final relativeImage = card
          .querySelector('img.article-card__image')
          ?.attributes['src'];
      final dateText =
          card
              .querySelector('.date-simple [aria-hidden="true"]')
              ?.text
              .trim() ??
          '';
      items.add({
        'title_ar': title,
        'title_en': title,
        'desc_ar': '',
        'desc_en': '',
        'date': dateText,
        'tag_ar': 'اقتصاد',
        'tag_en': 'Economy',
        'source_name': 'الجزيرة اقتصاد',
        'source_url': articleUrl.toString(),
        'image_url': relativeImage == null
            ? null
            : _alJazeeraEconomy.resolve(relativeImage).toString(),
        'published_at': _parseArabicDate(dateText)?.toIso8601String() ?? '',
      });
      if (items.length == 7) break;
    }

    await Future.wait(
      items.map((item) async {
        final metadata = await _fetchPageMetadata(
          Uri.parse(item['source_url'] as String),
        );
        final description = metadata.description;
        if (description.isNotEmpty) {
          item['desc_ar'] = description;
          item['desc_en'] = description;
        }
        if (metadata.imageUrl.isNotEmpty) {
          item['image_url'] = metadata.imageUrl;
        }
      }),
    );
    return items;
  }

  Future<List<Map<String, dynamic>>> _fetchEcb() async {
    final response = await _get(_ecbFeed);
    final document = XmlDocument.parse(response.body);
    final feedItems = document.findAllElements('item').take(5);
    final items = <Map<String, dynamic>>[];

    for (final item in feedItems) {
      final title = item.getElement('title')?.innerText.trim() ?? '';
      final link = item.getElement('link')?.innerText.trim() ?? '';
      final pubDate = item.getElement('pubDate')?.innerText.trim() ?? '';
      if (title.isEmpty || link.isEmpty) continue;
      final articleUrl = Uri.parse(link);
      final metadata = await _fetchPageMetadata(articleUrl);
      final publishedAt = _parseRfcDate(pubDate);
      items.add({
        'title_ar': title,
        'title_en': title,
        'desc_ar': metadata.description,
        'desc_en': metadata.description,
        'date': publishedAt == null
            ? pubDate
            : '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}',
        'tag_ar': 'بنوك مركزية',
        'tag_en': 'Central Banks',
        'source_name': 'European Central Bank',
        'source_url': articleUrl.toString(),
        'image_url': metadata.imageUrl,
        'published_at': publishedAt?.toIso8601String() ?? '',
      });
    }
    return items;
  }

  Future<_PageMetadata> _fetchPageMetadata(Uri url) async {
    try {
      final response = await _get(url);
      final document = html_parser.parse(response.body);
      final description =
          document
              .querySelector('meta[property="og:description"]')
              ?.attributes['content']
              ?.trim() ??
          document
              .querySelector('meta[name="description"]')
              ?.attributes['content']
              ?.trim() ??
          '';
      final rawImage =
          document
              .querySelector('meta[property="og:image"]')
              ?.attributes['content']
              ?.trim() ??
          '';
      return _PageMetadata(
        description: description,
        imageUrl: rawImage.isEmpty ? '' : url.resolve(rawImage).toString(),
      );
    } catch (_) {
      return const _PageMetadata(description: '', imageUrl: '');
    }
  }

  Future<http.Response> _get(Uri url) async {
    final response = await _client
        .get(
          url,
          headers: const {
            'Accept': 'text/html,application/rss+xml,application/xml',
            'User-Agent': 'CNews/1.0 (economic news reader)',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NewsRequestException(
        'News source returned HTTP ${response.statusCode}',
      );
    }
    return response;
  }

  DateTime? _parseArabicDate(String value) {
    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    if (match == null) return null;
    return DateTime.utc(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  DateTime? _parseRfcDate(String value) {
    final match = RegExp(
      r'^[A-Za-z]{3},\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
      r'(\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(value);
    if (match == null) return null;
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final month = months[match.group(2)];
    if (month == null) return null;
    return DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }
}

class NewsRequestException implements Exception {
  const NewsRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _PageMetadata {
  const _PageMetadata({required this.description, required this.imageUrl});

  final String description;
  final String imageUrl;
}
