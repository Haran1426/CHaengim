import 'package:material_ui/material_ui.dart';

import '../design/app_theme.dart';
import '../models/schedule.dart';
import '../platform/widget_bridge.dart';

class WidgetGuide extends StatefulWidget {
  const WidgetGuide({super.key, required this.bridge, required this.schedules});
  final WidgetBridge bridge;
  final List<Schedule> schedules;
  @override
  State<WidgetGuide> createState() => _WidgetGuideState();
}

class _WidgetGuideState extends State<WidgetGuide> {
  bool medium = false, busy = false;
  Future<void> pin() async {
    setState(() => busy = true);
    var message = '홈 화면을 길게 누른 뒤 위젯 목록에서 챙김을 찾아 추가해 주세요.';
    try {
      await widget.bridge.sync(widget.schedules);
      if (await widget.bridge.pin(medium: medium)) {
        message = '홈 화면의 위젯 추가 창에서 확인해 주세요.';
      }
    } catch (_) {
      message = '추가 창을 열지 못했어요. 홈 화면의 위젯 목록에서 챙김을 선택해 주세요.';
    }
    if (!mounted) return;
    setState(() => busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.schedules.where((s) => !s.isCompleted).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    return Scaffold(
      appBar: AppBar(title: const Text('홈 화면 위젯')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '바탕화면에서도\n놓치지 않는 챙김.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '앱을 열지 않고 마감일과 남은 준비물을 확인해요.',
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('소형 · 1건')),
                    ButtonSegment(value: true, label: Text('중형 · 최대 3건')),
                  ],
                  selected: {medium},
                  onSelectionChanged: (value) =>
                      setState(() => medium = value.first),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: context.appColors.soft,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: medium ? 380 : 230),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.appColors.forest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '챙김',
                                    style: TextStyle(
                                      color: context.appColors.lime,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.add_circle_outline,
                                  color: context.appColors.lime,
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            if (active.isEmpty) ...[
                              const Text(
                                '다가오는 일정 없음',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '+ 버튼으로 새 일정을 챙겨요',
                                style: TextStyle(
                                  color: context.appColors.onForestMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ] else
                              ...active
                                  .take(medium ? 3 : 1)
                                  .map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.dDay(DateTime.now()),
                                            style: TextStyle(
                                              color: context.appColors.lime,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            s.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '준비물 ${s.remaining}개 남음 · ${s.stage.label}',
                                            style: TextStyle(
                                              color: context
                                                  .appColors
                                                  .onForestMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '실제 일정 미리보기 · 크기와 글꼴은 홈 앱에 따라 달라질 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appColors.muted,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: busy ? null : pin,
                  icon: const Icon(Icons.add),
                  label: Text(busy ? '추가 창 여는 중…' : '홈 화면에 위젯 추가'),
                ),
                const SizedBox(height: 24),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.touch_app_outlined),
                  title: Text('일정을 누르면 상세로'),
                  subtitle: Text('준비물 체크는 앱에서 정확하게 확인하고 처리해요.'),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.add_circle_outline),
                  title: Text('+ 버튼으로 빠르게 등록'),
                  subtitle: Text('등록 화면을 바로 열어 새 일정을 추가해요.'),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.sync_rounded),
                  title: Text('변경사항을 위젯에도 반영'),
                  subtitle: Text('일정 저장 후 바로 갱신해요. 최종 완료한 일정은 제외돼요.'),
                ),
                const SizedBox(height: 16),
                Text(
                  '추가 창이 나오지 않나요?\n홈 화면의 빈 곳을 길게 누르기 → 위젯 → 챙김 → 소형 또는 중형을 선택하세요.',
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 12,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
