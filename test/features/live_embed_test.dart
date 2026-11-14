import 'package:app_quanly_giaidau/features/match/utils/live_embed.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMLIVE-01..10 (App): cùng bảng quy tắc với Web và Backend.
const _id = 'dQw4w9WgXcQ';

void main() {
  test('TC-CAMLIVE-01..06 các dạng link YouTube -> embed', () {
    for (final url in [
      'https://www.youtube.com/watch?v=$_id',
      'https://youtu.be/$_id?si=abc',
      'https://www.youtube.com/live/$_id?feature=share',
      'https://m.youtube.com/watch?v=$_id&t=5',
      'https://www.youtube.com/embed/$_id',
      'https://youtube.com/shorts/$_id',
      '  https://youtu.be/$_id  ',
    ]) {
      final r = LiveEmbed.parse(url);
      expect(r.isOk, isTrue, reason: url);
      expect(r.platform, LiveEmbedPlatform.youtube);
      expect(r.canonicalUrl, 'https://www.youtube.com/watch?v=$_id');
      expect(r.embedUrl, 'https://www.youtube.com/embed/$_id');
    }
  });

  test('TC-CAMLIVE-07 Facebook watch/videos/fb.watch/reel', () {
    for (final url in [
      'https://www.facebook.com/watch/?v=123456789',
      'https://www.facebook.com/SanPickleball/videos/123456789',
      'https://m.facebook.com/SanPickleball/videos/123456789/',
      'https://fb.watch/abcDEF123/',
      'https://www.facebook.com/reel/123456789',
      'https://www.facebook.com/video.php?v=123456789',
    ]) {
      final r = LiveEmbed.parse(url);
      expect(r.isOk, isTrue, reason: url);
      expect(r.platform, LiveEmbedPlatform.facebook);
      expect(
        r.embedUrl,
        'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(r.canonicalUrl!)}&show_text=false',
      );
    }
  });

  test('TC-CAMLIVE-08 link kênh/trang -> channelPage', () {
    for (final url in [
      'https://www.youtube.com/@abc',
      'https://www.youtube.com/channel/UC123',
      'https://www.youtube.com/',
      'https://www.facebook.com/SanPickleball',
      'https://www.facebook.com/',
    ]) {
      expect(
        LiveEmbed.parse(url).error,
        LiveEmbedError.channelPage,
        reason: url,
      );
    }
  });

  test('TC-CAMLIVE-09 host giả, javascript:, http, rác, rỗng -> notEmbed', () {
    for (final url in [
      'https://youtube.com.evil.com/watch?v=$_id',
      'https://evilyoutube.com/watch?v=$_id',
      'https://www.youtube.com@evil.com/watch?v=$_id',
      'https://media.aqvision.net/live/cam1/hls.m3u8',
      'javascript:alert(1)',
      'http://www.youtube.com/watch?v=$_id',
      'khong phai url',
      '',
    ]) {
      expect(LiveEmbed.parse(url).error, LiveEmbedError.notEmbed, reason: url);
    }
    expect(LiveEmbed.parse(null).error, LiveEmbedError.notEmbed);
  });

  test('TC-CAMLIVE-10 id YouTube sai -> noVideoId', () {
    expect(
      LiveEmbed.parse('https://www.youtube.com/watch?v=abc').error,
      LiveEmbedError.noVideoId,
    );
    expect(
      LiveEmbed.parse('https://youtu.be/<script>alert(1)</script>').error,
      LiveEmbedError.noVideoId,
    );
  });
}
