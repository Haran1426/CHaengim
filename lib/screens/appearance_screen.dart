import 'package:material_ui/material_ui.dart';
import '../data/appearance_store.dart';
import '../data/plus_store.dart';
import '../design/app_theme.dart';
import '../widgets/theme_preview.dart';
import 'plus_screen.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({
    super.key,
    required this.appearance,
    required this.plus,
  });
  final AppearanceStore appearance;
  final PlusStore plus;
  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late AppSkin selected = widget.appearance.active;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.appearance, widget.plus]),
    builder: (context, _) {
      final locked = selected.premium && !widget.plus.isPlus;
      final active = widget.appearance.active == selected;
      return Scaffold(
        appBar: AppBar(title: const Text('테마 꾸미기')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
              children: [
                Text(
                  '나의 하루에,\n나의 색을.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '앱과 홈 화면 위젯을 같은 분위기로 꾸며요.',
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 26),
                ThemePreview(skin: selected),
                const SizedBox(height: 22),
                SkinPicker(
                  selected: selected,
                  onSelected: (value) => setState(() => selected = value),
                ),
                const SizedBox(height: 12),
                Text(
                  selected.description,
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('apply-theme'),
                  icon: Icon(
                    locked ? Icons.auto_awesome_outlined : Icons.check_rounded,
                  ),
                  onPressed:
                      widget.appearance.loading ||
                          widget.appearance.saving ||
                          active
                      ? null
                      : () async {
                          if (locked) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => PlusScreen(
                                  plus: widget.plus,
                                  initialSkin: selected,
                                ),
                              ),
                            );
                            return;
                          }
                          final saved = await widget.appearance.select(
                            selected,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? '${selected.label} 테마를 적용했어요.'
                                    : widget.appearance.error ??
                                          '잠시 후 다시 시도해 주세요.',
                              ),
                            ),
                          );
                        },
                  label: Text(
                    widget.appearance.saving
                        ? '적용 중…'
                        : active
                        ? '사용 중인 테마'
                        : locked
                        ? '플러스로 테마 사용하기'
                        : '${selected.label} 테마 적용',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  locked
                      ? '미리보기는 무료예요. 플러스로 광고 제거와 세 가지 테마를 함께 이용해요.'
                      : '숲과 모래 테마는 누구나 무료로 사용할 수 있어요.',
                  style: TextStyle(
                    color: context.appColors.muted,
                    height: 1.7,
                    fontSize: 12,
                  ),
                ),
                if (widget.appearance.error != null)
                  TextButton(
                    onPressed: widget.appearance.retry,
                    child: Text('${widget.appearance.error} 다시 시도'),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
