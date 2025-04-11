import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String searchQuery;
  final TextStyle style;
  final TextStyle highlightStyle;
  final int? maxLines;

  const HighlightedText({
    super.key,
    required this.text,
    required this.searchQuery,
    required this.style,
    required this.highlightStyle,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerCaseText = text.toLowerCase();
    final lowerCaseQuery = searchQuery.toLowerCase();

    // If the text doesn't contain the query at all, return plain text
    if (!lowerCaseText.contains(lowerCaseQuery)) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Find all occurrences of the query in the text
    final List<int> matchPositions = [];
    int position = 0;
    while (true) {
      position = lowerCaseText.indexOf(lowerCaseQuery, position);
      if (position == -1) break;
      matchPositions.add(position);
      position += lowerCaseQuery.length;
    }

    // Build spans with highlighted matches
    final List<TextSpan> spans = [];
    int currentPosition = 0;

    for (final matchPosition in matchPositions) {
      // Add text before the match
      if (matchPosition > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, matchPosition),
          style: style,
        ));
      }

      // Add the highlighted match
      spans.add(TextSpan(
        text: text.substring(
            matchPosition, matchPosition + lowerCaseQuery.length),
        style: highlightStyle,
      ));

      currentPosition = matchPosition + lowerCaseQuery.length;
    }

    // Add any remaining text after the last match
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
