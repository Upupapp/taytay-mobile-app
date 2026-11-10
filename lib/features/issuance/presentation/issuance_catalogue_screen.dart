import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../shared/widgets/header_search_field.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/issuance_terms.dart';
import '../domain/issuance_type.dart';
import 'issuance_widgets.dart';

/// The documents the municipal offices issue, grouped by office.
///
/// Public, like the API's own catalogue. A guest or an unverified resident
/// reads it with a notice saying what it takes to send a request; nothing is
/// hidden from them.
///
/// Drawn as the `List + search + filters` pattern (Directory.dc): the blue
/// header with the back control and, once the list is long, the search field;
/// the documents as soft lists under each office's name.
class IssuanceCatalogueScreen extends StatefulWidget {
  const IssuanceCatalogueScreen({super.key});

  /// From this many types up, the list gets a search field.
  static const int searchFrom = 8;

  @override
  State<IssuanceCatalogueScreen> createState() =>
      _IssuanceCatalogueScreenState();
}

class _IssuanceCatalogueScreenState extends State<IssuanceCatalogueScreen> {
  bool _started = false;
  bool _loading = true;
  AppFailure? _failure;
  List<IssuanceType> _types = const <IssuanceType>[];
  final TextEditingController _search = TextEditingController();

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
    setState(() {
      _loading = true;
      _failure = null;
    });
    final Result<List<IssuanceType>> result = await AppDependencies.of(
      context,
    ).issuanceRepository.listTypes();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _types = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  bool get _searchable => _types.length >= IssuanceCatalogueScreen.searchFrom;

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependencies.of(context);
    return IssuanceScaffold(
      title: 'Request documents',
      bottom: _failure == null && _searchable
          ? HeaderSearchField(
              fieldKey: const Key('issuance-search'),
              hint: 'Search documents',
              controller: _search,
              onChanged: (_) => setState(() {}),
            )
          : null,
      body: AnimatedBuilder(
        animation: dependencies.session,
        builder: (BuildContext context, Widget? _) {
          final AccessDecision decision = AccessPolicy.evaluate(
            session: dependencies.session.state,
            requirement: AccessRequirement.verified,
          );
          final bool signedIn =
              AccessPolicy.evaluate(
                    session: dependencies.session.state,
                    requirement: AccessRequirement.authenticated,
                  )
                  is AccessAllowed;
          final AppFailure? failure = _failure;
          if (failure != null) {
            return IssuanceLoadFailure(
              failure: failure,
              onRetry: _load,
              what: 'the documents',
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: issuanceListPadding(context),
              children: <Widget>[
                IssuanceAccessNotice(decision: decision),
                if (signedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.section),
                    child: SettingsList(
                      children: <Widget>[
                        SettingsRow(
                          key: const Key('issuance-my-requests'),
                          title: 'My document requests',
                          detail: 'Follow what you have sent',
                          leading: const IconTile.lucide(
                            icon: TaytayIcons.inbox,
                            tone: TileTone.navy,
                          ),
                          onTap: () => context.pushNamed(
                            AppRoute.issuanceRequests.routeName,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(bottom: Spacing.section),
                  child: IssuanceText(
                    'Certificates and certified copies the municipal offices '
                    'issue. Choose one to see what it needs. Any fee is paid '
                    'at the office, never in the app.',
                  ),
                ),
                if (_loading && _types.isEmpty)
                  const LoadingSkeleton(semanticLabel: 'Loading documents')
                else if (_types.isEmpty)
                  const EmptyState(
                    title: 'No documents listed yet',
                    message:
                        'The municipal offices have not listed any documents '
                        'in the app yet. You can still ask at the Municipal '
                        'Hall.',
                    boxed: true,
                  )
                else
                  ..._catalogue(context),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _catalogue(BuildContext context) {
    final List<IssuanceType> shown = _searchable
        ? searchTypes(_types, _search.text)
        : _types;
    return <Widget>[
      if (shown.isEmpty)
        const EmptyState(
          title: 'No document matches',
          message: 'Try another word, or clear the search to see them all.',
          boxed: true,
        ),
      for (final (String office, List<IssuanceType> types) in groupByOffice(
        shown,
      )) ...<Widget>[
        SettingsSectionTitle(office),
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.section),
          child: SettingsList(
            children: <Widget>[
              for (final IssuanceType type in types)
                SettingsRow(
                  key: Key('issuance-type-${type.id}'),
                  title: type.name,
                  detail:
                      '${issuanceFeeLine(type.feeCentavos)} · '
                      '${issuanceProcessingLine(type.processingDays)}',
                  leading: const IconTile.glyph(glyph: TaytayGlyph.document),
                  onTap: () => context.pushNamed(
                    AppRoute.issuanceType.routeName,
                    pathParameters: <String, String>{'typeId': type.id},
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }
}
