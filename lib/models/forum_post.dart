import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Facebook-style reactions available on a post.
enum ReactionType { like, love, haha, wow, sad, angry }

extension ReactionTypeX on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.haha:
        return '😆';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😡';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.haha:
        return 'Haha';
      case ReactionType.wow:
        return 'Wow';
      case ReactionType.sad:
        return 'Sad';
      case ReactionType.angry:
        return 'Angry';
    }
  }

  Color get color {
    switch (this) {
      case ReactionType.like:
        return AppColors.primary;
      case ReactionType.love:
        return const Color(0xFFE2645F);
      case ReactionType.haha:
      case ReactionType.wow:
      case ReactionType.sad:
        return const Color(0xFFE0A23B);
      case ReactionType.angry:
        return const Color(0xFFD9663F);
    }
  }
}

/// A comment on a forum post (Facebook-style) with full reactions.
class ForumComment {
  final String id;
  final String author;
  final String authorId;
  final String body;
  final DateTime createdAt;

  /// Count per reaction type on this reply.
  final Map<ReactionType, int> reactions;

  /// The current user's reaction to this reply (null = none).
  ReactionType? myReaction;

  int reports;

  ForumComment({
    required this.id,
    required this.author,
    required this.body,
    this.authorId = '',
    DateTime? createdAt,
    Map<ReactionType, int>? reactions,
    int likes = 0,
    this.myReaction,
    this.reports = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        // `likes` is accepted for backwards-compatible seed data and folded
        // into the new reactions map as 👍 Likes.
        reactions = reactions ?? (likes > 0 ? {ReactionType.like: likes} : {});

  int get reactionCount => reactions.values.fold(0, (a, b) => a + b);

  /// Up to three reaction emojis with the highest counts (for the summary).
  List<ReactionType> get topReactions {
    final entries = reactions.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList();
  }
}

/// A community forum post with media, reactions and a thread of comments.
class ForumPost {
  final String id;
  final String author;

  /// uid of the poster — used for owner/admin delete permission.
  final String authorId;
  final String body;

  /// Optional attachments (local path or network URL).
  final String? imageURL;
  final String? videoURL;

  final DateTime createdAt;
  final List<ForumComment> comments;

  /// Count per reaction type.
  final Map<ReactionType, int> reactions;

  /// The current user's reaction (null = none).
  ReactionType? myReaction;

  int reports;

  ForumPost({
    required this.id,
    required this.author,
    required this.body,
    this.authorId = '',
    this.imageURL,
    this.videoURL,
    DateTime? createdAt,
    List<ForumComment>? comments,
    Map<ReactionType, int>? reactions,
    this.myReaction,
    this.reports = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        comments = comments ?? [],
        reactions = reactions ?? {};

  int get commentCount => comments.length;

  int get reactionCount => reactions.values.fold(0, (a, b) => a + b);

  bool get hasMedia => imageURL != null || videoURL != null;

  /// Up to three reaction emojis with the highest counts (for the summary row).
  List<ReactionType> get topReactions {
    final entries = reactions.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList();
  }
}
