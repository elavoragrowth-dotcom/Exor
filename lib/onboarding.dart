import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';
import 'versind_widgets.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.store});
  final AppStore store;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with SingleTickerProviderStateMixin {
  int _step = 0;
  int _hour = 6;
  int _accentIndex = 0;
  bool _notifications = true;
  final _name = TextEditingController();
  final _picker = FixedExtentScrollController(initialItem: 6);

  // The first moment of the app is dark and quiet; this veil lifts to let the aurora in.
  late final AnimationController _veil = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  bool _veilStarted = false;

  bool get _hasName => _name.text.trim().isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_veilStarted) return;
    _veilStarted = true;
    if (MediaQuery.of(context).disableAnimations) {
      _veil.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _veil.forward();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _picker.dispose();
    _veil.dispose();
    super.dispose();
  }

  void _go(int s) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = s);
  }

  Widget _welcome() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WelcomeBrand(),
          const SizedBox(height: 34),
          const Reveal(delayMs: 1900, child: Kicker('WELCOME')),
          const SizedBox(height: 14),
          const Reveal(delayMs: 2050, child: Text('Every day is', style: h1Light)),
          const Reveal(
            delayMs: 2200,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'a page ', style: h1Bold),
                TextSpan(text: 'worth filling', style: TextStyle(fontFamily: 'GreatVibes', fontSize: 46, height: 1.0, fontWeight: FontWeight.w400, color: C.lime)),
                TextSpan(text: '.', style: h1Bold),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          const Reveal(
            delayMs: 2400,
            child: Text(
              'Habits, plans, chapters and focus, woven into one calm place. A few quick questions so it can feel like yours.',
              style: subStyle,
            ),
          ),
          const SizedBox(height: 40),
          Reveal(delayMs: 2600, child: PillButton(label: 'Begin', onTap: () => _go(1))),
        ],
      );

  Widget _nameStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(delayMs: 100, child: Kicker('01 · YOU')),
          const SizedBox(height: 14),
          const Reveal(delayMs: 220, child: Text('First things first,', style: h1Light)),
          const Reveal(delayMs: 340, child: Text('what should I call you?', style: h1Bold)),
          const SizedBox(height: 32),
          Reveal(
            delayMs: 520,
            child: Glass(
              radius: 40,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                cursorColor: C.lime,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: C.text),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Your name',
                  hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: C.mute),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_hasName) _go(2);
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          Reveal(delayMs: 680, child: PillButton(label: 'Continue', enabled: _hasName, onTap: () => _go(2))),
        ],
      );

  Widget _hourStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(delayMs: 100, child: Kicker('02 · YOUR RHYTHM')),
          const SizedBox(height: 14),
          Reveal(delayMs: 220, child: Text('${_name.text.trim()}, when does', style: h1Light)),
          const Reveal(delayMs: 340, child: Text('your day begin?', style: h1Bold)),
          const SizedBox(height: 12),
          const Reveal(delayMs: 460, child: Text("I'll shape your plan around this hour.", style: subStyle)),
          const SizedBox(height: 24),
          Reveal(
            delayMs: 580,
            child: Glass(
              radius: 32,
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: _picker,
                  itemExtent: 54,
                  backgroundColor: Colors.transparent,
                  useMagnifier: true,
                  magnification: 1.08,
                  onSelectedItemChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _hour = i);
                  },
                  children: List.generate(
                    24,
                    (i) => Center(
                      child: Text(fmtHour(i),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w500, color: C.text)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Reveal(delayMs: 720, child: PillButton(label: 'Continue', onTap: () => _go(3))),
        ],
      );

  Widget _finalStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(delayMs: 100, child: Kicker('03 · ONE LAST TOUCH')),
          const SizedBox(height: 14),
          const Reveal(delayMs: 220, child: Text('Pick a spark,', style: h1Light)),
          const Reveal(delayMs: 340, child: Text('and one small promise.', style: h1Bold)),
          const SizedBox(height: 24),
          const Reveal(
            delayMs: 460,
            child: Text('This colours your buttons and highlights everywhere. Change it anytime in Settings.', style: subStyle),
          ),
          const SizedBox(height: 20),
          // Wrap (not Row): six 48px swatches + gaps are wider than a small phone, which clipped the last (Blue) one.
          Reveal(
            delayMs: 560,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(Accent.presets.length, (i) {
                final on = i == _accentIndex;
                return Semantics(
                  button: true,
                  selected: on,
                  label: Accent.names[i],
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _accentIndex = i;
                        Accent.color = Accent.presets[i];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Accent.presets[i],
                        shape: BoxShape.circle,
                        border: Border.all(color: on ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: on ? [BoxShadow(color: Accent.presets[i].withValues(alpha: 0.5), blurRadius: 18)] : [],
                      ),
                      child: on ? const Icon(Icons.check_rounded, color: C.base) : null,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Reveal(delayMs: 620, child: Text(Accent.names[_accentIndex], style: const TextStyle(color: C.mute, fontSize: 13))),
          const SizedBox(height: 28),
          Reveal(
            delayMs: 700,
            child: Glass(
              radius: 26,
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded, color: C.lime, size: 24),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Gently remind me about my plan', style: TextStyle(fontSize: 14.5, color: C.text))),
                  Switch(value: _notifications, activeColor: C.lime, onChanged: (v) => setState(() => _notifications = v)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Reveal(
            delayMs: 820,
            child: PillButton(
              label: 'Start my day',
              onTap: () {
                widget.store.completeOnboarding(_name.text.trim(), _hour, Accent.presets[_accentIndex], _notifications);
              },
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final pages = [_welcome(), _nameStep(), _hourStep(), _finalStep()];
    return Stack(
      fit: StackFit.expand,
      children: [
        // black veil sits BEHIND the content, above the app background: lifts once, never blocks touches
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _veil,
              builder: (_, __) {
                final a = 1 - Curves.easeInOutCubic.transform(_veil.value);
                return a <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Colors.black.withValues(alpha: a));
              },
            ),
          ),
        ),
        if (_step == 0) const Positioned.fill(child: AmbientMotes()),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 650),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                    child: ScaleTransition(scale: Tween<double>(begin: 0.97, end: 1).animate(anim), child: child),
                  ),
                ),
                child: SizedBox(key: ValueKey(_step), width: double.infinity, child: pages[_step]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
