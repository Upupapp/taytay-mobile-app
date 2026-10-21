import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
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

  @override
  void initState() {
    super.initState();
    OfficeCatalogue.byId(widget.officeId).then((Office? office) {
      if (mounted) setState(() => _office = office);
    });
  }

  Future<void> _message() async {
    final Office? office = _office;
    if (office == null || !office.messageable) return;
    final AccessDecision decision = AccessPolicy.evaluate(
      session: AppDependencies.of(context).session.state,
      requirement: ResidentIntentKind.messageOffice.requirement,
    );
    if (decision is! AccessAllowed) {
      await AccessGateSheet.show(
        context: context,
        decision: decision is AccessNeedsAuthentication
            ? const AccessNeedsVerification()
            : decision,
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
        onBack: () => _back(context),
        onCall: _dial,
        onDirections: _directions,
        onMessage: _message,
        onApp: _dial,
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

  @override
  void initState() {
    super.initState();
    OfficeCatalogue.byId(widget.officeId).then((Office? office) {
      if (mounted) setState(() => _office = office);
    });
  }

  Future<void> _send() async {
    final Office? office = _office;
    if (office == null) return;
    final result = await AppDependencies.of(context).officeMessagingRepository
        .send(
          officeId: office.id,
          topic: office.topic ?? office.shortName,
          body: office.draft ?? '',
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
        setState(() => _error = failure.residentMessage);
    }
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

  @override
  void initState() {
    super.initState();
    OfficeCatalogue.byId('mdrrmo').then((Office? office) {
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Office? office = await OfficeCatalogue.byId('bplo');
    final ({String dayLabel, List<DirectoryThreadBubble> messages}) thread =
        await OfficeCatalogue.thread();
    if (!mounted) return;
    setState(() {
      _office = office;
      _bubbles = thread.messages;
      _dayLabel = thread.dayLabel;
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
