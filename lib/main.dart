import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/app_theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/novel_provider.dart';
import 'providers/editor_provider.dart';
import 'providers/search_provider.dart';
import 'providers/statistics_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NovelProvider()),
        ChangeNotifierProvider(create: (_) => EditorProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<AppThemeProvider>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (themeProv.useDynamicColor &&
            lightDynamic != null &&
            darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else if (themeProv.seedColor != null) {
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: themeProv.seedColor!,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: themeProv.seedColor!,
            brightness: Brightness.dark,
          );
        } else {
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: '喵喵写作',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(lightColorScheme),
          darkTheme: AppTheme.buildDarkTheme(darkColorScheme),
          themeMode: themeProv.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
