import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility class for handling links in text messages
class LinkUtils {
  /// Regular expression to detect URLs
  static final RegExp urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Check if text contains any URLs
  static bool containsUrl(String text) {
    return urlRegex.hasMatch(text);
  }

  /// Extract all URLs from text
  static List<String> extractUrls(String text) {
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }

  /// Launch URL
  static Future<void> launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  /// Build a TextSpan with clickable links
  static TextSpan buildLinkifiedText({
    required String text,
    required TextStyle normalStyle,
    required TextStyle linkStyle,
  }) {
    if (!containsUrl(text)) {
      return TextSpan(text: text, style: normalStyle);
    }

    final List<TextSpan> spans = [];
    final matches = urlRegex.allMatches(text);
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the link
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: normalStyle,
        ));
      }

      // Add the clickable link
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchURL(url),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last link
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: normalStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  /// Build a RichText widget with clickable links
  static Widget buildLinkifiedTextWidget({
    required String text,
    required TextStyle normalStyle,
    TextStyle? linkStyle,
  }) {
    final effectiveLinkStyle = linkStyle ??
        normalStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
          fontWeight: FontWeight.bold,
        );

    return RichText(
      text: buildLinkifiedText(
        text: text,
        normalStyle: normalStyle,
        linkStyle: effectiveLinkStyle,
      ),
    );
  }
}

