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
import 'account_canvas.dart';

/// Office inbox. Verified. The shell keeps the tab bar.
class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  bool _started = false;
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
      _threads = switch (result) {
        Ok(:final value) => value,
        Err() => const <OfficeThread>[],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool empty = _threads.isEmpty;
    return AccountCanvas(
      frame: empty ? AccountFrame.inboxEmpty : AccountFrame.inbox,
      title: 'Messages',
      showBack: true,
      onBack: () => context.goNamed(AppRoute.profile.routeName),
      onBell: () => context.goNamed(AppRoute.notifications.routeName),
      inbox: <AccountInboxRow>[
        for (final OfficeThread thread in _threads)
          AccountInboxRow(
            office: thread.officeName,
            when: '',
            preview: thread.preview,
            icon: TaytayIcons.messageSquare,
            tile: BrandColors.chipBlueBg,
            iconColor: BrandColors.taytayBlue,
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
  String _name = '';
  String _mobile = '';
  String _email = '';
  String _barangay = '';
  String? _barangayId;
  bool _emailVerified = false;
  String? _idempotencyKey;

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
      setState(() {
        _name = value.valueOf(ResidentProfileField.fullName) ?? '';
        _mobile = value.valueOf(ResidentProfileField.mobileNumber) ?? '';
        _email = value.valueOf(ResidentProfileField.emailAddress) ?? '';
        _barangay = value.valueOf(ResidentProfileField.barangay) ?? '';
        _emailVerified = value.emailVerified;
      });
    }
    final Result<List<Barangay>> barangays = await dependencies
        .barangayDirectory
        .listBarangays();
    if (!mounted) return;
    if (barangays case Ok(:final value)) {
      for (final Barangay barangay in value) {
        if (barangay.name == _barangay) {
          setState(() => _barangayId = barangay.id);
        }
      }
    }
  }

  Future<void> _save() async {
    final dependencies = AppDependencies.of(context);
    _idempotencyKey ??= DateTime.now().microsecondsSinceEpoch.toString();
    final result = await dependencies.residentProfileRepository.submitOwnUpdate(
      changes: <String, Object?>{
        'name': _name,
        'mobile_number': _mobile,
        'email': _email,
        if (_barangayId != null) 'barangay_id': _barangayId,
      },
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
        AccountField(label: 'Display name', value: _name),
        AccountField(label: 'Mobile', value: _mobile),
        AccountField(label: 'Email', value: _email, verified: _emailVerified),
        AccountField(label: 'Barangay', value: _barangay, chevron: true),
      ],
      onSave: _save,
    );
  }
}

/// Notification, language and privacy rows. Balita and emergency are not
/// preference types on the API, so those rows do not write.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _started = false;
  bool _officeReplies = true;

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
      for (final ChannelPreference channel in value.channels) {
        if (channel.type == 'message_received') {
          setState(() => _officeReplies = channel.push);
        }
      }
    }
  }

  Future<void> _setOfficeReplies(bool on) async {
    final dependencies = AppDependencies.of(context);
    final Result<NotificationPreferences> loaded = await dependencies
        .notificationRepository
        .loadPreferences();
    if (!mounted || loaded is Err<NotificationPreferences>) return;
    final NotificationPreferences current =
        (loaded as Ok<NotificationPreferences>).value;
    final List<ChannelPreference> channels = <ChannelPreference>[
      for (final ChannelPreference channel in current.channels)
        if (channel.type == 'message_received')
          ChannelPreference(type: channel.type, inApp: channel.inApp, push: on)
        else
          channel,
    ];
    if (!channels.any((ChannelPreference c) => c.type == 'message_received')) {
      channels.add(
        ChannelPreference(type: 'message_received', inApp: true, push: on),
      );
    }
    setState(() => _officeReplies = on);
    final Result<void> saved = await dependencies.notificationRepository
        .updatePreferences(current.copyWith(channels: channels));
    if (!mounted) return;
    if (saved is Err<void>) setState(() => _officeReplies = !on);
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
        const AccountToggle(
          title: 'Balita & advisories',
          subtitle: 'Push notifications',
          icon: TaytayIcons.newspaper,
          tile: BrandColors.chipBlueBg,
          iconColor: BrandColors.taytayBlue,
          on: true,
          locked: true,
        ),
        AccountToggle(
          title: 'Office replies',
          subtitle: 'Push notifications',
          icon: TaytayIcons.messageSquare,
          tile: BrandColors.chipGreenBg,
          iconColor: BrandColors.success,
          on: _officeReplies,
          onChanged: _setOfficeReplies,
        ),
        const AccountToggle(
          title: 'Emergency alerts',
          subtitle: 'Always on for MDRRMO alerts',
          icon: TaytayIcons.siren,
          tile: BrandColors.chipRedBg,
          iconColor: BrandColors.danger,
          on: true,
          locked: true,
        ),
      ],
      onLanguage: () => AppDialog.acknowledge(
        context: context,
        title: 'Language',
        message: 'The app follows the language of this phone.',
      ),
      onChangePassword: () => AppDialog.acknowledge(
        context: context,
        title: 'Change password',
        message:
            'There is no in-session password change. Reset it from the '
            'sign-in screen.',
      ),
      onPrivacy: () => context.goNamed(AppRoute.profileNotice.routeName),
      onExport: () => AppDialog.acknowledge(
        context: context,
        title: 'Request a copy of my data',
        message:
            'A copy of your data is not available from the app yet. Contact '
            'the LGU Data Protection Officer.',
      ),
    );
  }
}

/// RA 10173 notice. Fixed copy, marked draft. It reads nothing.
class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountCanvas(
      frame: AccountFrame.privacy,
      title: 'Privacy Notice',
      showBack: true,
      showBell: false,
      onBack: () => context.goNamed(AppRoute.profile.routeName),
      onExport: () => AppDialog.acknowledge(
        context: context,
        title: 'Request a copy of my data',
        message:
            'A copy of your data is not available from the app yet. Contact '
            'the LGU Data Protection Officer.',
      ),
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
