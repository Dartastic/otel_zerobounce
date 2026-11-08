// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_zerobounce/otel_zerobounce.dart';

/// Traces ZeroBounce calls with OpenTelemetry.
///
/// `otel_zerobounce` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each ZeroBounce call in
/// [tracedZerobounce]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'zerobounce-example');

  // Wraps a ZeroBounce API call in a CLIENT span.
  final zerobounceId = await tracedZerobounce<String>(
    operation: 'bulk.send',
    invoke: () async {
      // Make the ZeroBounce call here, then report what it returned.
      const id = 'zerobounce_8f3a2c';
      return const ZerobounceCallResult(
          value: id,
          result: ZerobounceResult(
              email: 'ada@example.com',
              domain: 'example',
              status: 'valid',
              subStatus: 'mailbox_not_found',
              freeEmail: true,
              disposable: true,
              roleBased: true,
              acceptAll: true,
              smtpProvider: 'Gmail',
              mxFound: true,
              aiScore: 1,
              aiStatus: 'Engaged',
              bulkFileId: 'bulkfile_8f3a2c',
              bulkPercentComplete: 1,
              bulkErrors: 1,
              creditsUsed: 1,
              creditsRemaining: 1,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedZerobounce bulk.send returned $zerobounceId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutZerobounceInstrumentationAsync.
  await runWithoutZerobounceInstrumentationAsync(
    () => tracedZerobounce<String>(
      operation: 'bulk.send',
      invoke: () async {
        const id = 'zerobounce_8f3a2c';
        return const ZerobounceCallResult(
            value: id,
            result: ZerobounceResult(
                email: 'ada@example.com',
                domain: 'example',
                status: 'valid',
                subStatus: 'mailbox_not_found',
                freeEmail: true,
                disposable: true,
                roleBased: true,
                acceptAll: true,
                smtpProvider: 'Gmail',
                mxFound: true,
                aiScore: 1,
                aiStatus: 'Engaged',
                bulkFileId: 'bulkfile_8f3a2c',
                bulkPercentComplete: 1,
                bulkErrors: 1,
                creditsUsed: 1,
                creditsRemaining: 1,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
