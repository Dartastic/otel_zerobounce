// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_zerobounce_suppression.dart';

const _tracerName = 'dartastic_otel_libs_zerobounce';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class ZerobounceResult {
  /// Creates a result.
  const ZerobounceResult({
    this.email,
    this.domain,
    this.status,
    this.subStatus,
    this.freeEmail,
    this.disposable,
    this.roleBased,
    this.acceptAll,
    this.smtpProvider,
    this.mxFound,
    this.aiScore,
    this.aiStatus,
    this.bulkFileId,
    this.bulkPercentComplete,
    this.bulkErrors,
    this.creditsUsed,
    this.creditsRemaining,
    this.statusCode,
  });

  /// Validated email (id only — no payload-leak risk since this *is*
  /// the lookup key).
  final String? email;

  final String? domain;

  /// `valid` / `invalid` / `catch-all` / `unknown` / `spamtrap` /
  /// `abuse` / `do_not_mail`.
  final String? status;

  /// More-specific reason within `status` (e.g., `mailbox_not_found`,
  /// `disposable`, `role_based`, `global_suppression`,
  /// `mailbox_quota_exceeded`, `mail_server_temporary_error`,
  /// `unroutable_ip_address`).
  final String? subStatus;

  /// `true` if the address is a free webmail provider
  /// (gmail/yahoo/outlook/...).
  final bool? freeEmail;

  final bool? disposable;

  /// `true` if the mailbox is a role address (info@/sales@/support@).
  final bool? roleBased;

  /// `true` if the domain is configured to accept-all addresses
  /// (verifier can't tell if a specific one is real).
  final bool? acceptAll;

  /// `Gmail` / `Outlook` / `Yahoo` / `Custom` / etc.
  final String? smtpProvider;

  /// `true` if MX records exist for the domain.
  final bool? mxFound;

  /// AI Email Scoring (0-10) — ZeroBounce's deliverability prediction.
  final int? aiScore;

  /// `Engaged` / `LikelyEngaged` / `Disengaged` / `LikelyDisengaged`
  /// / `Unknown` — ZeroBounce's engagement classifier.
  final String? aiStatus;

  /// Bulk validation file id.
  final String? bulkFileId;

  /// `file_status.percent_complete` from bulk endpoints.
  final int? bulkPercentComplete;

  final int? bulkErrors;

  final int? creditsUsed;
  final int? creditsRemaining;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class ZerobounceCallResult<T> {
  /// Creates a call result.
  const ZerobounceCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final ZerobounceResult? result;
}

/// Wraps a ZeroBounce API call in a CLIENT span. [operation] is one
/// of `validate`, `validate.batch`, `bulk.send`, `bulk.status`,
/// `bulk.result`, `bulk.delete`, `getapiusage`, `getcredits`,
/// `getcounts`, `findemail`, `scoring`, `activity_data`.
Future<T> tracedZerobounce<T>({
  required String operation,
  required Future<ZerobounceCallResult<T>> Function() invoke,
}) async {
  if (zerobounceInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'zerobounce',
    'rpc.method': operation,
    'zerobounce.operation': operation,
  };

  final span = _tracer().startSpan(
    'zerobounce $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.email != null) {
        extras.add(OTelAPI.attributeString(
          'zerobounce.email',
          r.result!.email!,
        ));
      }
      if (r.result!.domain != null) {
        extras.add(OTelAPI.attributeString(
          'zerobounce.domain',
          r.result!.domain!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTelAPI.attributeString(
          'zerobounce.status',
          r.result!.status!,
        ));
        if (r.result!.status == 'invalid' ||
            r.result!.status == 'spamtrap' ||
            r.result!.status == 'abuse') {
          span.setStatus(
            SpanStatusCode.Error,
            'ZeroBounce status ${r.result!.status}',
          );
        }
      }
      if (r.result!.subStatus != null) {
        extras.add(OTelAPI.attributeString(
          'zerobounce.sub_status',
          r.result!.subStatus!,
        ));
      }
      if (r.result!.freeEmail != null) {
        extras.add(OTelAPI.attributeBool(
          'zerobounce.free_email',
          r.result!.freeEmail!,
        ));
      }
      if (r.result!.disposable != null) {
        extras.add(OTelAPI.attributeBool(
          'zerobounce.disposable',
          r.result!.disposable!,
        ));
      }
      if (r.result!.roleBased != null) {
        extras.add(OTelAPI.attributeBool(
          'zerobounce.role_based',
          r.result!.roleBased!,
        ));
      }
      if (r.result!.acceptAll != null) {
        extras.add(OTelAPI.attributeBool(
          'zerobounce.accept_all',
          r.result!.acceptAll!,
        ));
      }
      if (r.result!.smtpProvider != null) {
        extras.add(OTelAPI.attributeString(
          'zerobounce.smtp.provider',
          r.result!.smtpProvider!,
        ));
      }
      if (r.result!.mxFound != null) {
        extras.add(OTelAPI.attributeBool(
          'zerobounce.mx_found',
          r.result!.mxFound!,
        ));
      }
      if (r.result!.aiScore != null) {
        extras.add(OTelAPI.attributeInt(
          'zerobounce.ai.score',
          r.result!.aiScore!,
        ));
      }
      if (r.result!.aiStatus != null) {
        extras.add(OTelAPI.attributeString(
          'zerobounce.ai.status',
          r.result!.aiStatus!,
        ));
      }
      if (r.result!.bulkFileId != null) {
        extras.add(OTelAPI.attributeString(
          'zerobounce.bulk.file_id',
          r.result!.bulkFileId!,
        ));
      }
      if (r.result!.bulkPercentComplete != null) {
        extras.add(OTelAPI.attributeInt(
          'zerobounce.bulk.percent_complete',
          r.result!.bulkPercentComplete!,
        ));
      }
      if (r.result!.bulkErrors != null) {
        extras.add(OTelAPI.attributeInt(
          'zerobounce.bulk.errors',
          r.result!.bulkErrors!,
        ));
      }
      if (r.result!.creditsUsed != null) {
        extras.add(OTelAPI.attributeInt(
          'zerobounce.credits.used',
          r.result!.creditsUsed!,
        ));
      }
      if (r.result!.creditsRemaining != null) {
        extras.add(OTelAPI.attributeInt(
          'zerobounce.credits.remaining',
          r.result!.creditsRemaining!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'ZeroBounce HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
