import 'package:url_launcher/url_launcher.dart';

/// Service that uses [url_launcher] to open URLs, tel, mailto, and app deep links.
class UrlLauncherService {
  /// Launch a generic URL (web, https, etc.).
  static Future<bool> launchUrlString(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Launch a [Uri] directly.
  static Future<bool> launchUri(Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: mode);
    }
    return false;
  }

  /// Open phone dialer with [number].
  static Future<bool> launchTel(String number) async {
    final v = number.trim();
    if (v.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: v);
    return launchUri(uri);
  }

  /// Open email client with [email]. Optional [subject] and [body].
  static Future<bool> launchMailto(String email, {String? subject, String? body}) async {
    final v = email.trim();
    if (v.isEmpty) return false;
    final uri = Uri(
      scheme: 'mailto',
      path: v,
      query: _encodeMailtoQuery(subject: subject, body: body),
    );
    return launchUri(uri);
  }

  static String? _encodeMailtoQuery({String? subject, String? body}) {
    final parts = <String>[];
    if (subject != null && subject.isNotEmpty) parts.add('subject=${Uri.encodeComponent(subject)}');
    if (body != null && body.isNotEmpty) parts.add('body=${Uri.encodeComponent(body)}');
    return parts.isEmpty ? null : parts.join('&');
  }

  /// Open WhatsApp chat with [phoneNumber]. Expects digits only or normal phone format.
  static Future<bool> launchWhatsApp(String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return false;
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return launchTel(phoneNumber);
  }

  /// Open Telegram. [value] can be phone number or @username.
  static Future<bool> launchTelegram(String value) async {
    final v = value.trim();
    if (v.isEmpty) return false;

    if (v.startsWith('@') || (!v.contains('+') && !RegExp(r'^\d').hasMatch(v))) {
      final username = v.replaceAll('@', '').trim();
      final uri = Uri.parse('https://t.me/$username');
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      final digits = v.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isNotEmpty) {
        final phoneWithPlus = digits.startsWith('880') ? '+$digits' : digits;
        var uri = Uri.parse('tg://resolve?phone=$phoneWithPlus');
        if (await canLaunchUrl(uri)) {
          return launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        uri = Uri.parse('tg://msg?to=$phoneWithPlus');
        if (await canLaunchUrl(uri)) {
          return launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
    return launchTel(v);
  }

  /// Open IMO chat with [phoneNumber].
  static Future<bool> launchImo(String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return false;
    final uri = Uri.parse('imo://chat?phone=$digits');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return launchTel(phoneNumber);
  }

  /// Launch contact by type: email, whatsapp, telegram, imo, or phone.
  static Future<void> launchContact({
    required String contactType,
    required String contactValue,
    String? mailSubject,
  }) async {
    final v = contactValue.trim();
    if (v.isEmpty) return;

    final type = contactType.toLowerCase();

    if (type.contains('email')) {
      await launchMailto(v, subject: mailSubject ?? 'Contact from Nursery Shop BD App');
      return;
    }
    if (type.contains('whatsapp')) {
      await launchWhatsApp(v);
      return;
    }
    if (type.contains('telegram')) {
      await launchTelegram(v);
      return;
    }
    if (type.contains('imo')) {
      await launchImo(v);
      return;
    }
    await launchTel(v);
  }
}
