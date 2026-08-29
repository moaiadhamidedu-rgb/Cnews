import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mpcurrencytracker/data/remote/news_service.dart';

void main() {
  test('combines Al Jazeera economy and ECB news with images', () async {
    final client = MockClient((request) async {
      return switch (request.url.toString()) {
        'https://www.aljazeera.net/ebusiness/' => http.Response(
          '''
          <article>
            <a class="article-card__link" href="/ebusiness/2026/8/29/markets">
              <h2 class="article-card__title">الأسواق تتحرك اليوم</h2>
            </a>
            <div class="date-simple"><span aria-hidden="true">29/8/2026</span></div>
            <img class="article-card__image" src="/images/markets.jpg" />
          </article>
          ''',
          200,
          headers: const {'content-type': 'text/html; charset=utf-8'},
        ),
        'https://www.aljazeera.net/ebusiness/2026/8/29/markets' =>
          http.Response(
            '''
            <meta property="og:description" content="تفاصيل حركة الأسواق" />
            <meta property="og:image" content="/images/markets-large.jpg" />
            ''',
            200,
            headers: const {'content-type': 'text/html; charset=utf-8'},
          ),
        'https://www.ecb.europa.eu/rss/press.html' => http.Response('''
          <rss><channel><item>
            <title>ECB market update</title>
            <link>https://www.ecb.europa.eu/press/update.html</link>
            <pubDate>Fri, 28 Aug 2026 12:30:00 GMT</pubDate>
          </item></channel></rss>
          ''', 200),
        'https://www.ecb.europa.eu/press/update.html' => http.Response('''
          <meta name="description" content="Latest central bank update" />
          <meta property="og:image" content="/press/update.jpg" />
          ''', 200),
        _ => http.Response('Not found', 404),
      };
    });

    final news = await NewsService(client: client).fetchLatestNews();

    expect(news, hasLength(2));
    expect(news.first['source_name'], 'الجزيرة اقتصاد');
    expect(news.first['desc_ar'], 'تفاصيل حركة الأسواق');
    expect(
      news.first['image_url'],
      'https://www.aljazeera.net/images/markets-large.jpg',
    );
    expect(news.last['source_name'], 'European Central Bank');
    expect(
      news.last['image_url'],
      'https://www.ecb.europa.eu/press/update.jpg',
    );
  });
}
