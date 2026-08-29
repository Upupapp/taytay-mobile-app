import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/sharing/share_service.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/announcement_repository.dart';
import 'news_screen.dart' show formatPublishedDate;
import 'post_detail_controller.dart';

/// One announcement, opened by tapping the feed or by a push notification.
///
/// ---
///
/// **The identifier is re-validated here.** It was validated once by [DeepLink]
/// on the way in, but a path can also be typed, pasted or restored from the back
/// stack, and none of those routes pass through the resolver.
///
/// **A missing post is an ordinary outcome, not an error.** An announcement can
/// be withdrawn between the notification being sent and the resident tapping it
/// — a correction to a typhoon advisory is exactly the case.
///
/// **Every interaction is offered only when the backend declared it.** A
/// comment box that fails on submit wastes somebody's typing; a report control
/// the backend cannot record tells a resident their complaint went somewhere
/// when it went nowhere.
///
/// **A guest reads everything and is gated only at the point of acting.** The
/// gate holds the intent and returns them here, so the tap that was interrupted
/// is the tap they finish.
class NewsPostScreen extends StatefulWidget {
  const NewsPostScreen({required this.postId, super.key});

  final String postId;

  @override
  State<NewsPostScreen> createState() => _NewsPostScreenState();
}

class _NewsPostScreenState extends State<NewsPostScreen> {
  PostDetailController? _controller;
  final TextEditingController _composer = TextEditingController();

  bool get _idIsValid => DeepLink.isValidIdentifier(widget.postId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || !_idIsValid) return;

    _controller =
        PostDetailController(
            repository: AppDependencies.of(context).announcementRepository,
            postId: widget.postId,
          )
          ..addListener(_onChanged)
          ..load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    _composer.dispose();
    super.dispose();
  }

  /// The access decision for [intent], from the same policy the router uses.
  AccessDecision _decisionFor(ResidentIntentKind intent) =>
      AccessPolicy.evaluate(
        session: AppDependencies.of(context).session.state,
        requirement: intent.requirement,
      );

  /// Shows the sign-in sheet and remembers what the resident was doing, so the
  /// tap that was interrupted is the tap they finish.
  Future<void> _gate(ResidentIntentKind intent, AccessDecision decision) =>
      AccessGateSheet.show(
        context: context,
        decision: decision,
        intent: intent,
        targetId: widget.postId,
      );

  Future<void> _onReact(ReactionKind reaction) async {
    final decision = _decisionFor(ResidentIntentKind.likePost);
    if (decision is! AccessAllowed) {
      await _gate(ResidentIntentKind.likePost, decision);
      return;
    }
    // Light feedback on the press; nothing celebratory until the server agrees.
    unawaited(
      AppHaptics.fire(
        HapticIntent.selection,
        suppressed: Motion.reduced(context),
      ),
    );
    await _controller?.toggleReaction(reaction);
  }

  Future<void> _onSubmitComment() async {
    final decision = _decisionFor(ResidentIntentKind.commentOnPost);
    if (decision is! AccessAllowed) {
      await _gate(ResidentIntentKind.commentOnPost, decision);
      return;
    }

    final controller = _controller;
    if (controller == null) return;

    final text = _composer.text;
    final posted = await controller.submitComment(text);
    if (!mounted) return;

    if (posted) {
      _composer.clear();
      // Success haptic only after the server accepted it.
      unawaited(
        AppHaptics.fire(
          HapticIntent.confirm,
          suppressed: Motion.reduced(context),
        ),
      );
    }
    // On failure the text stays in the field, deliberately: losing a paragraph
    // somebody typed on a phone because a bus went through a tunnel is the
    // failure this avoids.
  }

  Future<void> _onShare() async {
    final post = _controller?.post;
    if (post == null) return;

    final outcome = await AppDependencies.of(context).shareService.share(
      ShareableContent(
        title: post.title,
        // Public content only. Nothing about this resident goes into it.
        body: '${post.title}\n\nFrom Taytay LGU',
        // The server's link or none — this app does not compose a public URL.
        url: post.shareUrl,
      ),
    );
    if (!mounted) return;

    final message = switch (outcome) {
      ShareOutcome.shared => null,
      ShareOutcome.dismissed => null,
      ShareOutcome.copiedToClipboard =>
        'Copied. You can paste this into any app.',
      ShareOutcome.unavailable => 'Sharing is not available on this device.',
    };
    if (message != null) {
      outcome == ShareOutcome.copiedToClipboard
          ? Outcome.succeeded(context, message)
          : Outcome.problem(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement')),
      body: SafeArea(
        child: switch ((_idIsValid, controller)) {
          // An id this app would never have produced. Same words as a missing
          // post: the app is not an oracle for which ids exist.
          (false, _) => _NotAvailable(
            message: DeepLinkRejection.invalidIdentifier.residentMessage,
          ),
          (_, null) => const AppLoadingView(),
          (_, final PostDetailController active) => _Detail(
            controller: active,
            composer: _composer,
            onReact: _onReact,
            onShare: _onShare,
            onSubmitComment: _onSubmitComment,
          ),
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.controller,
    required this.composer,
    required this.onReact,
    required this.onShare,
    required this.onSubmitComment,
  });

  final PostDetailController controller;
  final TextEditingController composer;
  final Future<void> Function(ReactionKind) onReact;
  final Future<void> Function() onShare;
  final Future<void> Function() onSubmitComment;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const AppLoadingView(message: 'Opening announcement…');
    }

    final post = controller.post;
    if (post == null) {
      return _NotAvailable(
        message: DeepLinkRejection.unknownTarget.residentMessage,
      );
    }

    final theme = Theme.of(context);
    final capabilities = controller.capabilities;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(post.title, style: theme.textTheme.headlineSmall),
        ),
        if (post.author != null || post.publishedAt != null) ...<Widget>[
          const SizedBox(height: Spacing.xs),
          Text(
            <String>[
              if (post.author != null) post.author!,
              if (post.publishedAt != null)
                formatPublishedDate(post.publishedAt!),
            ].join(' · '),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: Spacing.md),
        Text(post.body, style: theme.textTheme.bodyLarge),

        if (capabilities.canReact || capabilities.canShare) ...<Widget>[
          const SizedBox(height: Spacing.lg),
          const Divider(),
          _ActionBar(
            controller: controller,
            onReact: onReact,
            onShare: onShare,
          ),
        ],

        if (capabilities.canComment) ...<Widget>[
          const SizedBox(height: Spacing.lg),
          _Comments(
            controller: controller,
            composer: composer,
            onSubmit: onSubmitComment,
          ),
        ],
      ],
    );
  }
}

/// Reactions and share. Only what the backend offered.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.controller,
    required this.onReact,
    required this.onShare,
  });

  final PostDetailController controller;
  final Future<void> Function(ReactionKind) onReact;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final post = controller.post!;
    final mine = controller.myReaction?.known;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (controller.capabilities.canReact)
            for (final available in post.availableReactions)
              _ReactionChip(
                reaction: available,
                isSelected: available.known != null && available.known == mine,
                // A reaction kind this build does not recognise is shown by its
                // raw label and cannot be pressed: sending a value the app does
                // not understand is worse than showing that it exists.
                onPressed: available.known == null || controller.isReacting
                    ? null
                    : () => onReact(available.known!),
              ),

          if (post.engagement?.reactions != null)
            Text(
              '${post.engagement!.reactions}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

          if (controller.capabilities.canShare)
            TextButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined, size: IconSizes.sm),
              label: const Text('Share'),
            ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.reaction,
    required this.isSelected,
    required this.onPressed,
  });

  final ServerValue<ReactionKind> reaction;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (reaction.known) {
      ReactionKind.like => 'Like',
      ReactionKind.care => 'Care',
      ReactionKind.celebrate => 'Celebrate',
      ReactionKind.sad => 'Sad',
      // Unrecognised: the server's own label, shown as sent.
      null => reaction.raw,
    };

    return FilterChip(
      selected: isSelected,
      onSelected: onPressed == null ? null : (_) => onPressed!(),
      label: Text(label),
      // Selection is a state a screen reader must hear, not only see.
      tooltip: isSelected ? '$label, selected' : label,
    );
  }
}

/// Comments, replies, and the composer.
class _Comments extends StatelessWidget {
  const _Comments({
    required this.controller,
    required this.composer,
    required this.onSubmit,
  });

  final PostDetailController controller;
  final TextEditingController composer;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comments = controller.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Comments', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.md),

        _Composer(
          controller: controller,
          composer: composer,
          onSubmit: onSubmit,
        ),
        const SizedBox(height: Spacing.lg),

        if (comments.isEmpty && !controller.isLoadingComments)
          Text(
            'No comments yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

        for (final comment in comments)
          Padding(
            padding: EdgeInsets.only(
              bottom: Spacing.md,
              // Replies sit under their parent.
              left: comment.isReply ? Spacing.xl : 0,
            ),
            child: _CommentTile(comment: comment, controller: controller),
          ),

        if (controller.commentsFailure != null)
          AppBanner(
            tone: BannerTone.warning,
            title: 'Could not load comments',
            message: 'Anything already shown is still here.',
            action: TextButton(
              onPressed: controller.loadMoreComments,
              child: const Text('Try again'),
            ),
          )
        else if (controller.isLoadingComments)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.hasMoreComments && comments.isNotEmpty)
          TextButton(
            onPressed: controller.loadMoreComments,
            child: const Text('Load more comments'),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.composer,
    required this.onSubmit,
  });

  final PostDetailController controller;
  final TextEditingController composer;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final sending = controller.postingState == CommentPostingState.sending;
    final failed = controller.postingState == CommentPostingState.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          // A comment wraps, so the return key inserts a line.
          textInputAction: TextInputAction.newline,
          controller: composer,
          maxLines: 3,
          minLines: 1,
          enabled: !sending,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Write a comment',
          ),
        ),
        if (failed) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          const AppBanner(
            tone: BannerTone.error,
            title: 'Your comment was not posted',
            // Says the thing that matters: nothing was sent, and the words are
            // still here.
            message:
                'Nothing was sent, and what you wrote is still in the box. '
                'Trying again will not post it twice.',
          ),
        ],
        const SizedBox(height: Spacing.sm),
        AppButton(
          label: failed ? 'Try again' : 'Post comment',
          loading: sending,
          onPressed: sending ? null : onSubmit.call,
          hapticIntent: HapticIntent.selection,
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.controller});

  final PostComment comment;
  final PostDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (comment.isHiddenByModerator) {
      // Rendered as withheld rather than dropped: dropping it would leave a
      // reply pointing at nothing, and would hide from a resident that their
      // own comment was moderated. The app does not second-guess the state.
      return AppCard(
        child: Text(
          'This comment was removed by Taytay LGU.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (comment.isOfficial) ...<Widget>[
                Icon(
                  Icons.verified_outlined,
                  size: IconSizes.sm,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Spacing.xxs),
              ],
              Flexible(
                child: Text(
                  comment.authorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    // An official reply is visibly distinguished, and the word
                    // below carries it too — never colour alone.
                    color: comment.isOfficial
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ),
              if (comment.isOfficial) ...<Widget>[
                const SizedBox(width: Spacing.xs),
                Text(
                  'Taytay LGU',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(comment.body, style: theme.textTheme.bodyMedium),

          if (comment.createdAt != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(
              formatPublishedDate(comment.createdAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              children: <Widget>[
                // Own comment only, and only when the backend supports deleting
                // one. There is no control here that hides or edits somebody
                // else's words — that is an admin-console act (Article 0).
                if (comment.isMine &&
                    controller.capabilities.canDeleteOwnComment)
                  TextButton(
                    onPressed: () => controller.deleteOwnComment(comment.id),
                    child: const Text('Delete'),
                  ),

                /*
                 * REPORTING — F26, and required by both app stores for
                 * user-generated content.
                 *
                 * Never on your own comment: the author already has Delete,
                 * which is immediate and needs nobody, and the server refuses a
                 * self-report anyway. Offering a control that always fails is
                 * the thing this app refuses to do.
                 *
                 * Reporting *asks a moderator to look*. Nothing here removes
                 * anything, and the server changes nothing about the comment
                 * either — so this cannot be used to take a neighbour off the
                 * municipality's feed.
                 */
                if (!comment.isMine && controller.capabilities.canReportComment)
                  TextButton(
                    onPressed: () => _report(context),
                    child: const Text('Report'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Asks which of the five reasons, then sends it.
  ///
  /// A picker rather than a text field, and there is deliberately no "other"
  /// with a box under it. That box is where a resident types a neighbour's name
  /// and address into a municipal record that staff read — see [ReportReason].
  Future<void> _report(BuildContext context) async {
    final ReportReason? reason = await AppSheet.show<ReportReason>(
      context: context,
      title: 'Report this comment',
      builder: (BuildContext sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Text(
              'Taytay LGU staff will look at this comment. Nothing is removed '
              'automatically, and the person who wrote it is not told who '
              'reported it.',
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final ReportReason option in ReportReason.values)
            ListTile(
              title: Text(reportReasonCopy(context, option).label),
              subtitle: Text(reportReasonCopy(context, option).description),
              onTap: () => Navigator.of(sheetContext).pop(option),
            ),
        ],
      ),
    );

    if (reason == null || !context.mounted) return;

    final bool sent = await controller.reportComment(comment.id, reason);
    if (!context.mounted) return;

    /*
     * The same answer either way is NOT what happens here.
     *
     * The server's response never varies — reported now, already reported,
     * reported by nine others — because any difference would publish other
     * residents' actions. But a *failure to reach the server at all* is
     * different, and a resident who has just reported something abusive must
     * not be left believing the municipality was told when nothing was sent.
     */
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Thank you. Taytay LGU staff will look at this comment.'
              : 'Could not send your report. Please try again.',
        ),
      ),
    );
  }
}

/// The honest dead end for a link that cannot be opened.
class _NotAvailable extends StatelessWidget {
  const _NotAvailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'This announcement is not available',
      kind: StatusKind.empty,
      icon: Icons.link_off_outlined,
      message: message,
      primaryAction: FilledButton(
        onPressed: () => context.goNamed(AppRoute.news.routeName),
        child: const Text('See all announcements'),
      ),
    );
  }
}
