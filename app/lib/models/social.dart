/// Moments, albums, photos and events shared with the family.
library;

DateTime _ts(Object? v) => DateTime.parse(v as String).toLocal();

int _count(Object? embedded) {
  // PostgREST returns embedded counts as [{"count": n}].
  if (embedded is List && embedded.isNotEmpty) return (embedded.first as Map)['count'] as int? ?? 0;
  return 0;
}

List<String> _personIds(Object? rows) =>
    [for (final r in (rows as List? ?? const [])) (r as Map)['person_id'] as String];

/// An active account, as shown next to posts and comments.
class Member {
  const Member({required this.userId, required this.displayName, this.personId, this.isAdmin = false});

  final String userId;
  final String displayName;
  final String? personId;
  final bool isAdmin;

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        userId: j['user_id'] as String,
        displayName: j['display_name'] as String? ?? '',
        personId: j['person_id'] as String?,
        isAdmin: j['role'] == 'admin',
      );
}

class Photo {
  const Photo({
    required this.id,
    required this.storagePath,
    required this.uploadedBy,
    required this.createdAt,
    this.postId,
    this.albumId,
    this.caption,
    this.takenYear,
    this.people = const [],
    this.taggedBy = const {},
    this.likeCount = 0,
    this.commentCount = 0,
  });

  final String id;
  final String storagePath;
  final String uploadedBy;
  final DateTime createdAt;
  final String? postId;
  final String? albumId;
  final String? caption;
  final int? takenYear;
  final List<String> people;

  /// Who tagged each person (person id → user id).
  final Map<String, String> taggedBy;
  final int likeCount;
  final int commentCount;

  /// The year to group by: when it was taken, else when it was added.
  int get year => takenYear ?? createdAt.year;

  static const select = '*, photo_people(person_id, tagged_by), '
      'like_count:likes!likes_photo_id_fkey(count), comment_count:comments!comments_photo_id_fkey(count)';

  factory Photo.fromJson(Map<String, dynamic> j) => Photo(
        id: j['id'] as String,
        storagePath: j['storage_path'] as String,
        uploadedBy: j['uploaded_by'] as String,
        createdAt: _ts(j['created_at']),
        postId: j['post_id'] as String?,
        albumId: j['album_id'] as String?,
        caption: j['caption'] as String?,
        takenYear: j['taken_year'] as int?,
        people: _personIds(j['photo_people']),
        taggedBy: {
          for (final r in (j['photo_people'] as List? ?? const []))
            (r as Map)['person_id'] as String: r['tagged_by'] as String? ?? '',
        },
        likeCount: _count(j['like_count']),
        commentCount: _count(j['comment_count']),
      );
}

enum PostKind { moment, announcement }

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.createdAt,
    this.kind = PostKind.moment,
    this.body = '',
    this.albumId,
    this.albumTitle,
    this.pinned = false,
    this.photos = const [],
    this.people = const [],
    this.likeCount = 0,
    this.commentCount = 0,
  });

  final String id;
  final String authorId;
  final DateTime createdAt;
  final PostKind kind;
  final String body;
  final String? albumId;
  final String? albumTitle;
  final bool pinned;
  final List<Photo> photos;
  final List<String> people;
  final int likeCount;
  final int commentCount;

  static const select = '*, albums(title), photos!photos_post_id_fkey(${Photo.select}), post_people(person_id), '
      'like_count:likes!likes_post_id_fkey(count), comment_count:comments!comments_post_id_fkey(count)';

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        authorId: j['author_id'] as String,
        createdAt: _ts(j['created_at']),
        kind: j['kind'] == 'announcement' ? PostKind.announcement : PostKind.moment,
        body: j['body'] as String? ?? '',
        albumId: j['album_id'] as String?,
        albumTitle: (j['albums'] as Map?)?['title'] as String?,
        pinned: j['pinned'] as bool? ?? false,
        photos: [for (final p in (j['photos'] as List? ?? const [])) Photo.fromJson(p as Map<String, dynamic>)]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        people: _personIds(j['post_people']),
        likeCount: _count(j['like_count']),
        commentCount: _count(j['comment_count']),
      );
}

class Album {
  const Album({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    this.description,
    this.photoCount = 0,
    this.coverPath,
    this.minYear,
    this.maxYear,
    this.eventId,
  });

  final String id;
  final String title;
  final String createdBy;

  /// The event these photos are from, for an event's album.
  final String? eventId;
  final DateTime createdAt;
  final String? description;
  final int photoCount;
  final String? coverPath;
  final int? minYear;
  final int? maxYear;

  static const select = '*, photo_count:photos!photos_album_id_fkey(count), '
      'cover:photos!photos_album_id_fkey(storage_path, taken_year, created_at)';

  factory Album.fromJson(Map<String, dynamic> j) {
    final cover = (j['cover'] as List? ?? const []).cast<Map<String, dynamic>>();
    final years = [for (final c in cover) (c['taken_year'] as int?) ?? _ts(c['created_at']).year]..sort();
    return Album(
      id: j['id'] as String,
      title: j['title'] as String,
      createdBy: j['created_by'] as String? ?? '',
      createdAt: _ts(j['created_at']),
      description: j['description'] as String?,
      photoCount: _count(j['photo_count']),
      coverPath: cover.isEmpty ? null : cover.first['storage_path'] as String,
      minYear: years.isEmpty ? null : years.first,
      maxYear: years.isEmpty ? null : years.last,
      eventId: j['event_id'] as String?,
    );
  }
}

enum EventCategory { naming, wedding, meeting, condolence, graduation, other }

enum RsvpResponse { going, maybe, no }

class Rsvp {
  const Rsvp({required this.userId, required this.response, this.guests = 0});

  final String userId;
  final RsvpResponse response;
  final int guests;

  factory Rsvp.fromJson(Map<String, dynamic> j) => Rsvp(
        userId: j['user_id'] as String,
        response: RsvpResponse.values.byName(j['response'] as String),
        guests: j['guests'] as int? ?? 0,
      );
}

class FamilyEvent {
  const FamilyEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.createdBy,
    this.category = EventCategory.other,
    this.details,
    this.endsAt,
    this.place,
    this.address,
    this.rsvpEnabled = true,
    this.pinned = false,
    this.rsvps = const [],
    this.commentCount = 0,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final String createdBy;
  final EventCategory category;
  final String? details;
  final DateTime? endsAt;
  final String? place;
  final String? address;
  final bool rsvpEnabled;
  final bool pinned;
  final List<Rsvp> rsvps;
  final int commentCount;

  static const select = '*, event_rsvps(user_id, response, guests), comment_count:comments!comments_event_id_fkey(count)';

  factory FamilyEvent.fromJson(Map<String, dynamic> j) => FamilyEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        startsAt: _ts(j['starts_at']),
        createdBy: j['created_by'] as String? ?? '',
        category: EventCategory.values.byName(j['category'] as String? ?? 'other'),
        details: j['details'] as String?,
        endsAt: j['ends_at'] == null ? null : _ts(j['ends_at']),
        place: j['place'] as String?,
        address: j['address'] as String?,
        rsvpEnabled: j['rsvp_enabled'] as bool? ?? true,
        pinned: j['pinned'] as bool? ?? false,
        rsvps: [for (final r in (j['event_rsvps'] as List? ?? const [])) Rsvp.fromJson(r as Map<String, dynamic>)],
        commentCount: _count(j['comment_count']),
      );

  /// Upcoming until the end of the day it starts (or until it ends).
  bool isUpcoming(DateTime now) {
    final end = endsAt ?? DateTime(startsAt.year, startsAt.month, startsAt.day, 23, 59);
    return end.isAfter(now);
  }

  Rsvp? rsvpOf(String? userId) => rsvps.where((r) => r.userId == userId).firstOrNull;

  /// People coming, counting the guests they bring.
  int headcount(RsvpResponse response) =>
      rsvps.where((r) => r.response == response).fold(0, (n, r) => n + 1 + r.guests);
}

/// What a like or comment belongs to.
class Target {
  const Target.post(String id) : this._('post_id', id);
  const Target.photo(String id) : this._('photo_id', id);
  const Target.event(String id) : this._('event_id', id);
  const Target._(this.column, this.id);

  final String column;
  final String id;

  @override
  bool operator ==(Object other) => other is Target && other.column == column && other.id == id;

  @override
  int get hashCode => Object.hash(column, id);
}

class Comment {
  const Comment({required this.id, required this.authorId, required this.body, required this.createdAt});

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as String,
        authorId: j['author_id'] as String,
        body: j['body'] as String,
        createdAt: _ts(j['created_at']),
      );
}

/// A photo picked on the device, ready to upload.
class PickedImage {
  const PickedImage(this.bytes, this.extension);

  final List<int> bytes;
  final String extension;
}

/// A prayer or memory on someone's memorial page.
class Memory {
  const Memory({required this.id, required this.personId, required this.authorId, required this.body, required this.createdAt});

  final String id;
  final String personId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory Memory.fromJson(Map<String, dynamic> j) => Memory(
        id: j['id'] as String,
        personId: j['person_id'] as String,
        authorId: j['author_id'] as String,
        body: j['body'] as String,
        createdAt: _ts(j['created_at']),
      );
}

/// One thing found by search: a moment, an event, a story…
class SearchHit {
  const SearchHit({required this.kind, required this.id, required this.link, this.title, this.snippet, this.at});

  /// post, event, album, photo, story, cause, poll, opportunity, memory, skill, work.
  final String kind;
  final String id;
  final String? title;
  final String? snippet;
  final DateTime? at;
  final String link;

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
        kind: j['kind'] as String,
        id: j['id'] as String,
        title: j['title'] as String?,
        snippet: j['snippet'] as String?,
        at: j['at'] == null ? null : DateTime.parse(j['at'] as String).toLocal(),
        link: j['link'] as String,
      );
}
