import 'package:material_ui/material_ui.dart';

import '../data/plus_store.dart';
import '../design/app_theme.dart';
import '../widgets/theme_preview.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen({
    super.key,
    required this.plus,
    this.initialSkin = AppSkin.iris,
  });
  final PlusStore plus;
  final AppSkin initialSkin;
  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  late AppSkin selected = widget.initialSkin;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.plus,
    builder: (context, _) {
      final plus = widget.plus;
      return Scaffold(
        appBar: AppBar(title: const Text('챙김 플러스')),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.lime,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        plus.isPlus ? 'PLUS · 사용 중' : 'CHAENGIM  /  PLUS',
                        style: TextStyle(
                          color: context.appColors.forest,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '챙기는 마음은 그대로.\n분위기는 내 취향대로.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '광고 없이 조용하게, 좋아하는 색으로 가볍게.',
                    style: TextStyle(
                      color: context.appColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 26),
                  ThemePreview(skin: selected),
                  const SizedBox(height: 18),
                  SkinPicker(
                    selected: selected,
                    onSelected: (value) => setState(() => selected = value),
                  ),
                  const SizedBox(height: 28),
                  _benefit(
                    Icons.visibility_off_outlined,
                    '광고 없는 챙김',
                    '마이 화면의 배너 광고를 없애요.',
                  ),
                  const SizedBox(height: 20),
                  _benefit(
                    Icons.palette_outlined,
                    '내 취향의 테마 3종',
                    '바다 · 라일락 · 살구로 앱과 위젯을 함께 꾸며요.',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.appColors.soft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      '일정, 준비물, 알림, 기본 위젯은 모두 무료예요.\n플러스는 꾸미기와 광고 제거만 더해요.',
                      style: TextStyle(fontSize: 12, height: 1.8),
                    ),
                  ),
                  const SizedBox(height: 26),
                  if (!plus.isPlus) ...[
                    Text(
                      '한 번 구매로 계속 사용',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '정기 구독 없이, 추가 결제 없이.',
                      style: TextStyle(
                        color: context.appColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    key: const ValueKey('buy-plus'),
                    onPressed: plus.canBuy ? plus.purchase : null,
                    child: Text(
                      plus.isPlus
                          ? '플러스 사용 중'
                          : plus.busy
                          ? '스토어에서 확인 중…'
                          : plus.loading
                          ? '상품 확인 중…'
                          : plus.paymentPending
                          ? '결제 승인 대기 중'
                          : plus.offer != null
                          ? '${plus.offer!.price} · 플러스 시작하기'
                          : '출시 준비 중',
                    ),
                  ),
                  if (!plus.isPlus && !plus.configured) ...[
                    const SizedBox(height: 12),
                    Text(
                      '지금은 테마를 미리 둘러볼 수 있어요.\n판매가 시작되면 스토어 가격이 여기에 표시돼요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appColors.muted,
                        fontSize: 12,
                        height: 1.7,
                      ),
                    ),
                  ],
                  if (plus.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(plus.message!),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: plus.canRestore ? plus.restore : null,
                        child: const Text('구매 복원'),
                      ),
                      if (plus.configured)
                        TextButton(
                          onPressed: plus.busy || plus.loading
                              ? null
                              : plus.refresh,
                          child: const Text('다시 확인'),
                        ),
                    ],
                  ),
                  Text(
                    '기기를 바꿨다면 같은 Google Play 계정으로 구매를 복원해 주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.muted,
                      fontSize: 11,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _benefit(IconData icon, String title, String detail) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: context.appColors.forest, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              style: TextStyle(
                color: context.appColors.muted,
                fontSize: 12,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
