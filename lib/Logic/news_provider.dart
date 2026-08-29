import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/remote/news_service.dart';

class NewsProvider extends ChangeNotifier {
  NewsProvider({DatabaseHelper? database, NewsApi? newsApi})
    : _dbHelper = database ?? DatabaseHelper(),
      _newsApi = newsApi ?? NewsService();

  final DatabaseHelper _dbHelper;
  final NewsApi _newsApi;
  List<Map<String, dynamic>> _newsList = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _expandedIndex;

  List<Map<String, dynamic>> get newsList => _newsList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get expandedIndex => _expandedIndex;

  void toggleExpansion(int index) {
    if (_expandedIndex == index) {
      _expandedIndex = null;
    } else {
      _expandedIndex = index;
    }
    notifyListeners();
  }

  /// تحليل مشاعر الخبر بناءً على الكلمات المفتاحية
  /// Returns: 1 for Positive, -1 for Negative, 0 for Neutral
  int analyzeSentiment(String text) {
    final positiveWords = [
      'صعود',
      'ارتفاع',
      'نمو',
      'انتعاش',
      'دعم',
      'استقرار',
      'إيجابي',
      'نجاح',
      'تحسن',
      'records',
      'rise',
      'growth',
      'support',
      'stability',
      'positive',
      'success',
      'improvement',
    ];
    final negativeWords = [
      'هبوط',
      'انخفاض',
      'خسارة',
      'تراجع',
      'عقوبات',
      'انهيار',
      'سلبي',
      'تضخم',
      'تباطؤ',
      'drop',
      'fall',
      'loss',
      'decline',
      'sanctions',
      'collapse',
      'negative',
      'inflation',
      'slowdown',
    ];

    int score = 0;
    final lowerText = text.toLowerCase();

    for (var word in positiveWords) {
      if (lowerText.contains(word)) score++;
    }
    for (var word in negativeWords) {
      if (lowerText.contains(word)) score--;
    }

    if (score > 0) return 1;
    if (score < 0) return -1;
    return 0;
  }

  Future<void> loadNews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final liveNews = await _newsApi.fetchLatestNews();
      await _dbHelper.insertNews(liveNews);
    } catch (_) {
      _errorMessage = 'تعذر تحديث الأخبار، يتم عرض آخر نسخة محفوظة.';
    }

    var currentNews = await _dbHelper.queryAllNews();
    if (currentNews.isEmpty) {
      await _dbHelper.insertNews(_getInitialNews());
      currentNews = await _dbHelper.queryAllNews();
    }

    _newsList = currentNews;
    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _getInitialNews() {
    return [
      {
        'title_ar': 'البيتكوين يحطم الأرقام القياسية متجاوزاً 105,000 دولار',
        'title_en': 'Bitcoin Smashes Records, Surpassing \$105,000',
        'desc_ar':
            'واصلت العملة الرقمية الأولى في العالم رحلة الصعود الصاروخي وسط تفاؤل الأسواق بتشريعات أمريكية جديدة تدعم الأصول الرقمية، وزيادة استثمارات الشركات الكبرى في هذا المجال مما جعلها الملاذ الآمن الرقمي الأبرز عالمياً في الوقت الحالي.',
        'desc_en':
            'The world\'s leading cryptocurrency continued its meteoric rise amid market optimism over new US legislation supporting digital assets and increased institutional investment, making it the most prominent digital safe haven globally.',
        'date': 'منذ 15 دقيقة',
        'tag_ar': 'كريبتو',
        'tag_en': 'Crypto',
      },
      {
        'title_ar': 'البنك المركزي السوري يعلن عن إجراءات جديدة لضبط سوق الصرف',
        'title_en':
            'Central Bank of Syria Announces New Measures to Regulate Exchange Market',
        'desc_ar':
            'في خطوة تهدف لتحقيق الاستقرار، أصدر المصرف المركزي حزمة من القرارات التي تنظم عمليات الحوالات والصرافة، مما انعكس إيجاباً على سعر صرف الليرة في السوق الموازية، مع التأكيد على ملاحقة المتلاعبين بالأسعار.',
        'desc_en':
            'In a move aimed at achieving stability, the Central Bank issued a package of decisions regulating remittance and exchange operations, reflecting positively on the Lira rate, while emphasizing the crackdown on speculators.',
        'date': 'منذ ساعة',
        'tag_ar': 'اقتصاد محلي',
        'tag_en': 'Local Economy',
      },
      {
        'title_ar': 'تقرير: الذهب يتجه لتسجيل أفضل أداء سنوي منذ عقد',
        'title_en':
            'Report: Gold on Track for Best Annual Performance in a Decade',
        'desc_ar':
            'يرى المحللون أن التوترات الجيوسياسية المستمرة والتحول نحو خفض أسعار الفائدة عالمياً جعل المعدن الأصفر الخيار المفضل للمستثمرين للتحوط من المخاطر، مع توقعات باستمرار الصعود في الربع القادم.',
        'desc_en':
            'Analysts believe ongoing geopolitical tensions and the global shift towards lower interest rates have made the yellow metal the preferred choice for risk hedging, with expectations for continued growth in the next quarter.',
        'date': 'منذ 3 ساعات',
        'tag_ar': 'أسواق عالمية',
        'tag_en': 'Global Markets',
      },
      {
        'title_ar': 'انخفاض معدلات التضخم في منطقة اليورو بأكثر من المتوقع',
        'title_en': 'Eurozone Inflation Drops More Than Expected',
        'desc_ar':
            'أظهرت البيانات الرسمية تباطؤاً ملحوظاً في وتيرة ارتفاع الأسعار، مما يفتح الباب أمام البنك المركزي الأوروبي لخفض إضافي في أسعار الفائدة في اجتماعه القادم، مما قد يؤثر على قوة اليورو أمام العملات الأخرى.',
        'desc_en':
            'Official data showed a significant slowdown in the pace of price increases, opening the door for the ECB to further cut interest rates in its next meeting, which could affect the Euro\'s strength against other currencies.',
        'date': 'اليوم',
        'tag_ar': 'اقتصاد عالمي',
        'tag_en': 'World Economy',
      },
    ];
  }
}
