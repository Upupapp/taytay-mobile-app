import 'package:flutter/foundation.dart';

import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import 'social_service.dart';

/// Published social services. Information only.
///
/// Live: `GET /services` and `GET /services/{slug}`. A dev mock reads
/// `test/fixtures/mock/tulong_services.json`. There is no apply method.
///
/// **No method takes a search term** (D-59, D-205). `GET /services` accepts
/// `q`, and this app never sends it: Tulong reads the whole catalogue with
/// [readCatalogue] and searches on the phone (`searchServices`).
abstract interface class SocialServiceRepository {
  /// One page of the catalogue.
  ///
  /// [limit] is clamped to 1–50. The spec default is 20.
  /// [featured] sends `featured=true`. That list is the featured services,
  /// including ones hidden from the catalogue. The ordinary list omits
  /// `hidden_from_list`.
  /// [office] is `GET /services?office={slug}`. Empty is omitted.
  Future<Result<Paginated<SocialService>>> listServices({
    int? limit,
    String? cursor,
    bool featured = false,
    String? office,
  });

  /// The whole listed catalogue, every page, for the Tulong tab to search on
  /// the phone.
  ///
  /// A page that fails fails the read: a part of the catalogue is never
  /// handed over as if it were all of it. A catalogue longer than the
  /// app reads ([ServiceCatalogue.complete] false) is returned as far as it
  /// was read, and says so.
  Future<Result<ServiceCatalogue>> readCatalogue();

  Future<Result<SocialService>> loadService(String slug);

  /// Pages this process has already shown, or the fixture's saved specimen.
  ///
  /// Not a server resource and not written to device storage.
  Future<List<SocialService>> savedOnThisPhone();
}

/// The listed services, and whether that is all of them.
@immutable
class ServiceCatalogue {
  const ServiceCatalogue({required this.services, required this.complete});

  final List<SocialService> services;

  /// False when the server had more pages than the app reads
  /// (`SocialServiceApiRepository.catalogueMaxPages`), or said it had more
  /// and sent no cursor to read them by. Search then covers [services] only,
  /// and the screen says so.
  final bool complete;

  @override
  String toString() =>
      'ServiceCatalogue(${services.length}, complete: $complete)';
}
