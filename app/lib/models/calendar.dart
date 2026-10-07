/// My calendar link: the token in it, and what it holds.
class CalendarFeed {
  const CalendarFeed({
    required this.token,
    this.enabled = true,
    this.includeBirthdays = true,
    this.includeRemembrance = true,
    this.lastFetchedAt,
  });

  final String token;
  final bool enabled;
  final bool includeBirthdays;
  final bool includeRemembrance;

  /// When a calendar app last fetched it.
  final DateTime? lastFetchedAt;

  factory CalendarFeed.fromJson(Map<String, dynamic> j) => CalendarFeed(
        token: j['token'] as String,
        enabled: j['enabled'] as bool? ?? true,
        includeBirthdays: j['include_birthdays'] as bool? ?? true,
        includeRemembrance: j['include_remembrance'] as bool? ?? true,
        lastFetchedAt: j['last_fetched_at'] == null ? null : DateTime.parse(j['last_fetched_at'] as String).toLocal(),
      );
}

/// The links to give calendar apps for [https] (the feed's address).
class CalendarLinks {
  CalendarLinks(this.https);

  final String https;

  /// Apple Calendar and Outlook subscribe to webcal:// links.
  String get webcal => https.replaceFirst(RegExp(r'^https?://'), 'webcal://');

  /// Opens Google Calendar's "add this calendar" page.
  String get google => 'https://calendar.google.com/calendar/render?cid=${Uri.encodeComponent(webcal)}';
}
