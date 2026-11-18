import 'dart:convert';
import 'dart:io';
import 'play_build_config.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help')) {
    stdout.writeln(
      'dart tool/build_play_store.dart [--check] [--bootstrap] [--config=PATH] [--flutter=PATH]',
    );
    return;
  }
  final root = File.fromUri(Platform.script).parent.parent;
  String option(String name, String fallback) =>
      args
          .where((arg) => arg.startsWith('$name='))
          .map((arg) => arg.substring(name.length + 1))
          .firstOrNull ??
      fallback;
  final allowed = args.every(
    (arg) =>
        arg == '--check' ||
        arg == '--bootstrap' ||
        arg.startsWith('--config=') ||
        arg.startsWith('--flutter='),
  );
  if (!allowed) {
    stderr.writeln('알 수 없는 옵션이에요. --help를 확인하세요.');
    exitCode = 1;
    return;
  }
  final configFile = File(
    option('--config', '${root.path}/config/play-store.local.json'),
  );
  if (!configFile.existsSync()) {
    stderr.writeln(
      'config/play-store.example.json을 play-store.local.json으로 복사하고 설정을 채워 주세요.',
    );
    exitCode = 1;
    return;
  }
  PlayBuildConfig config;
  try {
    final decoded = jsonDecode(configFile.readAsStringSync());
    config = PlayBuildConfig(
      Map<String, Object?>.from(decoded as Map),
      bootstrap: args.contains('--bootstrap'),
    );
  } catch (_) {
    stderr.writeln('설정 파일을 JSON 객체로 읽을 수 없어요.');
    exitCode = 1;
    return;
  }
  final errors = [...config.errors];
  // 비밀번호는 읽더라도 출력·명령 인자에 포함하지 않습니다.
  final signing = File('${root.path}/android/key.properties');
  if (!signing.existsSync()) {
    errors.add('android/key.properties와 업로드 서명 키가 필요해요.');
  } else {
    final properties = <String, String>{};
    for (final line in signing.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') || trimmed.startsWith('!')) continue;
      final separator = line.indexOf('=');
      if (separator > 0) {
        properties[line.substring(0, separator).trim()] = line
            .substring(separator + 1)
            .trim();
      }
    }
    for (final name in [
      'storeFile',
      'storePassword',
      'keyAlias',
      'keyPassword',
    ]) {
      if (properties[name]?.isNotEmpty != true) {
        errors.add('업로드 서명 설정에서 $name 항목이 빠졌어요.');
      }
    }
    final path = properties['storeFile'];
    if (path != null && path.isNotEmpty) {
      // key.properties의 storeFile은 Java properties와 동일하게 / 경로를 권장합니다.
      final normalized = path.replaceAll(r'\\', r'\').replaceAll(r'\:', ':');
      final keyFile = File(normalized);
      final resolved = keyFile.isAbsolute
          ? keyFile
          : File('${root.path}/android/$normalized');
      if (!resolved.existsSync()) {
        errors.add('storeFile에 지정한 업로드 키 파일을 찾지 못했어요.');
      }
    }
  }
  if (errors.isNotEmpty) {
    stderr.writeln(errors.map((error) => '- $error').join('\n'));
    exitCode = 1;
    return;
  }
  stdout.writeln(
    '로컬 설정 검사 통과 · ${config.applicationId} · ${config.bootstrap ? '최초 등록용, 결제 꺼짐' : '결제 연동용'}',
  );
  stdout.writeln('이 검사는 Play/RevenueCat 계정 연결과 실제 구매 성공을 검증하지는 않아요.');
  if (args.contains('--check')) return;
  final flutter = option(
    '--flutter',
    Platform.isWindows ? 'flutter.bat' : 'flutter',
  );
  try {
    final process = await Process.start(
      flutter,
      config.flutterArguments,
      workingDirectory: root.path,
      runInShell: Platform.isWindows,
      mode: ProcessStartMode.inheritStdio,
    );
    exitCode = await process.exitCode;
    if (exitCode == 0) {
      stdout.writeln(
        'AAB 생성 완료: ${root.path}/build/app/outputs/bundle/release/app-release.aab\nPlay Console 내부 테스트에 업로드한 뒤 라이선스 테스트 계정으로 구매·복원을 확인하세요.',
      );
    }
  } on ProcessException {
    stderr.writeln('Flutter를 실행하지 못했어요. PATH를 확인하거나 --flutter=전체경로 옵션을 사용하세요.');
    exitCode = 1;
  }
}
