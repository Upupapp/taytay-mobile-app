import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/deep_link.dart';
import 'package:taytay_resident/features/issuance/data/issuance_api_repository.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_request.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_status.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_type.dart';
import 'package:taytay_resident/features/notifications/data/notification_api_repository.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';

class _Scripted implements ApiTransport {
  final List<Result<ApiHttpResponse>> responses = <Result<ApiHttpResponse>>[];
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> _json(int status, Object body) => Ok<ApiHttpResponse>(
  ApiHttpResponse(statusCode: status, body: jsonEncode(body)),
);

Map<String, Object?> _typeWire({Object? fee = 5000}) => <String, Object?>{
  'id': 'dt-1',
  'office': <String, Object?>{
    'id': 'o-1',
    'slug': 'mcr',
    'name': 'Civil Registrar',
  },
  'name': 'Certified copy of a birth record',
  'description': 'A copy.',
  'requirements': <Object?>[
    <String, Object?>{
      'code': 'valid-id',
      'label': 'Valid ID',
      'required': true,
      'hint': 'Front of the ID',
    },
    <String, Object?>{
      'code': 'authorization',
      'label': 'Authorization letter',
      'required': false,
      'hint': null,
    },
  ],
  'fee_centavos': fee,
  'processing_days': null,
  'claim_instructions': 'Civil Registry window.',
  'active': true,
  'retired_at': null,
  'accepts': <String, Object?>{
    'mime_types': <Object?>['application/pdf', 'image/jpeg', 'image/png'],
    'max_bytes': 10485760,
  },
  'created_at': '2026-11-01T00:00:00Z',
  'updated_at': '2026-11-01T00:00:00Z',
};

Map<String, Object?> _requestWire({
  String status = 'needs-info',
  bool canCancel = true,
  bool canResubmit = true,
}) => <String, Object?>{
  'id': 'r-1',
  'reference_number': 'DR-2026-000124',
  'status': status,
  'status_label': 'Needs more information',
  'type': <String, Object?>{'id': 'dt-1', 'name': 'Certificate of indigency'},
  'office': <String, Object?>{'id': 'o-2', 'name': 'MSWDO'},
  'created_at': '2026-11-02T02:00:00Z',
  'updated_at': '2026-11-03T05:20:00Z',
  'purpose': 'For a hospital bill discount.',
  'fee_centavos': null,
  'processing_days': 1,
  'claim_instructions': null,
  'requirements': <Object?>[
    <String, Object?>{
      'code': 'valid-id',
      'label': 'Valid ID',
      'required': true,
      'hint': null,
    },
  ],
  'attachments': <Object?>[
    <String, Object?>{
      'id': 'a-1',
      'requirement_code': 'valid-id',
      'version': 1,
      'mime_type': 'image/jpeg',
      'byte_size': 1000,
      'current': true,
      'created_at': '2026-11-02T02:00:00Z',
    },
  ],
  'claim_details': null,
  'needs_info_message': 'Send a newer barangay certificate.',
  'history': <Object?>[
    <String, Object?>{
      'from_status': null,
      'to_status': 'submitted',
      'status_label': 'Submitted',
      'by': 'resident',
      'description': 'You sent the request.',
      'message': null,
      'claim_details': null,
      'at': '2026-11-02T02:00:00Z',
    },
    <String, Object?>{
      'from_status': 'under-review',
      'to_status': 'needs-info',
      'status_label': 'Needs more information',
      'by': 'office',
      'description': 'The office needs more from you.',
      'message': 'Send a newer barangay certificate.',
      'claim_details': null,
      'at': '2026-11-03T05:20:00Z',
    },
  ],
  'can_cancel': canCancel,
  'can_resubmit': canResubmit,
  // Office-only fields a resident view never carries; ignored if they appear.
  'allowed_moves': <Object?>['approved'],
  'resident': <String, Object?>{'id': 'u-1', 'name': 'Sample Resident'},
};

CapturedDocument _pdf() => CapturedDocument(
  bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 1, 2, 3]),
  fileName: 'Juana Dela Cruz barangay cert.pdf',
  mimeType: 'application/pdf',
  source: DocumentSource.file,
);

void main() {
  late _Scripted transport;
  late ApiClient client;
  late IssuanceApiRepository repository;

  setUp(() {
    transport = _Scripted();
    client = ApiClient(
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
      ),
      transport: transport,
      accessTokenProvider: () async => 'tok',
    );
    repository = IssuanceApiRepository(apiClient: client);
  });

  group('the catalogue', () {
    test(
      'is read anonymously, whole, with the server\'s own upload policy',
      () async {
        transport.responses.add(
          _json(200, <String, Object?>{
            'data': <Object?>[
              _typeWire(),
              _typeWire(fee: null)..['id'] = 'dt-2',
            ],
            'meta': <String, Object?>{},
          }),
        );

        final Result<List<IssuanceType>> result = await repository.listTypes();

        final ApiRequest request = transport.requests.single;
        expect(request.method, HttpMethod.get);
        expect(request.path, 'issuance-types');
        expect(request.headers.containsKey('Authorization'), isFalse);
        final List<IssuanceType> types = result.valueOrNull!;
        expect(types, hasLength(2));
        final IssuanceType first = types.first;
        expect(first.feeCentavos, 5000);
        expect(types.last.feeCentavos, isNull);
        expect(first.processingDays, isNull);
        expect(first.officeName, 'Civil Registrar');
        expect(
          first.requirements.map((IssuanceRequirement r) => r.required),
          <bool>[true, false],
        );
        expect(first.uploadPolicy.source, UploadPolicySource.served);
        expect(first.uploadPolicy.maxBytes, 10485760);
      },
    );

    test('a retired or unknown type is not found', () async {
      transport.responses.add(
        _json(404, <String, Object?>{
          'error': <String, Object?>{
            'code': 'NOT_FOUND',
            'message': 'Document type not found.',
            'request_id': 'req-9',
          },
        }),
      );

      final Result<IssuanceType> result = await repository.loadType('gone');

      expect(transport.requests.single.path, 'issuance-types/gone');
      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(result.failureOrNull?.requestId, 'req-9');
    });
  });

  group('filing a request', () {
    test(
      'posts multipart: the type, the trimmed purpose, one part per code',
      () async {
        transport.responses.add(
          _json(201, <String, Object?>{
            'data': _requestWire(status: 'submitted', canResubmit: false),
            'meta': <String, Object?>{},
          }),
        );

        final Result<IssuanceRequestDetail> result = await repository.submit(
          typeId: 'dt-1',
          purpose: '  For a school enrolment.  ',
          files: <String, CapturedDocument>{'valid-id': _pdf()},
          idempotencyKey: 'key-1',
        );

        final ApiRequest request = transport.requests.single;
        expect(request.method, HttpMethod.post);
        expect(request.path, 'me/issuance-requests');
        expect(request.headers['Authorization'], 'Bearer tok');
        expect(request.headers['Idempotency-Key'], 'key-1');
        expect(request.body, <String, Object?>{
          'type_id': 'dt-1',
          'purpose': 'For a school enrolment.',
        });
        final MultipartFile part = request.files.single;
        expect(part.field, 'valid-id');
        expect(part.mimeType, 'application/pdf');
        // The phone's file name can carry a person's name; it never leaves.
        expect(part.filename, 'valid-id.pdf');
        expect(result.valueOrNull?.summary.referenceNumber, 'DR-2026-000124');
        expect(result.valueOrNull?.status, IssuanceStatus.submitted);
      },
    );

    test('only a 201 counts as filed', () async {
      transport.responses.add(
        _json(200, <String, Object?>{
          'data': _requestWire(status: 'submitted'),
          'meta': <String, Object?>{},
        }),
      );

      final Result<IssuanceRequestDetail> result = await repository.submit(
        typeId: 'dt-1',
        purpose: 'For a school enrolment.',
        files: const <String, CapturedDocument>{},
        idempotencyKey: 'key-1',
      );

      expect(result.isErr, isTrue);
    });

    test(
      'an unverified resident gets a typed refusal, not the server text',
      () async {
        const String serverText =
            'Only a verified resident can request a document. Finish verification first.';
        transport.responses.add(
          _json(403, <String, Object?>{
            'error': <String, Object?>{
              'code': 'FORBIDDEN',
              'message': serverText,
              'request_id': 'req-403',
            },
          }),
        );

        final Result<IssuanceRequestDetail> result = await repository.submit(
          typeId: 'dt-1',
          purpose: 'For a school enrolment.',
          files: const <String, CapturedDocument>{},
          idempotencyKey: 'key-1',
        );

        final AppFailure? failure = result.failureOrNull;
        expect(failure, isA<ForbiddenFailure>());
        expect(failure?.residentMessage, isNot(contains(serverText)));
      },
    );

    test('a 422 keyed by requirement code keeps the keys', () async {
      transport.responses.add(
        _json(422, <String, Object?>{
          'error': <String, Object?>{
            'code': 'VALIDATION_FAILED',
            'message': 'Validation failed.',
            'details': <String, Object?>{
              'valid-id': <Object?>['The file is not a PDF, JPEG or PNG.'],
            },
          },
        }),
      );

      final Result<IssuanceRequestDetail> result = await repository.submit(
        typeId: 'dt-1',
        purpose: 'For a school enrolment.',
        files: <String, CapturedDocument>{'valid-id': _pdf()},
        idempotencyKey: 'key-1',
      );

      final AppFailure? failure = result.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).fieldErrors.keys,
        contains('valid-id'),
      );
    });
  });

  group('following requests', () {
    test('the list sends limit and cursor and reads the next cursor', () async {
      transport.responses.add(
        _json(200, <String, Object?>{
          'data': <Object?>[_requestWire()],
          'meta': <String, Object?>{
            'pagination': <String, Object?>{
              'limit': 25,
              'has_more': true,
              'next_cursor': 'c-2',
            },
          },
        }),
      );

      final Result<Paginated<IssuanceRequestSummary>> result = await repository
          .listOwn(cursor: 'c-1');

      final ApiRequest request = transport.requests.single;
      expect(request.path, 'me/issuance-requests');
      expect(request.query['cursor'], 'c-1');
      expect(request.query['limit'], isNotNull);
      expect(request.query.containsKey('page'), isFalse);
      final Paginated<IssuanceRequestSummary> page = result.valueOrNull!;
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'c-2');
      expect(page.items.single.status, IssuanceStatus.needsInfo);
      expect(page.items.single.typeId, 'dt-1');
    });

    test(
      'the detail carries the history, the office\'s words and the server\'s flags',
      () async {
        transport.responses.add(
          _json(200, <String, Object?>{
            'data': _requestWire(),
            'meta': <String, Object?>{},
          }),
        );

        final IssuanceRequestDetail detail = (await repository.loadOwn(
          'r-1',
        )).valueOrNull!;

        expect(transport.requests.single.path, 'me/issuance-requests/r-1');
        expect(detail.needsInfoMessage, 'Send a newer barangay certificate.');
        expect(detail.canCancel, isTrue);
        expect(detail.canResubmit, isTrue);
        expect(detail.history, hasLength(2));
        expect(detail.history.last.by, IssuanceActor.office);
        expect(
          detail.history.last.message,
          'Send a newer barangay certificate.',
        );
        expect(detail.attachments.single.isImage, isTrue);
      },
    );

    test('a missing flag never offers an act', () async {
      final Map<String, Object?> wire = _requestWire()
        ..remove('can_cancel')
        ..remove('can_resubmit');
      transport.responses.add(
        _json(200, <String, Object?>{
          'data': wire,
          'meta': <String, Object?>{},
        }),
      );

      final IssuanceRequestDetail detail = (await repository.loadOwn(
        'r-1',
      )).valueOrNull!;

      expect(detail.canCancel, isFalse);
      expect(detail.canResubmit, isFalse);
    });

    test('cancel posts the reason only when one was given', () async {
      for (final String? reason in <String?>[null, '  ', 'Filed by mistake']) {
        transport.responses.add(
          _json(200, <String, Object?>{
            'data': _requestWire(status: 'cancelled', canCancel: false),
            'meta': <String, Object?>{},
          }),
        );
        final Result<IssuanceRequestDetail> result = await repository.cancel(
          'r-1',
          reason: reason,
          idempotencyKey: 'k',
        );
        expect(result.valueOrNull?.status, IssuanceStatus.cancelled);
      }
      expect(transport.requests.map((ApiRequest r) => r.path).toSet(), <String>{
        'me/issuance-requests/r-1/cancel',
      });
      expect(transport.requests[0].body, <String, Object?>{});
      expect(transport.requests[1].body, <String, Object?>{});
      expect(transport.requests[2].body, <String, Object?>{
        'reason': 'Filed by mistake',
      });
    });

    test(
      'resubmit sends the note and the new files under their codes',
      () async {
        transport.responses.add(
          _json(200, <String, Object?>{
            'data': _requestWire(status: 'under-review', canResubmit: false),
            'meta': <String, Object?>{},
          }),
        );

        final Result<IssuanceRequestDetail> result = await repository.resubmit(
          'r-1',
          note: ' A newer certificate. ',
          files: <String, CapturedDocument>{'valid-id': _pdf()},
          idempotencyKey: 'k',
        );

        final ApiRequest request = transport.requests.single;
        expect(request.path, 'me/issuance-requests/r-1/resubmit');
        expect(request.body, <String, Object?>{'note': 'A newer certificate.'});
        expect(request.files.single.field, 'valid-id');
        expect(result.valueOrNull?.status, IssuanceStatus.underReview);
      },
    );

    test('the resident\'s own photo is read as bytes', () async {
      final Uint8List png = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0,
        0,
      ]);
      transport.responses.add(
        Ok<ApiHttpResponse>(
          ApiHttpResponse(
            statusCode: 200,
            body: '',
            bodyBytes: png,
            headers: const <String, String>{'content-type': 'image/png'},
          ),
        ),
      );

      final Result<Uint8List> result = await repository.loadAttachmentImage(
        'r-1',
        'a-1',
      );

      expect(
        transport.requests.single.path,
        'me/issuance-requests/r-1/attachments/a-1/content',
      );
      expect(result.valueOrNull, png);
    });
  });

  group('the update notification', () {
    test('opens the request it names', () async {
      transport.responses.add(
        _json(200, <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'id': 'n-1',
              'type': 'issuance_request_updated',
              'title': 'Document request update',
              'body':
                  'Your document request DR-2026-000124 is now ready for pickup.',
              'subject_id': 'r-1',
              'read_at': null,
              'created_at': '2026-11-03T05:20:00Z',
            },
          ],
          'meta': <String, Object?>{},
        }),
      );

      final Result<Paginated<ResidentNotification>> result =
          await NotificationApiRepository(apiClient: client).listOwn();
      final ResidentNotification notification =
          result.valueOrNull!.items.single;

      final DeepLinkResult link = DeepLink.resolve(notification.target);
      expect(link, isA<DeepLinkResolved>());
      final DeepLinkTarget target = (link as DeepLinkResolved).target;
      expect(target.route, AppRoute.issuanceRequestDetail);
      expect(target.location, '/documents/mine/r-1');
    });
  });
}
