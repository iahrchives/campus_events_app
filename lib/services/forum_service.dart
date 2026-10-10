import 'dart:async';

import '../models/forum_post.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Mock community forum store with a broadcast stream so the list and the
/// thread detail stay in sync (mirrors a Firestore `Posts` + comments layout).
class ForumService {
  ForumService._() {
    _controller = StreamController<List<ForumPost>>.broadcast(
      onListen: () => _controller.add(List.unmodifiable(_posts)),
    );
  }
  static final ForumService instance = ForumService._();

  late final StreamController<List<ForumPost>> _controller;

  final List<ForumPost> _posts = [
    ForumPost(
      id: 'p1',
      author: 'Ava Cruz',
      authorId: 'uid_validated_001',
      body: 'Anyone selling a graphing calculator? Need it by Monday!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      reactions: {ReactionType.like: 4, ReactionType.love: 1},
      comments: [
        ForumComment(
            id: 'c1',
            author: 'Marco Lim',
            body: 'I have one, DM me!',
            likes: 2),
        ForumComment(
            id: 'c2', author: 'Bea Tan', body: 'Check the marketplace tab too.'),
      ],
    ),
    ForumPost(
      id: 'p2',
      author: 'Marco Lim',
      authorId: 'uid_pending_002',
      body: 'Reminder: Org fair booths close at 4 PM today. 🎪',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      reactions: {ReactionType.like: 8, ReactionType.wow: 2},
      comments: [
        ForumComment(
            id: 'c3', author: 'Kyle Reyes', body: 'Thanks for the heads up!'),
      ],
    ),
    ForumPost(
      id: 'p3',
      author: 'Bea Tan',
      authorId: 'uid_admin_000',
      body: 'Lost a blue tumbler near Room 204 — please DM me.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      reactions: {ReactionType.sad: 3},
    ),
    ForumPost(
      id: 'p4',
      author: 'Kyle Reyes',
      authorId: 'uid_validated_001',
      body: 'Study group for finals this weekend at the library?',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      reactions: {ReactionType.like: 5, ReactionType.love: 2, ReactionType.haha: 1},
      comments: [
        ForumComment(
            id: 'c4',
            author: 'Ava Cruz',
            body: 'I\u2019m in! Saturday morning?',
            likes: 1),
      ],
    ),
  ];

  Stream<List<ForumPost>> get stream => _controller.stream;
  List<ForumPost> get current => List.unmodifiable(_posts);

  ForumPost? byId(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _emit() => _controller.add(List.unmodifiable(_posts));

  Future<void> addPost({
    required String author,
    required String body,
    String authorId = '',
    String? imageURL,
    String? videoURL,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _posts.insert(
      0,
      ForumPost(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        author: author,
        authorId: authorId,
        body: body,
        imageURL: imageURL,
        videoURL: videoURL,
      ),
    );
    _emit();
  }

  Future<void> deletePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _posts.removeWhere((p) => p.id == postId);
    _emit();
  }

  /// Sets / toggles the current user's reaction on a post.
  void setReaction(String postId, ReactionType? reaction) {
    final post = byId(postId);
    if (post == null) return;
    final prev = post.myReaction;

    if (prev == reaction) {
      // Tapping the same reaction removes it.
      if (prev != null) {
        post.reactions[prev] = (post.reactions[prev] ?? 1) - 1;
        if ((post.reactions[prev] ?? 0) <= 0) post.reactions.remove(prev);
      }
      post.myReaction = null;
    } else {
      if (prev != null) {
        post.reactions[prev] = (post.reactions[prev] ?? 1) - 1;
        if ((post.reactions[prev] ?? 0) <= 0) post.reactions.remove(prev);
      }
      if (reaction != null) {
        post.reactions[reaction] = (post.reactions[reaction] ?? 0) + 1;
        _notifyAuthor(
          recipientId: post.authorId,
          type: AppNotificationType.forumReaction,
          title: 'New reaction on your post',
          body:
              '${AuthService.instance.currentUser?.fullName ?? "Someone"} reacted ${reaction.emoji} to your post.',
          targetId: post.id,
        );
      }
      post.myReaction = reaction;
    }
    _emit();
  }

  /// Sets / toggles the current user's reaction on a reply (comment).
  void setCommentReaction(
      String postId, String commentId, ReactionType? reaction) {
    final post = byId(postId);
    if (post == null) return;
    for (final c in post.comments) {
      if (c.id != commentId) continue;
      final prev = c.myReaction;
      if (prev == reaction) {
        if (prev != null) {
          c.reactions[prev] = (c.reactions[prev] ?? 1) - 1;
          if ((c.reactions[prev] ?? 0) <= 0) c.reactions.remove(prev);
        }
        c.myReaction = null;
      } else {
        if (prev != null) {
          c.reactions[prev] = (c.reactions[prev] ?? 1) - 1;
          if ((c.reactions[prev] ?? 0) <= 0) c.reactions.remove(prev);
        }
        if (reaction != null) {
          c.reactions[reaction] = (c.reactions[reaction] ?? 0) + 1;
          _notifyAuthor(
            recipientId: c.authorId,
            type: AppNotificationType.forumReaction,
            title: 'New reaction on your reply',
            body:
                '${AuthService.instance.currentUser?.fullName ?? "Someone"} reacted ${reaction.emoji} to your reply.',
            targetId: post.id,
          );
        }
        c.myReaction = reaction;
      }
      break;
    }
    _emit();
  }

  Future<void> addComment(String postId, ForumComment comment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final post = byId(postId);
    if (post == null) return;
    post.comments.add(comment);
    _notifyAuthor(
      recipientId: post.authorId,
      actorId: comment.authorId,
      type: AppNotificationType.forumReply,
      title: 'New reply to your post',
      body: '${comment.author} replied: ${comment.body}',
      targetId: post.id,
    );
    _emit();
  }

  /// Removes a comment. Allowed for the comment author or an admin.
  Future<void> deleteComment(String postId, String commentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final post = byId(postId);
    if (post == null) return;
    post.comments.removeWhere((c) => c.id == commentId);
    _emit();
  }

  /// Pushes a notification to a post/comment author unless they are the actor.
  void _notifyAuthor({
    required String recipientId,
    required AppNotificationType type,
    required String title,
    required String body,
    String? actorId,
    String? targetId,
  }) {
    final me = actorId ?? AuthService.instance.currentUser?.uid ?? '';
    if (recipientId.isEmpty || recipientId == me) return;
    NotificationService.instance.push(
      userId: recipientId,
      type: type,
      title: title,
      body: body,
      targetId: targetId,
    );
  }

  /// Flags a post for moderation (mock — increments a counter, stores reason).
  void reportPost(String postId, {String? reason}) {
    final post = byId(postId);
    if (post == null) return;
    post.reports += 1;
    _emit();
  }

  void reportComment(String postId, String commentId, {String? reason}) {
    final post = byId(postId);
    if (post == null) return;
    for (final c in post.comments) {
      if (c.id == commentId) {
        c.reports += 1;
        break;
      }
    }
    _emit();
  }
}
