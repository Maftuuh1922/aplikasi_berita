import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class ArticleScraperService {
  static Future<Map<String, dynamic>> scrapeArticle(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return {'success': false, 'content': ''};
      }

      final document = html_parser.parse(response.body);
      
      // Hapus elemen yang tidak diinginkan
      _removeUnwantedElements(document);
      
      // Ekstrak konten artikel
      String content = _extractContent(document, url);
      
      // Ekstrak gambar
      List<String> images = _extractImages(document, url);
      
      return {
        'success': true,
        'content': content,
        'images': images,
      };
    } catch (e) {
      print('Error scraping article: $e');
      return {'success': false, 'content': '', 'images': []};
    }
  }

  static void _removeUnwantedElements(Document document) {
    // Hapus elemen yang tidak diinginkan
    final unwantedSelectors = [
      'script',
      'style',
      'nav',
      'header',
      'footer',
      'aside',
      'iframe',
      '.advertisement',
      '.ads',
      '.social-share',
      '.related-articles',
      '.comments',
      '#comments',
      '.sidebar',
    ];

    for (var selector in unwantedSelectors) {
      document.querySelectorAll(selector).forEach((element) {
        element.remove();
      });
    }
  }

  static String _extractContent(Document document, String url) {
    List<String> paragraphs = [];
    
    // Selectors umum untuk konten artikel (lebih lengkap)
    final contentSelectors = [
      'article p',
      '.article-content p',
      '.post-content p',
      '.entry-content p',
      '.content p',
      'main p',
      '.main-content p',
      '[itemprop="articleBody"] p',
      '.detail-content p',
      '.news-content p',
      '.story-content p',
      '#article-content p',
      '.article__body p',
      '.post__content p',
    ];

    Element? contentElement;
    
    // Cari elemen konten dengan prioritas
    for (var selector in contentSelectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        // Ekstrak dari semua paragraf yang ditemukan
        for (var p in elements) {
          String text = p.text.trim();
          
          // Filter paragraf yang valid
          if (text.length > 40 && !_isUnwantedText(text)) {
            // Hindari duplikasi
            if (!paragraphs.contains(text)) {
              paragraphs.add(text);
            }
          }
        }
        
        // Jika sudah dapat banyak paragraf, break
        if (paragraphs.length > 5) break;
      }
    }

    // Jika masih sedikit, coba ambil semua paragraf dari body
    if (paragraphs.length < 3) {
      final allParagraphs = document.querySelectorAll('p');
      for (var p in allParagraphs) {
        String text = p.text.trim();
        if (text.length > 50 && !_isUnwantedText(text) && !paragraphs.contains(text)) {
          paragraphs.add(text);
        }
        if (paragraphs.length >= 10) break;
      }
    }

    // Jika tidak ada paragraf ditemukan, ambil dari meta description
    if (paragraphs.isEmpty) {
      final metaDesc = document.querySelector('meta[name="description"]');
      if (metaDesc != null) {
        final desc = metaDesc.attributes['content'];
        if (desc != null && desc.isNotEmpty) {
          paragraphs.add(desc);
        }
      }
      
      // Coba Open Graph description
      final ogDesc = document.querySelector('meta[property="og:description"]');
      if (ogDesc != null && paragraphs.isEmpty) {
        final desc = ogDesc.attributes['content'];
        if (desc != null && desc.isNotEmpty) {
          paragraphs.add(desc);
        }
      }
    }

    return paragraphs.join('\n\n');
  }

  static bool _isUnwantedText(String text) {
    final unwantedPatterns = [
      'cookie',
      'subscribe',
      'newsletter',
      'advertisement',
      'read more',
      'baca juga',
      'berita terkait',
      'lihat juga',
      'follow us',
      'share this',
      'bagikan',
      'komentar',
      'redaksi',
      'reporter',
      'editor',
      'loading',
      'undefined',
    ];

    final lowerText = text.toLowerCase();
    
    // Cek apakah text mengandung pattern yang tidak diinginkan
    for (var pattern in unwantedPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }
    
    // Cek apakah text terlalu pendek (kurang dari 40 karakter)
    if (text.length < 40) {
      return true;
    }
    
    // Cek apakah text hanya berisi link atau simbol
    if (RegExp(r'^[^a-zA-Z0-9]*$').hasMatch(text)) {
      return true;
    }
    
    return false;
  }

  static List<String> _extractImages(Document document, String url) {
    List<String> images = [];
    final imgElements = document.querySelectorAll('article img, .article-content img, .post-content img');

    for (var img in imgElements) {
      String? src = img.attributes['src'] ?? img.attributes['data-src'];
      if (src != null && src.isNotEmpty) {
        // Convert relative URL to absolute
        if (src.startsWith('//')) {
          src = 'https:$src';
        } else if (src.startsWith('/')) {
          final uri = Uri.parse(url);
          src = '${uri.scheme}://${uri.host}$src';
        }
        
        // Filter out small images (icons, logos, etc)
        if (!src.contains('icon') && !src.contains('logo')) {
          images.add(src);
        }
      }
    }

    return images.take(5).toList(); // Maksimal 5 gambar
  }
}
