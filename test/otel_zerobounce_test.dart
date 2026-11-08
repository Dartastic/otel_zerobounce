// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_zerobounce/otel_zerobounce.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_zerobounce-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('validate records full classifier output', () async {
    await tracedZerobounce<String>(
      operation: 'validate',
      invoke: () async => const ZerobounceCallResult(
        value: 'ok',
        result: ZerobounceResult(
          email: 'jane@example.com',
          domain: 'example.com',
          status: 'valid',
          freeEmail: false,
          disposable: false,
          roleBased: false,
          acceptAll: false,
          smtpProvider: 'Custom',
          mxFound: true,
          aiScore: 9,
          aiStatus: 'Engaged',
          creditsUsed: 1,
          creditsRemaining: 9999,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('zerobounce validate')!);
    expect(a['zerobounce.status'], 'valid');
    expect(a['zerobounce.ai.score'], 9);
    expect(a['zerobounce.ai.status'], 'Engaged');
    expect(a['zerobounce.credits.used'], 1);
  });

  test('spamtrap status sets span error', () async {
    await tracedZerobounce<String>(
      operation: 'validate',
      invoke: () async => const ZerobounceCallResult(
        value: 'ok',
        result: ZerobounceResult(
          status: 'spamtrap',
          subStatus: 'global_suppression',
        ),
      ),
    );
    expect(
      spans.findSpanByName('zerobounce validate')!.status,
      SpanStatusCode.Error,
    );
  });

  test('catch-all does NOT set span error', () async {
    await tracedZerobounce<String>(
      operation: 'validate',
      invoke: () async => const ZerobounceCallResult(
        value: 'ok',
        result: ZerobounceResult(
          status: 'catch-all',
          acceptAll: true,
        ),
      ),
    );
    expect(
      spans.findSpanByName('zerobounce validate')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('bulk.status records progress', () async {
    await tracedZerobounce<String>(
      operation: 'bulk.status',
      invoke: () async => const ZerobounceCallResult(
        value: 'ok',
        result: ZerobounceResult(
          bulkFileId: 'file_1',
          bulkPercentComplete: 75,
          bulkErrors: 0,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('zerobounce bulk.status')!);
    expect(a['zerobounce.bulk.percent_complete'], 75);
  });

  test('suppression skips spans', () async {
    await runWithoutZerobounceInstrumentationAsync(() async {
      await tracedZerobounce<String>(
        operation: 'getcredits',
        invoke: () async => const ZerobounceCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('zerobounce '), isEmpty);
  });
}
