import 'package:flutter/foundation.dart';

import '../../../core/documents/upload_policy.dart';

/// One file a document type asks for. The [code] is also the multipart field
/// name the file travels under, so it is never shown to a resident.
@immutable
class IssuanceRequirement {
  const IssuanceRequirement({
    required this.code,
    required this.label,
    required this.required,
    this.hint,
  });

  final String code;
  final String label;
  final bool required;
  final String? hint;
}

/// A document a municipal office issues, as the public catalogue lists it.
///
/// Public information: no field here is about a resident.
@immutable
class IssuanceType {
  const IssuanceType({
    required this.id,
    required this.name,
    required this.officeId,
    required this.officeName,
    required this.requirements,
    required this.uploadPolicy,
    this.description,
    this.feeCentavos,
    this.processingDays,
    this.claimInstructions,
  });

  final String id;
  final String name;
  final String? description;
  final String officeId;
  final String officeName;
  final List<IssuanceRequirement> requirements;

  /// Integer centavos, or `null` when the office stated no fee.
  final int? feeCentavos;

  /// Working days, or `null` when the office did not state them.
  final int? processingDays;
  final String? claimInstructions;

  /// The server's own `accepts` block: which files, and how large.
  final UploadPolicy uploadPolicy;

  @override
  String toString() => 'IssuanceType($id)';
}

/// The catalogue, grouped by office in the order the server listed them.
List<(String office, List<IssuanceType> types)> groupByOffice(
  List<IssuanceType> types,
) {
  final List<String> order = <String>[];
  final Map<String, List<IssuanceType>> byOffice =
      <String, List<IssuanceType>>{};
  for (final IssuanceType type in types) {
    final List<IssuanceType>? existing = byOffice[type.officeId];
    if (existing == null) {
      order.add(type.officeId);
      byOffice[type.officeId] = <IssuanceType>[type];
    } else {
      existing.add(type);
    }
  }
  return <(String, List<IssuanceType>)>[
    for (final String id in order)
      (
        byOffice[id]!.first.officeName,
        List<IssuanceType>.unmodifiable(byOffice[id]!),
      ),
  ];
}

/// Types whose name, description or office contains every word of [query].
List<IssuanceType> searchTypes(List<IssuanceType> types, String query) {
  final List<String> words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return types;
  return <IssuanceType>[
    for (final IssuanceType type in types)
      if (words.every(
        (String word) => <String?>[
          type.name,
          type.description,
          type.officeName,
        ].any((String? field) => field?.toLowerCase().contains(word) ?? false),
      ))
        type,
  ];
}
