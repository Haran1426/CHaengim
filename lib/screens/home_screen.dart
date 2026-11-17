import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/schedule_store.dart';
import '../design/app_theme.dart';
import '../models/schedule.dart';
import '../platform/widget_bridge.dart';
import '../widgets/schedule_card.dart';
import '../widgets/week_overview.dart';
import 'schedule_editor.dart';
import 'schedule_detail.dart';
import 'widget_guide.dart';
import 'notification_settings.dart';
import '../data/appearance_store.dart';
import '../data/plus_store.dart';
import '../platform/ads_controller.dart';
import '../widgets/sponsor_banner.dart';
import 'appearance_screen.dart';
import 'plus_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.bridge,
    required this.appearance,
    required this.plus,
    required this.ads,
  });
  final ScheduleStore store;
  final WidgetBridge bridge;
  final AppearanceStore appearance;
  final PlusStore plus;
  final AdsController ads;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int tab = 0;
  String query = '', filter = '진행 중', category = '전체', period = '전체 기간';
  DateTime? deadlineDay;
  String? pendingRoute;
  late final Timer timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(flushRoute);
    widget.bridge.listen(openRoute);
    widget.bridge
        .initialRoute()
        .then((route) {
          if (route != null && mounted) openRoute(route);
        })
        .catchError((Object _) {});
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) widget.store.refreshClock();
    });
  }

  void openRoute(String route) {
    pendingRoute = route;
    flushRoute();
  }

  void flushRoute() {
    if (pendingRoute == null ||
        widget.store.loading ||
        widget.store.loadError != null) {
      return;
    }
    final route = pendingRoute!;
    pendingRoute = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (route == 'home') setState(() => tab = 0);
      if (route == 'add') {
        add();
      } else if (route.startsWith('detail:')) {
        final id = route.substring(7);
        if (widget.store.schedules.any((s) => s.id == id)) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ScheduleDetail(store: widget.store, id: id),
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('이 일정은 삭제되었어요.')));
        }
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.plus.refresh();
      widget.appearance.retry();
      setState(() {});
      widget.store.syncWidget().then((_) {
        if (mounted) setState(() {});
      });
      widget.store.syncReminders().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    widget.store.removeListener(flushRoute);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void add({String? initialCategory}) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          ScheduleEditor(store: widget.store, initialCategory: initialCategory),
    ),
  );
  void showSchedules([DateTime? day]) => setState(() {
    tab = 1;
    deadlineDay = day;
    filter = '진행 중';
    category = '전체';
    period = '전체 기간';
    query = '';
  });
  void detail(Schedule schedule) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ScheduleDetail(store: widget.store, id: schedule.id),
    ),
  );
  void guide() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          WidgetGuide(bridge: widget.bridge, schedules: widget.store.schedules),
    ),
  );
  void notifications() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const NotificationSettings()),
  );

  Future<void> refresh() async {
    unawaited(widget.plus.refresh());
    unawaited(widget.appearance.retry());
    await widget.store.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.store,
      widget.plus,
      widget.ads,
      widget.appearance,
    ]),
    builder: (context, _) {
      final store = widget.store;
      final now = DateTime.now();
      final active = store.schedules.where((s) => !s.isCompleted).toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
      final visible =
          store.schedules
              .where(
                (s) =>
                    (filter == '전체' ||
                        (filter == '완료' ? s.isCompleted : !s.isCompleted)) &&
                    (category == '전체' || s.category == category) &&
                    (deadlineDay == null ||
                        DateUtils.isSameDay(s.deadline, deadlineDay)) &&
                    (period == '전체 기간' ||
                        (s.daysLeft(now) >= 0 && s.daysLeft(now) <= 7)) &&
                    '${s.title} ${s.category} ${s.memo}'.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));
      final preparations = <({Schedule schedule, int index})>[];
      for (final s in active) {
        for (var i = 0; i < s.items.length; i++) {
          if (!s.items[i].done) preparations.add((schedule: s, index: i));
        }
      }
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: tab == 0 ? 64 : 70,
          titleSpacing: tab == 0 ? 20 : 24,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: context.appColors.forest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.done_all_rounded,
                  color: context.appColors.lime,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                ['챙김', '내 일정', '마이'][tab],
                style: const TextStyle(
                  fontFamily: AppTypography.display,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            if (tab == 0)
              IconButton(
                onPressed: guide,
                tooltip: '위젯 가이드',
                icon: const Icon(Icons.widgets_outlined, size: 22),
              ),
            const SizedBox(width: 12),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.appColors.line)),
          ),
          child: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                label: '일정',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: '마이',
              ),
            ],
          ),
        ),
        floatingActionButton:
            tab == 2 || store.loading || store.loadError != null
            ? null
            : FloatingActionButton.extended(
                onPressed: add,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  '일정 추가',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
        body: store.loading && !store.hasLoaded
            ? const Center(child: CircularProgressIndicator())
            : store.loadError != null && !store.hasLoaded
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(store.loadError!),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: store.load,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: refresh,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: tab == 0
                          ? const EdgeInsets.fromLTRB(20, 4, 20, 110)
                          : const EdgeInsets.fromLTRB(24, 12, 24, 110),
                      children: [
                        if (store.loading) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                        ],
                        if (store.loadError != null) ...[
                          const Text('새로 불러오지 못해 마지막으로 확인한 일정을 보여드려요.'),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: store.load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('다시 불러오기'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (store.widgetError != null) ...[
                          TextButton.icon(
                            onPressed: () async {
                              await store.syncWidget();
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.sync_problem),
                            label: Text('${store.widgetError} 다시 시도'),
                          ),
                        ],
                        if (store.reminderError != null)
                          TextButton.icon(
                            onPressed: () async {
                              await store.syncReminders();
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.notifications_off_outlined),
                            label: Text('${store.reminderError} 다시 시도'),
                          ),
                        if (tab == 0) ...[
                          Text(
                            '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}  ${['월', '화', '수', '목', '금', '토', '일'][now.weekday - 1]}요일',
                            style: TextStyle(
                              color: context.appColors.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '오늘의 챙김',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          WeekOverview(
                            today: now,
                            schedules: active,
                            onSelected: showSchedules,
                          ),
                          const SizedBox(height: 16),
                          if (active.isNotEmpty)
                            ScheduleCard(
                              schedule: active.first,
                              featured: true,
                              onTap: () => detail(active.first),
                            )
                          else
                            _empty(
                              '지금 챙길 일정이 없어요',
                              '일정 추가로 시작하세요.',
                              compact: true,
                            ),
                          if (active.isEmpty) ...[
                            const SizedBox(height: 20),
                            _section('빠르게 추가', null),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final shortcut in const [
                                  ('지원·신청', Icons.description_outlined),
                                  ('시험·자격증', Icons.school_outlined),
                                  ('생활', Icons.home_outlined),
                                ])
                                  OutlinedButton.icon(
                                    key: ValueKey('quick-add-${shortcut.$1}'),
                                    onPressed: !store.canEdit
                                        ? null
                                        : () =>
                                              add(initialCategory: shortcut.$1),
                                    icon: Icon(shortcut.$2, size: 18),
                                    label: Text(shortcut.$1),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: context.appColors.line,
                                      ),
                                      textStyle: const TextStyle(
                                        fontFamily: AppTypography.body,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (preparations.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _section('준비물', '${preparations.length}개 남음'),
                            const SizedBox(height: 12),
                            Card(
                              child: Column(
                                children: preparations
                                    .take(3)
                                    .map(
                                      (entry) => CheckboxListTile(
                                        dense: true,
                                        visualDensity: const VisualDensity(
                                          vertical: -2,
                                        ),
                                        value: false,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 0,
                                            ),
                                        title: Text(
                                          entry
                                              .schedule
                                              .items[entry.index]
                                              .title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          entry.schedule.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: context.appColors.muted,
                                          ),
                                        ),
                                        secondary: IconButton(
                                          tooltip: '일정 상세',
                                          icon: const Icon(
                                            Icons.north_east_rounded,
                                            size: 17,
                                          ),
                                          onPressed: () =>
                                              detail(entry.schedule),
                                        ),
                                        onChanged: !store.canEdit
                                            ? null
                                            : (_) async {
                                                final items = [
                                                  ...entry.schedule.items,
                                                ];
                                                items[entry
                                                    .index] = Preparation(
                                                  title:
                                                      items[entry.index].title,
                                                  done: true,
                                                );
                                                try {
                                                  await store.put(
                                                    entry.schedule.copyWith(
                                                      items: items,
                                                    ),
                                                  );
                                                } catch (_) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '체크를 저장하지 못했어요.',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (active.length > 1) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _section('다음 일정', null)),
                                TextButton(
                                  onPressed: () => showSchedules(),
                                  child: const Text(
                                    '전체 보기',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...active
                                .skip(1)
                                .take(2)
                                .map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ScheduleCard(
                                      schedule: s,
                                      onTap: () => detail(s),
                                    ),
                                  ),
                                ),
                          ],
                        ],
                        if (tab == 1) ...[
                          TextField(
                            onChanged: (value) => setState(() => query = value),
                            decoration: const InputDecoration(
                              hintText: '제목, 메모로 검색',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (deadlineDay != null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InputChip(
                                key: const ValueKey('deadline-day-filter'),
                                avatar: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  '${deadlineDay!.month}월 ${deadlineDay!.day}일 마감',
                                ),
                                deleteButtonTooltipMessage: '날짜 필터 해제',
                                onDeleted: () =>
                                    setState(() => deadlineDay = null),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 7,
                                  children: ['진행 중', '전체', '완료']
                                      .map(
                                        (value) => ChoiceChip(
                                          label: Text(value),
                                          selected: filter == value,
                                          onSelected: (_) =>
                                              setState(() => filter = value),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: '기간 필터',
                                initialValue: period,
                                onSelected: (value) => setState(() {
                                  period = value;
                                  deadlineDay = null;
                                }),
                                itemBuilder: (_) => ['전체 기간', '7일 이내']
                                    .map(
                                      (v) => PopupMenuItem(
                                        value: v,
                                        child: Text(v),
                                      ),
                                    )
                                    .toList(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '$period ▾',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['전체', ...categories]
                                  .map(
                                    (value) => Padding(
                                      padding: const EdgeInsets.only(right: 7),
                                      child: FilterChip(
                                        label: Text(
                                          value,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        selected: category == value,
                                        onSelected: (_) =>
                                            setState(() => category = value),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _section('일정 목록', '${visible.length}개'),
                          const SizedBox(height: 14),
                          if (visible.isEmpty)
                            _empty('표시할 일정이 없어요', '검색 조건을 바꿔보세요.')
                          else
                            ...visible.map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ScheduleCard(
                                  schedule: s,
                                  onTap: () => detail(s),
                                ),
                              ),
                            ),
                        ],
                        if (tab == 2) ...[
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  key: const ValueKey('open-appearance'),
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: const Icon(Icons.palette_outlined),
                                  title: const Text(
                                    '테마 꾸미기',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    widget.appearance.active.label,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => AppearanceScreen(
                                        appearance: widget.appearance,
                                        plus: widget.plus,
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(indent: 16, endIndent: 16),
                                ListTile(
                                  key: const ValueKey('open-plus'),
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: const Icon(
                                    Icons.auto_awesome_outlined,
                                  ),
                                  title: Text(
                                    widget.plus.isPlus
                                        ? '챙김 플러스 · 사용 중'
                                        : '챙김 플러스',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          PlusScreen(plus: widget.plus),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: const Icon(Icons.widgets_outlined),
                                  title: const Text(
                                    '홈 화면 위젯',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: guide,
                                ),
                                const Divider(indent: 16, endIndent: 16),
                                ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: const Icon(Icons.notifications_none),
                                  title: const Text(
                                    '마감 알림',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: notifications,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.phone_android_outlined),
                            title: Text(
                              '이 기기에 저장',
                              style: TextStyle(fontSize: 16),
                            ),
                            subtitle: Text(
                              '앱 삭제 시 일정도 삭제돼요.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => showLicensePage(
                              context: context,
                              applicationName: '챙김',
                              applicationVersion: '1.0.7',
                              applicationLegalese:
                                  'Noto Sans KR\nSIL Open Font License 1.1',
                            ),
                            child: const Text('오픈소스 라이선스'),
                          ),
                          if (widget.ads.privacyRequired)
                            TextButton(
                              onPressed: () async {
                                final success = await widget.ads
                                    .privacyOptions();
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '광고 개인정보 설정을 열지 못했어요. 다시 시도해 주세요.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('광고 개인정보 설정'),
                            ),
                          if (widget.plus.showAds && widget.ads.configured)
                            SponsorBanner(
                              key: ValueKey(widget.ads.revision),
                              ads: widget.ads,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      );
    },
  );
  Widget _section(String title, String? trailing) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: TextStyle(fontSize: 14, color: context.appColors.muted),
        ),
    ],
  );
  Widget _empty(String title, String description, {bool compact = false}) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 20 : 30,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appColors.line),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 12 : 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.appColors.lime,
              ),
              child: Icon(
                Icons.done_all_rounded,
                size: 30,
                color: context.appColors.forest,
              ),
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: context.appColors.muted,
              ),
            ),
          ],
        ),
      );
}
