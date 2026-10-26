import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_dialog.dart';
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
      switch (result) {
        case Ok(:final value):
          _threads = value;
          _failed = false;
        case Err():
          _threads = const <OfficeThread>[];
          _failed = true;
      }
    });
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
      inbox: <AccountInboxRow>[
        for (final OfficeThread thread in _threads)
          AccountInboxRow(
            office: thread.officeName,
            when: '',
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
  String _title = 'Messages';
  String _subtitle = 'Bayan ng Taytay · Rizal';
  List<AccountBubble> _bubbles = const <AccountBubble>[];

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
    final Result<List<OfficeMessage>> messages = await dependencies
        .officeMessagingRepository
        .listMessages(widget.threadId);
    if (!mounted) return;
    final String? accountId =
        dependencies.session.state.residentOrNull?.accountId;
    setState(() {
      if (thread case Ok(:final value)) {
        _title = value.officeName;
        _subtitle = value.topic.isEmpty
            ? 'Bayan ng Taytay · Rizal'
            : value.topic;
      }
      if (messages case Ok(:final value)) {
        _bubbles = <AccountBubble>[
          for (final OfficeMessage message in value)
            AccountBubble(
              body: message.body,
              when: '',
              fromResident:
                  message.fromResident ||
                  (accountId != null &&
                      accountId.isNotEmpty &&
                      message.senderId == accountId),
            ),
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool mock = AppDependencies.of(context).config.usesMockData;
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: AccountCanvas(
        frame: AccountFrame.thread,
        title: _title,
        subtitle: _subtitle,
        subtitleLines: _subtitle.length > 42 ? 2 : 1,
        showBack: true,
        showBell: false,
        onBack: () => context.goNamed(AppRoute.messagesInbox.routeName),
        showSampleNote: mock,
        bubbles: _bubbles,
        dayLabel: '',
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
    if (result is Err<void>) {
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
