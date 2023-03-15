import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:shorebird_cli/src/command.dart';
import 'package:shorebird_cli/src/shorebird_config_mixin.dart';

/// {@template delete_app_command}
///
/// `shorebird apps delete`
/// Delete an existing app on Shorebird.
/// {@endtemplate}
class DeleteAppCommand extends ShorebirdCommand with ShorebirdConfigMixin {
  /// {@macro delete_app_command}
  DeleteAppCommand({
    required super.logger,
    super.buildCodePushClient,
    super.auth,
  }) {
    argParser.addOption(
      'app-id',
      help: '''
The unique application identifier.
Defaults to the product_id in "shorebird.yaml".''',
    );
  }

  @override
  String get description => 'Delete an existing app on Shorebird.';

  @override
  String get name => 'delete';

  @override
  Future<int>? run() async {
    final session = auth.currentSession;
    if (session == null) {
      logger.err('You must be logged in.');
      return ExitCode.noUser.code;
    }

    final appId = results['app-id'] as String?;
    late final String productId;

    if (appId == null) {
      String? defaultProductId;
      try {
        defaultProductId = getShorebirdYaml()?.productId;
      } catch (_) {}

      productId = logger.prompt(
        '${lightGreen.wrap('?')} Enter the App ID',
        defaultValue: defaultProductId,
      );
    } else {
      productId = appId;
    }

    final client = buildCodePushClient(apiKey: session.apiKey);

    final confirm = logger.confirm('Deleting an app is permanent. Continue?');
    if (!confirm) {
      logger.info('Aborted.');
      return ExitCode.success.code;
    }

    try {
      await client.deleteApp(productId: productId);
    } catch (error) {
      logger.err('Unable to delete app\n$error');
      return ExitCode.software.code;
    }

    logger.info(
      '${lightGreen.wrap('Deleted app: ${cyan.wrap(productId)}')}',
    );

    return ExitCode.success.code;
  }
}