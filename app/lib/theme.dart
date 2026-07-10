import 'package:flutter/material.dart';

const appBg = Color(0xfff7f9fc);
const appSurface = Color(0xffffffff);
const appSurfaceAlt = Color(0xfff0f5fa);
const appText = Color(0xff081321);
const appMuted = Color(0xff5d7087);
const appLine = Color(0xffd8e2ef);
const appGreen = Color(0xff16845b);
const appBlue = Color(0xff128cff);
const appAmber = Color(0xffb7791f);
const appDanger = Color(0xffc24135);

const _lightAdminColors = AdminThemeColors(
  background: appBg,
  surface: appSurface,
  surfaceAlt: appSurfaceAlt,
  text: appText,
  muted: appMuted,
  line: appLine,
  green: appGreen,
  blue: appBlue,
  amber: appAmber,
  danger: appDanger,
);

const _darkAdminColors = AdminThemeColors(
  background: Color(0xff07111d),
  surface: Color(0xff0b1726),
  surfaceAlt: Color(0xff081321),
  text: Color(0xfff5f8fc),
  muted: Color(0xff8da0b6),
  line: Color(0xff223249),
  green: Color(0xff34d399),
  blue: Color(0xff19d8f2),
  amber: Color(0xfff2d36b),
  danger: Color(0xffff7d73),
);

class AdminThemeColors extends ThemeExtension<AdminThemeColors> {
  const AdminThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.muted,
    required this.line,
    required this.green,
    required this.blue,
    required this.amber,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color muted;
  final Color line;
  final Color green;
  final Color blue;
  final Color amber;
  final Color danger;

  @override
  AdminThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? text,
    Color? muted,
    Color? line,
    Color? green,
    Color? blue,
    Color? amber,
    Color? danger,
  }) {
    return AdminThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      amber: amber ?? this.amber,
      danger: danger ?? this.danger,
    );
  }

  @override
  AdminThemeColors lerp(ThemeExtension<AdminThemeColors>? other, double t) {
    if (other is! AdminThemeColors) {
      return this;
    }
    Color blend(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AdminThemeColors(
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      surfaceAlt: blend(surfaceAlt, other.surfaceAlt),
      text: blend(text, other.text),
      muted: blend(muted, other.muted),
      line: blend(line, other.line),
      green: blend(green, other.green),
      blue: blend(blue, other.blue),
      amber: blend(amber, other.amber),
      danger: blend(danger, other.danger),
    );
  }
}

extension AdminThemeContext on BuildContext {
  AdminThemeColors get adminColors =>
      Theme.of(this).extension<AdminThemeColors>()!;
}

ThemeData buildAdminTheme([Brightness brightness = Brightness.light]) {
  final colors = brightness == Brightness.dark
      ? _darkAdminColors
      : _lightAdminColors;
  final scheme = brightness == Brightness.dark
      ? ColorScheme.dark(
          primary: colors.blue,
          secondary: colors.green,
          tertiary: colors.amber,
          surface: colors.surface,
          error: colors.danger,
          onSurface: colors.text,
        )
      : ColorScheme.light(
          primary: colors.blue,
          secondary: colors.green,
          tertiary: colors.amber,
          surface: colors.surface,
          error: colors.danger,
          onSurface: colors.text,
        );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    dividerColor: colors.line,
    extensions: [colors],
    fontFamily: 'Inter',
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.08,
        color: colors.text,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: colors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: colors.text,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: colors.text),
      bodySmall: TextStyle(fontSize: 12, color: colors.muted, height: 1.35),
      labelLarge: TextStyle(fontWeight: FontWeight.w800, color: colors.text),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.text,
      surfaceTintColor: colors.surface,
      elevation: 0,
    ),
    drawerTheme: DrawerThemeData(backgroundColor: colors.surface),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1),
    iconTheme: IconThemeData(color: colors.muted),
    listTileTheme: ListTileThemeData(
      iconColor: colors.muted,
      selectedColor: colors.blue,
      selectedTileColor: colors.surfaceAlt,
      textColor: colors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      hintStyle: TextStyle(color: colors.muted),
      labelStyle: TextStyle(color: colors.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.blue),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(40, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(40, 46),
        foregroundColor: colors.text,
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colors.blue),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surface,
      textStyle: TextStyle(color: colors.text),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceAlt,
      contentTextStyle: TextStyle(color: colors.text),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(colors.surfaceAlt),
      dividerThickness: .8,
      headingTextStyle: TextStyle(
        color: colors.text,
        fontWeight: FontWeight.w800,
      ),
      dataTextStyle: TextStyle(color: colors.text),
    ),
  );
}
