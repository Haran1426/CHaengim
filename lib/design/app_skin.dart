import 'package:material_ui/material_ui.dart';

enum AppSkin {
  forest(
    '숲',
    '차분한 초록, 챙김의 시작',
    false,
    AppPalette(
      paper: Color(0xFFF6F4EF),
      ink: Color(0xFF263C35),
      forest: Color(0xFF244C3F),
      lime: Color(0xFFE0EEAC),
    ),
  ),
  sand(
    '모래',
    '따뜻하고 담백한 하루',
    false,
    AppPalette(
      paper: Color(0xFFF8F4EE),
      ink: Color(0xFF443B32),
      forest: Color(0xFF62503E),
      lime: Color(0xFFF1DFC0),
    ),
  ),
  ocean(
    '바다',
    '맑은 파랑으로 가볍게',
    true,
    AppPalette(
      paper: Color(0xFFF1F6F8),
      ink: Color(0xFF293D4B),
      forest: Color(0xFF284C63),
      lime: Color(0xFFC6E7F3),
    ),
  ),
  iris(
    '라일락',
    '은은한 보랏빛의 여유',
    true,
    AppPalette(
      paper: Color(0xFFF6F3FA),
      ink: Color(0xFF40364C),
      forest: Color(0xFF56436E),
      lime: Color(0xFFE5D8F7),
    ),
  ),
  rose(
    '살구',
    '부드럽고 포근한 온기',
    true,
    AppPalette(
      paper: Color(0xFFFCF3EF),
      ink: Color(0xFF503B38),
      forest: Color(0xFF7A4A42),
      lime: Color(0xFFF9D6BE),
    ),
  );

  const AppSkin(this.label, this.description, this.premium, this.palette);
  final String label, description;
  final bool premium;
  final AppPalette palette;

  static AppSkin fromId(String? id) =>
      values.firstWhere((skin) => skin.name == id, orElse: () => forest);
}

// 같은 색상 묶음을 앱 화면과 Android 위젯에 전달합니다.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.paper,
    required this.ink,
    required this.forest,
    required this.lime,
  });
  const AppPalette.colors(this.paper, this.ink, this.forest, this.lime);
  final Color paper, ink, forest, lime;
  Color get muted => Color.lerp(ink, paper, .18)!;
  Color get line => Color.lerp(ink, paper, .89)!;
  Color get soft => Color.lerp(lime, paper, .65)!;
  Color get onForestMuted => Color.lerp(forest, Colors.white, .78)!;
  Color get progressTrack => Color.lerp(forest, Colors.white, .18)!;
  Color get rust => const Color(0xFFAF4E2E);

  @override
  AppPalette copyWith({Color? paper, Color? ink, Color? forest, Color? lime}) =>
      AppPalette.colors(
        paper ?? this.paper,
        ink ?? this.ink,
        forest ?? this.forest,
        lime ?? this.lime,
      );
  @override
  AppPalette lerp(covariant AppPalette? other, double t) => other == null
      ? this
      : AppPalette.colors(
          Color.lerp(paper, other.paper, t)!,
          Color.lerp(ink, other.ink, t)!,
          Color.lerp(forest, other.forest, t)!,
          Color.lerp(lime, other.lime, t)!,
        );
  Map<String, int> get widgetColors => {
    'background': forest.toARGB32(),
    'accent': lime.toARGB32(),
    'secondary': onForestMuted.toARGB32(),
  };
}

extension AppPaletteContext on BuildContext {
  AppPalette get appColors =>
      Theme.of(this).extension<AppPalette>() ?? AppSkin.forest.palette;
}
