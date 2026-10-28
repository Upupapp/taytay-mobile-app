import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../messaging/domain/office_messaging_repository.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../../tulong/domain/social_service.dart';
import '../data/office_api_repository.dart';
import '../data/office_catalogue.dart';
import '../domain/office.dart';
import 'directory_canvas.dart';

/// The Directory tab: the public office list.
class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  List<Office> _offices = const <Office>[];
  List<String> _chips = const <String>[];
  bool _loading = true;
  bool _offline = false;
  bool _started = false;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AppDependencies dependencies = AppDependencies.of(context);
    try {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load(
            mock: dependencies.config.usesMockData,
            api: dependencies.apiClient,
          );
      if (!mounted) return;
      setState(() {
        _offices = catalogue.offices;
        _chips = catalogue.chips;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: DirectoryCanvas(
        frame: _offline
            ? DirectoryFrame.offline
            : _loading
            ? DirectoryFrame.loading
            : DirectoryFrame.list,
        offices: _offices,
        chips: _chips,
        query: _query,
        searchController: _search,
        onSearch: (String value) => setState(() => _query = value),
        onOffice: (Office office) => context.pushNamed(
          AppRoute.officeDetail.routeName,
          pathParameters: <String, String>{'officeId': office.id},
        ),
        onRetry: _load,
      ),
    );
  }
}

/// One office page. The same screen paints every office.
class OfficeDetailScreen extends StatefulWidget {
  const OfficeDetailScreen({required this.officeId, super.key});

  final String officeId;

  @override
  State<OfficeDetailScreen> createState() => _OfficeDetailScreenState();
}

class _OfficeDetailScreenState extends State<OfficeDetailScreen> {
  Office? _office;
  Uint8List? _heroBytes;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final AppDependencies dependencies = AppDependencies.of(context);
    final bool mock = dependencies.config.usesMockData;
    final Office? office = await OfficeCatalogue.byId(
      widget.officeId,
      mock: mock,
      api: dependencies.apiClient,
    );
    if (!mounted) return;
    // The hall is the placeholder. The page does not wait on the banner or
    // the office's Tulong list.
    setState(() => _office = office);
    if (office == null || mock) return;
    final Future<List<SocialService>> catalogueFuture = _catalogue(
      dependencies,
      office.id,
    );
    final Future<Uint8List?> heroFuture = _hero(dependencies, office);
    final List<SocialService> catalogue = await catalogueFuture;
    final Uint8List? hero = await heroFuture;
    if (!mounted) return;
    final List<OfficeServiceLine> lines = office
        .linesWithCatalogue(<({String label, String slug})>[
          for (final SocialService service in catalogue)
            (label: service.name, slug: service.slug),
        ]);
    setState(() {
      _heroBytes = hero;
      _office = identical(lines, office.services)
          ? office
          : office.withServices(lines);
    });
  }

  /// Bytes only when the read succeeds and is non-empty. A 404, a 5xx, or a
  /// missing URL leaves the hall in place.
  Future<Uint8List?> _hero(AppDependencies dependencies, Office office) async {
    if (office.heroUrl == null) return null;
    final Result<Uint8List> bytes = await OfficeApiRepository(
      apiClient: dependencies.apiClient,
    ).loadHero(office.id);
    return switch (bytes) {
      Ok(:final value) when value.isNotEmpty => value,
      _ => null,
    };
  }

  Future<List<SocialService>> _catalogue(
    AppDependencies dependencies,
    String slug,
  ) async {
    final result = await dependencies.socialServiceRepository.listServices(
      office: slug,
    );
    return switch (result) {
      Ok(:final value) => value.items,
      Err() => const <SocialService>[],
    };
  }

  Future<void> _message() async {
    final Office? office = _office;
    if (office == null || !office.messageable) return;
    final AccessDecision decision = AccessPolicy.evaluate(
      session: AppDependencies.of(context).session.state,
      requirement: ResidentIntentKind.messageOffice.requirement,
    );
    if (decision is! AccessAllowed) {
      // A guest goes to sign-in. The verification sheet is only for a
      // signed-in resident the LGU has not confirmed.
      await AccessGateSheet.show(
        context: context,
        decision: decision,
        intent: ResidentIntentKind.messageOffice,
        targetId: office.id,
      );
      return;
    }
    if (!mounted) return;
    unawaited(
      context.pushNamed(
        AppRoute.officeCompose.routeName,
        pathParameters: <String, String>{'officeId': office.id},
      ),
    );
  }

  Future<void> _dial() async {
    final String phone = _office?.phone ?? '';
    if (phone.isEmpty) return;
    await AppDependencies.of(context).externalLinks.dial(phone);
  }

  Future<void> _directions() async {
    final String query = _office?.directionsQuery ?? '';
    if (query.isEmpty) return;
    final String url = Uri.https(
      'www.google.com',
      '/maps/search/',
      <String, String>{'api': '1', 'query': query},
    ).toString();
    await AppDependencies.of(context).externalLinks.open(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: DirectoryCanvas(
        frame: DirectoryFrame.detail,
        offices: const <Office>[],
        office: _office,
        heroBytes: _heroBytes,
        onBack: () => _back(context),
        onCall: _dial,
        onDirections: _directions,
        onMessage: _message,
        onApp: _dial,
        onServiceLine: (String slug) {
          context.pushNamed(
            AppRoute.programDetail.routeName,
            pathParameters: <String, String>{'programId': slug},
          );
        },
      ),
    );
  }
}

class OfficeComposeScreen extends StatefulWidget {
  const OfficeComposeScreen({required this.officeId, super.key});

  final String officeId;

  @override
  State<OfficeComposeScreen> createState() => _OfficeComposeScreenState();
}

class _OfficeComposeScreenState extends State<OfficeComposeScreen> {
  Office? _office;
  String? _error;
  String _topic = '';
  bool _started = false;
  final TextEditingController _message = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final AppDependencies dependencies = AppDependencies.of(context);
    OfficeCatalogue.byId(
      widget.officeId,
      mock: dependencies.config.usesMockData,
      api: dependencies.apiClient,
    ).then((Office? office) {
      if (!mounted || office == null) return;
      setState(() {
        _office = office;
        _topic = office.topics.isNotEmpty
            ? office.topics.first
            : (office.topic ?? '');
      });
    });
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickTopic() async {
    final Office? office = _office;
    if (office == null || office.topics.isEmpty) return;
    final String? chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final String topic in office.topics)
                ListTile(
                  title: Text(topic),
                  onTap: () => Navigator.of(sheetContext).pop(topic),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;
    setState(() => _topic = chosen);
  }

  Future<void> _send() async {
    final Office? office = _office;
    if (office == null) return;
    final String body = _message.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Write a message before sending.');
      return;
    }
    if (_topic.trim().isEmpty) {
      setState(() => _error = 'Choose a topic before sending.');
      return;
    }
    final AppDependencies dependencies = AppDependencies.of(context);
    final result = await dependencies.officeMessagingRepository.send(
      officeId: office.wireId,
      topic: _topic,
      body: body,
    );
    if (!mounted) return;
    switch (result) {
      case Ok():
        unawaited(
          context.pushNamed(
            AppRoute.officeMessageSent.routeName,
            pathParameters: <String, String>{'officeId': office.id},
          ),
        );
      case Err(:final failure):
        if (failure is ForbiddenFailure) {
          await _applyTierAfterForbidden(dependencies, office, failure);
          return;
        }
        setState(() => _error = failure.residentMessage);
    }
  }

  Future<void> _applyTierAfterForbidden(
    AppDependencies dependencies,
    Office office,
    AppFailure failure,
  ) async {
    final Result<ResidentProfileDetail> me = await dependencies
        .residentProfileRepository
        .loadOwnDetail();
    if (!mounted) return;
    if (me case Ok(:final value)) {
      final String? tier = value.verificationTier;
      if (AccessLevel.fromVerificationTier(tier) != AccessLevel.verified) {
        // Leave the verified-only compose route before the session drops.
        // Otherwise the guard replaces this screen and the sheet never lands.
        GoRouter.of(context).goNamed(
          AppRoute.officeDetail.routeName,
          pathParameters: <String, String>{'officeId': office.id},
        );
        if (tier != null && tier.isNotEmpty) {
          dependencies.session.applyVerificationTier(tier);
        }
        if (!context.mounted) return;
        await AccessGateSheet.show(
          context: context,
          decision: const AccessNeedsVerification(),
          intent: ResidentIntentKind.messageOffice,
          targetId: office.id,
        );
        return;
      }
      if (tier != null && tier.isNotEmpty) {
        dependencies.session.applyVerificationTier(tier);
      }
    }
    if (!mounted) return;
    setState(() => _error = failure.residentMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: Column(
        children: <Widget>[
          Expanded(
            child: DirectoryCanvas(
              frame: DirectoryFrame.compose,
              offices: const <Office>[],
              office: _office,
              messageController: _message,
              selectedTopic: _topic,
              onTopic: _pickTopic,
              onBack: () => _back(context),
              onSend: _send,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB3261E),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MessageSentScreen extends StatefulWidget {
  const MessageSentScreen({required this.officeId, super.key})
    : assert(officeId != '', 'officeId is required');

  final String officeId;

  @override
  State<MessageSentScreen> createState() => _MessageSentScreenState();
}

class _MessageSentScreenState extends State<MessageSentScreen> {
  String _phone = '';
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final AppDependencies dependencies = AppDependencies.of(context);
    OfficeCatalogue.byId(
      widget.officeId,
      mock: dependencies.config.usesMockData,
      api: dependencies.apiClient,
    ).then((Office? office) {
      if (mounted) setState(() => _phone = office?.phone ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: DirectoryCanvas(
        frame: DirectoryFrame.sent,
        offices: const <Office>[],
        emergencyPhone: _phone,
        onBack: () => context.goNamed(AppRoute.services.routeName),
        onMessages: () => context.goNamed(AppRoute.messagesInbox.routeName),
      ),
    );
  }
}

class OfficeThreadScreen extends StatefulWidget {
  const OfficeThreadScreen({required this.threadId, super.key});

  final String threadId;

  @override
  State<OfficeThreadScreen> createState() => _OfficeThreadScreenState();
}

class _OfficeThreadScreenState extends State<OfficeThreadScreen> {
  Office? _office;
  List<DirectoryThreadBubble> _bubbles = const <DirectoryThreadBubble>[];
  String _dayLabel = '';
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final AppDependencies dependencies = AppDependencies.of(context);
    final Result<OfficeThread> thread = await dependencies
        .officeMessagingRepository
        .loadThread(widget.threadId);
    final Result<List<OfficeMessage>> messages = await dependencies
        .officeMessagingRepository
        .listMessages(widget.threadId);
    if (!mounted) return;
    final OfficeThread? loaded = switch (thread) {
      Ok(:final value) => value,
      Err() => null,
    };
    final String slug = loaded == null
        ? ''
        : (loaded.officeSlug.isNotEmpty ? loaded.officeSlug : loaded.officeId);
    final Office? office = slug.isEmpty
        ? null
        : await OfficeCatalogue.byId(
            slug,
            mock: dependencies.config.usesMockData,
            api: dependencies.apiClient,
          );
    if (!mounted) return;
    final String? accountId =
        dependencies.session.state.residentOrNull?.accountId;
    final List<OfficeMessage> rows = switch (messages) {
      Ok(:final value) => value.reversed.toList(growable: false),
      Err() => const <OfficeMessage>[],
    };
    setState(() {
      _office =
          office ??
          (loaded == null
              ? null
              : Office(
                  id: slug,
                  serverId: loaded.officeId,
                  shortName: loaded.officeName,
                  name: loaded.officeName,
                  listName: loaded.officeName,
                  category: '',
                  listLine: '',
                  icon: OfficeIcon.building2,
                  keywords: const <String>[],
                  eyebrow: '',
                  summary: '',
                  heroAsset: 'assets/photos/municipal_hall.jpg',
                  heroFocus: 0.5,
                  insetAsset: 'assets/photos/municipal_hall.jpg',
                  representative: false,
                  credit: '',
                  messageable: true,
                  callLabel: 'Call',
                  callIsEmergency: false,
                  phone: '',
                  directionsQuery: '',
                  facts: const <OfficeFact>[],
                  services: const <OfficeServiceLine>[],
                ));
      _bubbles = <DirectoryThreadBubble>[
        for (final OfficeMessage message in rows)
          DirectoryThreadBubble(
            fromResident:
                message.fromResident ||
                (accountId != null &&
                    accountId.isNotEmpty &&
                    message.senderId == accountId),
            when: ManilaTime.formatTime(message.sentAt),
            body: message.body,
          ),
      ];
      _dayLabel = rows.isEmpty ? '' : ManilaTime.formatDate(rows.first.sentAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: DirectoryCanvas(
        frame: DirectoryFrame.thread,
        offices: const <Office>[],
        office: _office,
        bubbles: _bubbles,
        dayLabel: _dayLabel,
        onBack: () => _back(context),
      ),
    );
  }
}

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.goNamed(AppRoute.services.routeName);
}
