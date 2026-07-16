import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';

/// MD3 动态取色 Provider
/// 监听系统壁纸颜色变化，自动生成亮/暗主题
class AppThemeProvider extends ChangeNotifier {
  Brightness _brightness = Brightness.light;
  Color? _seedColor;
  bool _followSystemTheme = true;

  Brightness get brightness => _brightness;
  Color? get seedColor => _seedColor;
  bool get followSystemTheme => _followSystemTheme;
  bool get useDynamicColor => _followSystemTheme;
  ThemeMode get themeMode =>
      _followSystemTheme ? ThemeMode.system : (_brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark);

  bool get isDarkMode => _brightness == Brightness.dark;

  /// 切换亮/暗模式
  void toggleBrightness() {
    _brightness =
        _brightness == Brightness.light ? Brightness.dark : Brightness.light;
    notifyListeners();
  }

  /// 设置是否跟随系统主题
  void setFollowSystemTheme(bool value) {
    _followSystemTheme = value;
    notifyListeners();
  }

  /// 手动设置亮暗模式
  void setBrightness(Brightness brightness) {
    _brightness = brightness;
    notifyListeners();
  }

  /// 手动设置种子颜色（覆盖系统取色）
  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  /// 获取当前主题（种子颜色 → MD3 动态主题）
  ThemeData get currentTheme {
    final seed = _seedColor ?? Colors.blue;
    return _brightness == Brightness.light
        ? AppTheme.lightTheme(seed)
        : AppTheme.darkTheme(seed);
  }

  /// 监听系统动态颜色变化
  Color? onDynamicColorChanged(Color? dynamicColor) {
    if (_followSystemTheme && dynamicColor != null) {
      _seedColor = dynamicColor;
      notifyListeners();
    }
    return _seedColor;
  }

  /// 构建 MD3 应用入口组件
  /// 包裹 DynamicColorBuilder 以监听壁纸取色
  static Widget wrapApp(Widget Function(BuildContext context, ThemeData lightTheme, ThemeData darkTheme) builder) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return Builder(
          builder: (context) {
            final provider = context.watch<AppThemeProvider>();
            // 优先使用系统动态颜色
            final lightSeed = lightDynamic?.primary ?? provider.seedColor ?? Colors.blue;
            final darkSeed = darkDynamic?.primary ?? provider.seedColor ?? Colors.blue;
            return builder(
              context,
              AppTheme.lightTheme(lightSeed),
              AppTheme.darkTheme(darkSeed),
            );
          },
        );
      },
    );
  }
}
