import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/api/send_key.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../messaging/domain/message_send_failure.dart';
import '../../messaging/domain/office_messaging_repository.dart';
import '../../notifications/domain/notification_repository.dart';
import '../../profile/domain/profile_fields.dart';
import '../../registration/domain/registration_domain.dart';
import '../domain/account_password_client.dart';
import 'account_canvas.dart';
import 'change_password_form.dart';

/// Office inbox. Verified. The shell keeps the tab bar.
class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  bool _started = false;
  bool _loading = true;
  bool _failed = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _cursor;
  String? _pageError;
  List<OfficeThread> _threads = const <OfficeThread>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final result = await AppDependencies.of(
      context,
    ).officeMessagingRepository.listThreads();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      switch (result) {
        case Ok(:final value):
          _threads = _uniqueThreads(value.items);
          _remember(value);
          _pageError = null;
          _failed = false;
        case Err():
          _threads = const <OfficeThread>[];
          _cursor = null;
          _hasMore = false;
          _pageError = null;
          _failed = true;
      }
    });
  }

  Future<void> _loadMore() async {
    final String? cursor = _cursor;
    if (_loading || _loadingMore || !_hasMore || cursor == null) return;
    setState(() {
      _loadingMore = true;
      _pageError = null;
    });
    final result = await AppDependencies.of(
      context,
    ).officeMessagingRepository.listThreads(cursor: cursor);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (result case Ok(:final value)) {
        final Set<String> seen = _threads.map((OfficeThread t) => t.id).toSet();
        _threads = <OfficeThread>[
          ..._threads,
          for (final OfficeThread thread in value.items)
            if (seen.add(thread.id)) thread,
        ];
        _remember(value);
        _pageError = null;
      } else if (result case Err(:final failure)) {
        _pageError = failure.residentMessage;
      }
    });
  }

  List<OfficeThread> _uniqueThreads(List<OfficeThread> threads) {
    final Set<String> seen = <String>{};
    return <OfficeThread>[
      for (final OfficeThread thread in threads)
        if (seen.add(thread.id)) thread,
    ];
  }

  void _remember(Paginated<OfficeThread> page) {
    final String? next = page.nextCursor;
    _cursor = next;
    _hasMore = page.hasMore && next != null && next.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: BrandColors.surface,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final AccountFrame frame = _failed
        ? AccountFrame.inboxError
        : _threads.isEmpty
        ? AccountFrame.inboxEmpty
        : AccountFrame.inbox;
    return AccountCanvas(
      frame: frame,
      title: 'Messages',
      showBack: true,
      showSampleNote: AppDependencies.of(context).config.usesMockData,
      onBack: () => context.goNamed(AppRoute.profile.routeName),
      onBell: () => context.goNamed(AppRoute.notifications.routeName),
      onInboxRetry: _load,
      onInboxNearEnd: _loadMore,
      inboxMoreMessage: _pageError,
      onInboxMoreRetry: _pageError == null ? null : _loadMore,
      inbox: <AccountInboxRow>[
        for (final OfficeThread thread in _threads)
          AccountInboxRow(
            office: thread.officeName,
            when: ManilaTime.formatTime(
              thread.lastMessageAt ?? thread.updatedAt,
            ),
            preview: thread.preview,
            icon: TaytayIcons.messageSquare,
            tile: BrandColors.chipBlueBg,
            iconColor: BrandColors.taytayBlue,
            badge: thread.unreadCount > 0 ? '${thread.unreadCount}' : null,
            onTap: () => context.goNamed(
              AppRoute.messageThread.routeName,
              pathParameters: <String, String>{'threadId': thread.id},
            ),
          ),
      ],
      onMessageOffice: () => context.goNamed(AppRoute.services.routeName),
    );
  }
}

/// One thread. Full screen: the tab bar stays off this route.
class AccountThreadScreen extends StatefulWidget {
  const AccountThreadScreen({required this.threadId, super.key});

  final String threadId;

  @override
  State<AccountThreadScreen> createState() => _AccountThreadScreenState();
}

class _AccountThreadScreenState extends State<AccountThreadScreen> {
  bool _started = false;
  bool _ready = false;
  bool _failed = false;
  bool _closed = false;
  bool _sending = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _cursor;
  String _title = 'Messages';
  String _subtitle = 'Bayan ng Taytay · Rizal';
  String _ownerAccountId = '';
  String? _error;
  String? _pageError;
  String? _mediaId;
  OutgoingFile? _file;
  List<OfficeMessage> _messages = const <OfficeMessage>[];
  final TextEditingController _composer = TextEditingController();

  /// Kept across every retry of the same words and attachment.
  final SendKey _sendKey = SendKey();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    final Result<OfficeThread> thread = await dependencies
        .officeMessagingRepository
        .loadThread(widget.threadId);
    final Result<Paginated<OfficeMessage>> messages = await dependencies
        .officeMessagingRepository
        .listMessages(widget.threadId);
    if (thread is Ok<OfficeThread>) {
      await dependencies.officeMessagingRepository.markThreadRead(
        widget.threadId,
      );
    }
    if (!mounted) return;
    setState(() {
      _ready = true;
      var failed = false;
      String? error;
      if (thread case Ok(:final value)) {
        _title = value.officeName;
        _subtitle = value.topic.isEmpty
            ? 'Bayan ng Taytay · Rizal'
            : value.topic;
        _ownerAccountId = value.ownerAccountId;
        _closed = value.status == 'closed';
      } else if (thread case Err(:final failure)) {
        failed = true;
        error = failure.residentMessage;
      }
      if (messages case Ok(:final value)) {
        _messages = _uniqueMessages(value.items.reversed.toList());
        _remember(value);
      } else if (messages case Err(:final failure)) {
        failed = true;
        error ??= failure.residentMessage;
      }
      _failed = failed;
      _error = error;
    });
  }

  Future<void> _loadOlder() async {
    final String? cursor = _cursor;
    if (_loadingMore || !_hasMore || cursor == null || _failed) return;
    setState(() {
      _loadingMore = true;
      _pageError = null;
    });
    final result = await AppDependencies.of(
      context,
    ).officeMessagingRepository.listMessages(widget.threadId, cursor: cursor);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (result case Ok(:final value)) {
        final Set<String> seen = _messages
            .map((OfficeMessage m) => m.id)
            .toSet();
        final List<OfficeMessage> older = <OfficeMessage>[
          for (final OfficeMessage message in value.items.reversed)
            if (seen.add(message.id)) message,
        ];
        _messages = <OfficeMessage>[...older, ..._messages];
        _remember(value);
        _pageError = null;
      } else if (result case Err(:final failure)) {
        _pageError = failure.residentMessage;
      }
    });
  }

  List<OfficeMessage> _uniqueMessages(List<OfficeMessage> messages) {
    final Set<String> seen = <String>{};
    return <OfficeMessage>[
      for (final OfficeMessage message in messages)
        if (seen.add(message.id)) message,
    ];
  }

  void _remember(Paginated<OfficeMessage> page) {
    final String? next = page.nextCursor;
    _cursor = next;
    _hasMore = page.hasMore && next != null && next.isNotEmpty;
  }

  Future<void> _attach() async {
    final DocumentPicker picker = AppDependencies.of(context).documentPicker;
    const UploadPolicy policy = UploadPolicy.fallback;
    if (!picker.supports(DocumentSource.file)) {
      setState(() => _error = 'This phone cannot attach a file.');
      return;
    }
    final CapturedDocument? picked = await picker.pick(
      DocumentSource.file,
      policy,
    );
    if (!mounted || picked == null) return;
    final DocumentRejection? rejection = DocumentCapturePolicy.inspect(
      picked,
      policy,
    );
    if (rejection != null) {
      final String message = localisedDocumentRejection(
        context,
        rejection,
        actualBytes: picked.sizeBytes,
        policy: policy,
      );
      setState(() => _error = message);
      return;
    }
    setState(() {
      _file = OutgoingFile(
        bytes: picked.bytes,
        fileName: picked.fileName,
        mimeType: picked.mimeType,
      );
      _mediaId = null;
      _error = null;
    });
  }

  void _useMedia(String mediaId) {
    setState(() {
      _mediaId = mediaId;
      _file = null;
      _error = null;
    });
  }

  Future<void> _send() async {
    if (_sending || _closed || _failed || !_ready) return;
    final String body = _composer.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Write a message before sending.');
      return;
    }
    setState(() => _sending = true);
    final OutgoingFile? file = _file;
    final String? mediaId = file == null ? _mediaId : null;
    // The same reply keeps its key, so one whose answer was lost posts once
    // however often it is repeated. Other words or another attachment are a
    // new reply: the server refuses an old key on them.
    final String key = _sendKey.takeFor((widget.threadId, body, file, mediaId));
    final result = await AppDependencies.of(context).officeMessagingRepository
        .reply(
          threadId: widget.threadId,
          body: body,
          idempotencyKey: key,
          mediaId: mediaId,
          file: file,
        );
    _sendKey.settle(result);
    if (!mounted) {
      _sending = false;
      return;
    }
    switch (result) {
      case Ok(:final value):
        setState(() {
          _sending = false;
          final Set<String> seen = _messages
              .map((OfficeMessage message) => message.id)
              .toSet();
          final OfficeMessage sent = value.asFromResident();
          _messages = <OfficeMessage>[
            ..._messages,
            if (seen.add(sent.id)) sent,
          ];
          _composer.clear();
          _file = null;
          _mediaId = null;
          _error = null;
        });
      case Err(:final failure):
        setState(() {
          _sending = false;
          if (failure is ConflictFailure) _closed = true;
          _error = messageSendFailure(failure, act: MessageAct.reply);
        });
    }
  }

  Future<void> _openMenu() async {
    final String title = _title;
    await AppSheet.show<void>(
      context: context,
      title: title,
      builder: (BuildContext sheetContext) {
        return _CloseConversationAction(
          onTap: () {
            Navigator.of(sheetContext).pop();
            unawaited(_close());
          },
        );
      },
    );
  }

  Future<void> _close() async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Close this conversation?',
      message:
          'The office will see it as closed. You can start a new message afterwards.',
      confirmLabel: 'Close conversation',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final result = await AppDependencies.of(
      context,
    ).officeMessagingRepository.closeThread(widget.threadId);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() {
          _closed = true;
          _file = null;
          _mediaId = null;
          _error = null;
        });
      case Err(:final failure):
        setState(() {
          if (failure is ConflictFailure) _closed = true;
          _error = failure.residentMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final bool mock = dependencies.config.usesMockData;
    final String? accountId =
        dependencies.session.state.residentOrNull?.accountId;
    final bool ownsOpenThread =
        _ready &&
        !_failed &&
        !_closed &&
        accountId != null &&
        accountId.isNotEmpty &&
        _ownerAccountId.isNotEmpty &&
        _ownerAccountId == accountId;
    final bool showComposer = _ready && !_failed && !_closed;
    final String? label = showComposer
        ? (_file?.fileName ?? (_mediaId == null ? null : 'Attachment'))
        : null;
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: Column(
        children: <Widget>[
          Expanded(
            child: AccountCanvas(
              frame: AccountFrame.thread,
              title: _title,
              subtitle: _subtitle,
              subtitleLines: _subtitle.length > 42 ? 2 : 1,
              showBack: true,
              showBell: false,
              onBack: () => context.goNamed(AppRoute.messagesInbox.routeName),
              showSampleNote: mock,
              bubbles: <AccountBubble>[
                for (final OfficeMessage message in _messages)
                  AccountBubble(
                    body: message.body,
                    when: ManilaTime.formatTime(message.sentAt),
                    fromResident:
                        message.fromResident ||
                        (accountId != null &&
                            accountId.isNotEmpty &&
                            message.senderId == accountId),
                    mediaIds: <String>[
                      for (final MessageAttachment attachment
                          in message.attachments)
                        attachment.mediaId,
                    ],
                  ),
              ],
              dayLabel: '',
              composer: showComposer ? _composer : null,
              onAttach: showComposer ? _attach : null,
              onSend: showComposer && !_sending ? _send : null,
              sendEnabled: !_sending,
              onThreadMenu: ownsOpenThread ? _openMenu : null,
              threadClosed: _ready && _closed && !_failed,
              hideComposer: !showComposer && !(_ready && _closed && !_failed),
              attachmentLabel: label,
              onClearAttachment: label == null
                  ? null
                  : () => setState(() {
                      _file = null;
                      _mediaId = null;
                    }),
              onUseMedia: showComposer ? _useMedia : null,
              onThreadNearStart: _ready && !_failed ? _loadOlder : null,
              threadMoreMessage: _pageError,
              onThreadMoreRetry: _pageError == null ? null : _loadOlder,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.danger,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One destructive row in the thread menu.
class _CloseConversationAction extends StatelessWidget {
  const _CloseConversationAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close conversation',
      child: GestureDetector(
        key: const Key('account-thread-close'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(
          height: 48,
          child: Row(
            children: <Widget>[
              TaytayIcon(
                icon: TaytayIcons.circleX,
                size: 20,
                color: BrandColors.danger,
                semanticLabel: '',
                excludeSemantics: true,
              ),
              SizedBox(width: 12),
              Text(
                'Close conversation',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.danger,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Correctable profile fields. Legal name changes stay on the resident record.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _started = false;
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  String _mobileOriginal = '';
  String _emailOriginal = '';
  String _barangay = '';
  String? _barangayId;
  String? _barangayIdOriginal;
  List<Barangay> _barangays = const <Barangay>[];
  bool _emailVerified = false;
  String? _idempotencyKey;

  @override
  void dispose() {
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    final result = await dependencies.residentProfileRepository.loadOwnDetail();
    if (!mounted) return;
    if (result case Ok(:final value)) {
      final String mobile =
          value.valueOf(ResidentProfileField.mobileNumber) ?? '';
      final String email =
          value.valueOf(ResidentProfileField.emailAddress) ?? '';
      _mobile.text = mobile;
      _email.text = email;
      _mobileOriginal = mobile.trim();
      _emailOriginal = email.trim();
      setState(() {
        _barangay = value.valueOf(ResidentProfileField.barangay) ?? '';
        _emailVerified = value.emailVerified;
      });
    }
    final Result<List<Barangay>> barangays = await dependencies
        .barangayDirectory
        .listBarangays();
    if (!mounted) return;
    if (barangays case Ok(:final value)) {
      setState(() {
        _barangays = value;
        for (final Barangay barangay in value) {
          if (barangay.name == _barangay) _barangayId = barangay.id;
        }
        _barangayIdOriginal = _barangayId;
      });
    }
  }

  Future<void> _pickBarangay() async {
    if (_barangays.isEmpty) return;
    final Barangay? picked = await showDialog<Barangay>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Barangay'),
          children: <Widget>[
            for (final Barangay barangay in _barangays)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(barangay),
                child: Text(barangay.name),
              ),
          ],
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _barangay = picked.name;
      _barangayId = picked.id;
    });
  }

  Future<void> _save() async {
    final Map<String, Object?> changes = <String, Object?>{};
    final String mobile = _mobile.text.trim();
    final String email = _email.text.trim();
    if (mobile != _mobileOriginal) changes['mobile'] = mobile;
    if (email != _emailOriginal) changes['email'] = email;
    if (_barangayId != null && _barangayId != _barangayIdOriginal) {
      changes['barangay_id'] = _barangayId;
    }
    // ProfilePatch.name is the legal name. There is no display-name field.
    if (changes.isEmpty) {
      await AppDialog.acknowledge(
        context: context,
        title: 'Nothing was changed',
        message: 'Your profile was not updated. You can try again.',
      );
      return;
    }
    if (!mounted) return;
    final dependencies = AppDependencies.of(context);
    _idempotencyKey ??= DateTime.now().microsecondsSinceEpoch.toString();
    final result = await dependencies.residentProfileRepository.submitOwnUpdate(
      changes: changes,
      idempotencyKey: _idempotencyKey!,
    );
    if (!mounted) return;
    if (result case Err<void>(:final AppFailure failure)) {
      // `PATCH /me` sets each value outright, so saving again is safe. After
      // a timeout the office may already hold the change: keep the key, and
      // do not say nothing changed.
      if (failure.outcomeUnknown) {
        await AppDialog.acknowledge(
          context: context,
          title: 'Not confirmed yet',
          message:
              'We could not confirm that your profile was updated. Saving '
              'again is safe: the same change is sent again.',
        );
        return;
      }
      _idempotencyKey = null;
      await AppDialog.acknowledge(
        context: context,
        title: 'Nothing was changed',
        message: 'Your profile was not updated. You can try again.',
      );
      return;
    }
    if (!mounted) return;
    context.goNamed(AppRoute.profile.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return AccountCanvas(
      frame: AccountFrame.editProfile,
      title: 'Edit profile',
      showBack: true,
      showBell: false,
      onBack: () => context.goNamed(AppRoute.profile.routeName),
      onLegalName: () => context.goNamed(AppRoute.profileRecord.routeName),
      fields: <AccountField>[
        AccountField(
          label: 'Mobile number',
          value: _mobile.text,
          controller: _mobile,
        ),
        AccountField(
          label: 'Email',
          value: _email.text,
          controller: _email,
          verified: _emailVerified,
        ),
        AccountField(
          label: 'Barangay',
          value: _barangay,
          chevron: true,
          onTap: _pickBarangay,
        ),
      ],
      onSave: _save,
    );
  }
}

/// Notification, language and privacy rows.
///
/// Balita and emergency are `in_app` and `push` preferences. The row writes
/// both. An absent row is on.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _started = false;
  bool _officeReplies = true;
  bool _balita = true;
  bool _emergency = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final result = await AppDependencies.of(
      context,
    ).notificationRepository.loadPreferences();
    if (!mounted) return;
    if (result case Ok(:final value)) {
      setState(() {
        _officeReplies = preferenceEnabled(value.channels, 'message_received');
        _balita = preferenceEnabled(value.channels, 'balita');
        _emergency = preferenceEnabled(value.channels, 'emergency');
      });
    }
  }

  Future<void> _setChannel(
    String type,
    bool on, {
    required bool pushOnly,
    required void Function(bool value) apply,
  }) async {
    final dependencies = AppDependencies.of(context);
    final Result<NotificationPreferences> loaded = await dependencies
        .notificationRepository
        .loadPreferences();
    if (!mounted || loaded is Err<NotificationPreferences>) return;
    final NotificationPreferences current =
        (loaded as Ok<NotificationPreferences>).value;
    final List<ChannelPreference> channels = writePreference(
      current.channels,
      type: type,
      on: on,
      pushOnly: pushOnly,
    );
    setState(() => apply(on));
    final Result<void> saved = await dependencies.notificationRepository
        .updatePreferences(current.copyWith(channels: channels));
    if (!mounted) return;
    if (saved is Err<void>) setState(() => apply(!on));
  }

  @override
  Widget build(BuildContext context) {
    return AccountCanvas(
      frame: AccountFrame.settings,
      title: 'Settings & privacy',
      showBack: true,
      showBell: false,
      onBack: () => context.goNamed(AppRoute.profile.routeName),
      toggles: <AccountToggle>[
        AccountToggle(
          title: 'Balita & advisories',
          subtitle: 'Push notifications',
          icon: TaytayIcons.bell,
          tile: BrandColors.chipBlueBg,
          iconColor: BrandColors.taytayBlue,
          on: _balita,
          onChanged: (bool on) => _setChannel(
            'balita',
            on,
            pushOnly: false,
            apply: (bool value) => _balita = value,
          ),
        ),
        AccountToggle(
          title: 'Office replies',
          subtitle: 'Push notifications',
          icon: TaytayIcons.messageSquare,
          tile: BrandColors.chipBlueBg,
          iconColor: BrandColors.taytayBlue,
          on: _officeReplies,
          onChanged: (bool on) => _setChannel(
            'message_received',
            on,
            pushOnly: true,
            apply: (bool value) => _officeReplies = value,
          ),
        ),
        AccountToggle(
          title: 'Emergency alerts',
          subtitle: 'Push notifications',
          icon: TaytayIcons.siren,
          tile: BrandColors.chipRedBg,
          iconColor: BrandColors.danger,
          on: _emergency,
          onChanged: (bool on) => _setChannel(
            'emergency',
            on,
            pushOnly: false,
            apply: (bool value) => _emergency = value,
          ),
        ),
      ],
      changePasswordSubtitle: '',
      showDataExport: false,
      onLanguage: () => AppDialog.acknowledge(
        context: context,
        title: 'Language',
        message: 'The app follows the language of this phone.',
      ),
      onChangePassword: () => _changePassword(context),
      onPrivacy: () => context.goNamed(AppRoute.profileNotice.routeName),
      onConsents: () => context.pushNamed(AppRoute.privacyControls.routeName),
    );
  }
}

Future<void> _changePassword(BuildContext context) async {
  final AccountPasswordClient client = AppDependencies.of(
    context,
  ).accountPasswordClient;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        scrollable: true,
        title: const Text('Change password'),
        content: ChangePasswordForm(
          client: client,
          onDone: () {
            Navigator.of(dialogContext).pop();
            AppDialog.acknowledge(
              context: context,
              title: 'Password updated',
              message: 'Use the new password the next time you sign in.',
            );
          },
        ),
      );
    },
  );
}

/// RA 10173 notice. The bundled draft stands in until `GET /app/config`
/// publishes a privacy notice whose version is not `placeholder`.
class PrivacyNoticeScreen extends StatefulWidget {
  const PrivacyNoticeScreen({super.key});

  @override
  State<PrivacyNoticeScreen> createState() => _PrivacyNoticeScreenState();
}

class _PrivacyNoticeScreenState extends State<PrivacyNoticeScreen> {
  bool _started = false;
  bool _ready = false;
  String? _markdown;
  bool _draft = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    final bool production = dependencies.config.environment.isProduction;
    final result = await dependencies.platformRepository.loadBootstrap();
    if (!mounted) return;
    setState(() {
      _ready = true;
      if (result case Ok(:final value)) {
        final notice = value.privacyNotice;
        if (!notice.usesBundledDraft) {
          _markdown = notice.bodyMarkdown;
        } else if (!production) {
          _draft = true;
        }
      } else if (!production) {
        _draft = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const ColoredBox(
        color: BrandColors.surface,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AccountCanvas(
      frame: AccountFrame.privacy,
      title: 'Privacy Notice',
      showBack: true,
      showBell: false,
      onBack: () => context.goNamed(AppRoute.profile.routeName),
      showDataExport: false,
      showBundledDraft: _draft,
      noticeMarkdown: _markdown,
    );
  }
}

/// About and the welcome-photo credits.
class PhotoCreditsScreen extends StatelessWidget {
  const PhotoCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountCanvas(
      frame: AccountFrame.about,
      title: 'Photo credits & about',
      showBack: true,
      showBell: false,
      onBack: () => context.goNamed(AppRoute.profile.routeName),
      onBanners: () => context.goNamed(AppRoute.profileBanners.routeName),
    );
  }
}

/// Office-banner credits. Every bundled office photograph is in the list.
class OfficeBannersScreen extends StatelessWidget {
  const OfficeBannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountCanvas(
      frame: AccountFrame.banners,
      title: 'Office banner photos',
      showBack: true,
      showBell: false,
      onBack: () => context.goNamed(AppRoute.photoCredits.routeName),
    );
  }
}
