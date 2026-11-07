import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/issuance_terms.dart';
import '../domain/issuance_type.dart';
import 'issuance_widgets.dart';

/// The documents the municipal offices issue, grouped by office.
///
/// Public, like the API's own catalogue. A guest or an unverified resident
/// reads it with a notice saying what it takes to send a request; nothing is
/// hidden from them.
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

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependencies.of(context);
    return IssuanceScaffold(
      title: 'Request documents',
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
              padding: s3PagePadding,
              children: <Widget>[
                IssuanceAccessNotice(decision: decision),
                if (signedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: s3CardGap),
                    child: S3Card(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListRow(
                        key: const Key('issuance-my-requests'),
                        title: 'My document requests',
                        subtitle: 'Follow what you have sent',
                        icon: TaytayIcons.inbox,
                        iconLabel: 'Your requests',
                        trailing: const Icon(
                          TaytayIcons.chevronRight,
                          size: 18,
                          color: BrandColors.chevron,
                        ),
                        onTap: () => context.pushNamed(
                          AppRoute.issuanceRequests.routeName,
                        ),
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(bottom: s3CardGap),
                  child: IssuanceText(
                    'Certificates and certified copies the municipal offices '
                    'issue. Choose one to see what it needs. Any fee is paid '
                    'at the office, never in the app.',
                  ),
                ),
                if (_loading && _types.isEmpty)
                  ..._skeleton()
                else if (_types.isEmpty)
                  const EmptyState(
                    title: 'No documents listed yet',
                    message:
                        'The municipal offices have not listed any documents '
                        'in the app yet. You can still ask at the Municipal '
                        'Hall.',
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

  List<Widget> _skeleton() => <Widget>[
    for (var i = 0; i < 3; i++)
      const Padding(
        padding: EdgeInsets.only(bottom: s3CardGap),
        child: SkeletonBlock(height: 72, radius: Radii.lg),
      ),
  ];

  List<Widget> _catalogue(BuildContext context) {
    final bool searchable = _types.length >= IssuanceCatalogueScreen.searchFrom;
    final List<IssuanceType> shown = searchable
        ? searchTypes(_types, _search.text)
        : _types;
    return <Widget>[
      if (searchable)
        Padding(
          padding: const EdgeInsets.only(bottom: s3CardGap),
          child: TextField(
            key: const Key('issuance-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Search documents',
              prefixIcon: Icon(TaytayIcons.search),
            ),
          ),
        ),
      if (shown.isEmpty)
        const EmptyState(
          title: 'No document matches',
          message: 'Try another word, or clear the search to see them all.',
        ),
      for (final (String office, List<IssuanceType> types) in groupByOffice(
        shown,
      )) ...<Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Semantics(
            header: true,
            child: Text(
              office,
              style: s3Type(13, AppTypography.black, BrandColors.textSecondary),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: s3CardGap),
          child: S3Card(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < types.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1),
                  ListRow(
                    key: Key('issuance-type-${types[i].id}'),
                    title: types[i].name,
                    subtitle:
                        '${issuanceFeeLine(types[i].feeCentavos)} · '
                        '${issuanceProcessingLine(types[i].processingDays)}',
                    icon: TaytayIcons.fileText,
                    iconLabel: 'Document',
                    trailing: const Icon(
                      TaytayIcons.chevronRight,
                      size: 18,
                      color: BrandColors.chevron,
                    ),
                    onTap: () => context.pushNamed(
                      AppRoute.issuanceType.routeName,
                      pathParameters: <String, String>{'typeId': types[i].id},
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ];
  }
}
