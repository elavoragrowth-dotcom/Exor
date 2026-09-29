import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core.dart';
import 'data.dart';
import 'onboarding.dart';
import 'home_page.dart';
import 'habits_page.dart';
import 'planner_page.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final prefs = await SharedPreferences.getInstance();
  final store = AppStore(prefs);
  await store.load();
  runApp(DaybookApp(store: store));
}

class DaybookApp extends StatelessWidget {
  const DaybookApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daybook',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: C.base,
        colorScheme: ColorScheme.fromSeed(seedColor: C.lime, brightness: Brightness.dark),
      ),
      home: Root(store: store),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key, required this.store});
  final AppStore store;
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraBackground(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeOutCubic,
            layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
            child: store.onboarded ? Shell(key: const ValueKey('shell'), store: store) : Onboarding(key: const ValueKey('onb'), store: store),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store});
  final AppStore store;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  static const _tabs = [
    _Tab('Home', Icons.home_rounded),
    _Tab('Habits', Icons.local_fire_department_rounded),
    _Tab('Projects', Icons.auto_stories_rounded),
    _Tab('Stats', Icons.insights_rounded),
    _Tab('Planner', Icons.calendar_month_rounded),
    _Tab('Settings', Icons.tune_rounded),
  ];

  Widget _body() {
    final store = widget.store;
    switch (_i) {
      case 0:
        return HomePage(store: store);
      case 1:
        return HabitsPage(store: store);
      case 2:
        return const SoonPage(
          kicker: 'PROJECTS',
          light: 'Chapter by chapter,',
          bold: 'cleared.',
          icon: Icons.auto_stories_rounded,
          phase: 2,
          line: 'Your eight CA Inter subjects and every chapter, with revisions, will live here.',
        );
      case 3:
        return const SoonPage(
          kicker: 'STATS',
          light: "How you're",
          bold: 'really doing.',
          icon: Icons.insights_rounded,
          phase: 3,
          line: 'Focus time, consistency and progress will be drawn here, one calm chart at a time.',
        );
      case 4:
        return PlannerPage(store: store);
      default:
        return SettingsPage(store: store, onReset: store.resetOnboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim), child: child),
              ),
              child: KeyedSubtree(key: ValueKey(_i), child: _body()),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
          child: GlassNav(tabs: _tabs, index: _i, onTap: (i) => setState(() => _i = i)),
        ),
      ],
    );
  }
}

class GlassNav extends StatelessWidget {
  const GlassNav({super.key, required this.tabs, required this.index, required this.onTap});
  final List<_Tab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(36);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: br, border: Border.all(color: Colors.white.withValues(alpha: 0.16))),
          child: LayoutBuilder(builder: (context, cons) {
            const small = 40.0;
            final big = cons.maxWidth - small * (tabs.length - 1);
            return Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Semantics(
                    button: true,
                    label: tabs[i].label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != index) HapticFeedback.selectionClick();
                        onTap(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        width: i == index ? big : small,
                        height: 52,
                        decoration: BoxDecoration(color: i == index ? C.lime : Colors.transparent, borderRadius: BorderRadius.circular(26)),
                        child: ClipRect(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(tabs[i].icon, size: 22, color: i == index ? C.base : C.text.withValues(alpha: 0.75)),
                              if (i == index) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 450),
                                    builder: (_, v, child) => Opacity(opacity: v, child: child),
                                    child: Text(tabs[i].label, maxLines: 1, softWrap: false, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.base)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class SoonPage extends StatelessWidget {
  const SoonPage({super.key, required this.kicker, required this.light, required this.bold, required this.line, required this.phase, required this.icon});
  final String kicker, light, bold, line;
  final int phase;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: pagePad,
      children: [
        Reveal(child: Kicker(kicker)),
        const SizedBox(height: 14),
        Reveal(delayMs: 120, child: Text(light, style: h1Light)),
        Reveal(delayMs: 240, child: Text(bold, style: h1Bold)),
        const SizedBox(height: 28),
        Reveal(
          delayMs: 420,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: C.lime, size: 30),
                const SizedBox(height: 16),
                Text(line, style: const TextStyle(fontSize: 16, height: 1.5, color: C.text)),
                const SizedBox(height: 18),
                Chip2('Arrives in Phase $phase'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
