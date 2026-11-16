import 'package:flutter/material.dart';
import '../design/app_theme.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.skin});
  final AppSkin skin;
  @override
  Widget build(BuildContext context) {
    final colors = skin.palette;
    return Semantics(
      label: '${skin.label} 테마 앱과 위젯 미리보기. 예시 일정입니다.',
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.done_all_rounded, color: colors.forest, size: 22),
                const SizedBox(width: 8),
                Text(
                  '오늘의 챙김',
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.forest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '가장 먼저 챙겨요',
                    style: TextStyle(color: colors.onForestMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '나를 위한 작은 준비',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.lime,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'D-3',
                          style: TextStyle(
                            color: colors.forest,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '준비물 2개 남음',
                        style: TextStyle(
                          color: colors.onForestMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '홈 화면 위젯도 같은 색으로',
              style: TextStyle(color: colors.muted, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.forest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '챙김',
                          style: TextStyle(color: colors.lime, fontSize: 11),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '나를 위한 작은 준비',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'D-3',
                    style: TextStyle(
                      color: colors.lime,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '예시 화면 · ${skin.label}',
              style: TextStyle(color: colors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class SkinPicker extends StatelessWidget {
  const SkinPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final AppSkin selected;
  final ValueChanged<AppSkin> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 10,
    children: AppSkin.values
        .map(
          (skin) => ChoiceChip(
            key: ValueKey('skin-${skin.name}'),
            avatar: CircleAvatar(
              backgroundColor: skin.palette.forest,
              radius: 9,
            ),
            showCheckmark: false,
            selected: selected == skin,
            onSelected: (_) => onSelected(skin),
            label: Text(
              '${skin.label}${skin.premium ? ' · PLUS' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            tooltip: skin.description,
          ),
        )
        .toList(),
  );
}
