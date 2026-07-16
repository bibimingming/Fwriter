import 'package:flutter/material.dart';

class AppTheme {
  /// 从种子颜色生成 MD3 ColorScheme
  static ColorScheme _createColorScheme(Color seedColor, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      // 使用 Material 3 默认配置
    );
  }

  /// 生成亮色主题（接受种子颜色）
  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = _createColorScheme(seedColor, Brightness.light);
    return _buildTheme(colorScheme, Brightness.light);
  }

  /// 生成暗色主题（接受种子颜色）
  static ThemeData darkTheme(Color seedColor) {
    final colorScheme = _createColorScheme(seedColor, Brightness.dark);
    return _buildTheme(colorScheme, Brightness.dark);
  }

  /// 从 ColorScheme 直接构建亮色主题（main.dart 中 DynamicColorBuilder 使用）
  static ThemeData buildLightTheme(ColorScheme colorScheme) {
    return _buildTheme(colorScheme, Brightness.light);
  }

  /// 从 ColorScheme 直接构建暗色主题（main.dart 中 DynamicColorBuilder 使用）
  static ThemeData buildDarkTheme(ColorScheme colorScheme) {
    return _buildTheme(colorScheme, Brightness.dark);
  }

  /// 构建完整的 MD3 ThemeData
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,

      // AppBar 样式
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // 卡片样式
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: colorScheme.primaryContainer,
      ),

      // 输入框样式（编辑器核心）
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: InputBorder.none,
        outlineBorder: const BorderSide(style: BorderStyle.none),
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isCollapsed: true,
      ),

      // FAB 样式
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 底部导航栏
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // 文本样式 - 编辑器主体
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 18,
          height: 1.8,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          height: 1.8,
          letterSpacing: 0.3,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // 分割线
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),

      // 对话框
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // 列表图块
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
