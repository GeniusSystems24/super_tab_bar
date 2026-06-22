// super_tab_bar · Example app launcher
//
// Opens a simple launcher screen listing the three examples.
// Each example is a self-contained StatefulWidget that can be run
// independently — push to it from this launcher or set it directly
// as the MaterialApp home for faster iteration.

import 'package:flutter/material.dart';
import 'package:super_tab_bar/super_tab_bar.dart';

import 'example_01_basic_workspace.dart';
import 'example_02_document_shell.dart';
import 'example_03_theme_rtl_overflow.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'super_tab_bar examples',
      debugShowCheckedModeBanner: false,
      // Register both presets — the examples toggle between them.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A7CFF)),
        extensions: const [BrowserStyleTabBarThemeData.light],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A7CFF), brightness: Brightness.dark),
        extensions: const [BrowserStyleTabBarThemeData.dark],
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: LauncherScreen(
        dark: _dark,
        onToggleTheme: (v) => setState(() => _dark = v),
      ),
    );
  }
}

class LauncherScreen extends StatelessWidget {
  final bool dark;
  final ValueChanged<bool> onToggleTheme;
  const LauncherScreen(
      {super.key, required this.dark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final examples = [
      (
        '01 · Basic workspace & state preservation',
        'Four tabs, each with a counter + text field + scroll list.\n'
            'Keep-alive vs Rebuild toggle + LTR/RTL toggle.',
        const BasicWorkspaceExample(),
      ),
      (
        '02 · Document management shell',
        'ERP-style workspace: pinned CoA tab, dirty Journal Entry form,\n'
            'open-from-row via of(context), save flow, onAddTab intercept.',
        const DocumentShellExample(),
      ),
      (
        '03 · Custom theme + RTL + overflow',
        'copyWith accent, Dark/Light toggle, LTR/RTL toggle,\n'
            '12+ tabs forcing overflow chevrons + ▾ list.',
        const ThemeRtlOverflowExample(),
      ),
    ];

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        elevation: 0,
        title: Text(
          'super_tab_bar',
          style: TextStyle(
              fontFamily: BrowserStyleTabBarThemeData.displayFont,
              fontWeight: FontWeight.w800,
              color: s.fg1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => onToggleTheme(!dark),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: s.inputBg,
                  border: Border.all(color: s.border),
                  borderRadius: BorderRadius.circular(
                      BrowserStyleTabBarThemeData.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                        dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 15,
                        color: s.fg2),
                    const SizedBox(width: 6),
                    Text(dark ? 'Light' : 'Dark',
                        style: TextStyle(
                            fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: s.fg1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: examples.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final ex = examples[i];
          return _ExampleTile(
            title: ex.$1,
            desc: ex.$2,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => ex.$3),
            ),
          );
        },
      ),
    );
  }
}

class _ExampleTile extends StatefulWidget {
  final String title, desc;
  final VoidCallback onTap;
  const _ExampleTile(
      {required this.title, required this.desc, required this.onTap});
  @override
  State<_ExampleTile> createState() => _ExampleTileState();
}

class _ExampleTileState extends State<_ExampleTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BrowserStyleTabBarThemeData.durBase,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hover ? s.hover : s.surface,
            border: Border.all(
                color: _hover
                    ? BrowserStyleTabBarThemeData.accent
                    : s.border),
            borderRadius: BorderRadius.circular(
                BrowserStyleTabBarThemeData.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrowserStyleTabBarThemeData.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(
                      BrowserStyleTabBarThemeData.radiusMd),
                ),
                child: const Icon(Icons.tab_outlined,
                    size: 20,
                    color: BrowserStyleTabBarThemeData.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            fontFamily:
                                BrowserStyleTabBarThemeData.bodyFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: s.fg1)),
                    const SizedBox(height: 4),
                    Text(widget.desc,
                        style: TextStyle(
                            fontFamily:
                                BrowserStyleTabBarThemeData.bodyFont,
                            fontSize: 12.5,
                            height: 1.5,
                            color: s.fg3)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: s.fg3),
            ],
          ),
        ),
      ),
    );
  }
}
