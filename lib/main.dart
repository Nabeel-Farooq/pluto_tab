import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'backend/backend_service.dart';
import 'backend/rest_backend_service.dart';

import 'home/home.dart';

import 'resources/colors.dart';

import 'utils/drop_delegate.dart';
import 'utils/geocoding_service.dart';
import 'utils/storage_manager.dart';
import 'utils/weather_service.dart';

final GetIt locator = GetIt.instance;

late final PackageInfo packageInfo;

Future<void> main() async {
  WidgetsFlutterBinding binding =
      WidgetsFlutterBinding.ensureInitialized();

  _configureWindowRendering(binding);

  await initialize();

  runApp(const PlutoApp());
}

/// Disable automatic system UI adjustments
/// for all render views.
void _configureWindowRendering(
  WidgetsFlutterBinding binding,
) {
  for (final view in binding.renderViews) {
    view.automaticSystemUiAdjustment = false;
  }
}

/// Load package information from platform.
Future<void> loadPackageInfo() async {
  packageInfo = await PackageInfo.fromPlatform();
}

class PlutoApp extends StatefulWidget {
  const PlutoApp({super.key});

  @override
  State<PlutoApp> createState() => _PlutoAppState();
}

class _PlutoAppState extends State<PlutoApp> {
  final ValueNotifier<bool> _windowDragNotifier =
      ValueNotifier<bool>(false);

  late final DragAndDropDelegate _dropDelegate =
      DragAndDropDelegate(
    dragNotifier: _windowDragNotifier,
  );

  @override
  void dispose() {
    _windowDragNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DebugRender(
      debugHighlightObserverRebuild: false,
      child: MaterialApp(
        title: 'Pluto',

        debugShowCheckedModeBanner: false,

        theme: buildTheme(),

        builder: _buildDropRegion,

        home: const HomeWrapper(
          key: ValueKey('HomeWrapper'),
        ),
      ),
    );
  }

  Widget _buildDropRegion(
    BuildContext context,
    Widget? child,
  ) {
    return DropRegion(
      formats: Formats.standardFormats,

      onDropEnter: (_) {
        _windowDragNotifier.value = true;
      },

      onDropLeave: (_) {
        _windowDragNotifier.value = false;
      },

      onDropOver: (_) => DropOperation.copy,

      onPerformDrop: (_) async {
        _windowDragNotifier.value = false;
      },

      child: DragAndDropScope(
        delegate: _dropDelegate,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Initialize all app services.
Future<void> initialize() async {
  await initializeBackend();

  final storage =
      await SharedPreferencesStorageManager.create();

  locator.registerSingleton<LocalStorageManager>(
    storage,
  );

  locator.registerSingleton<WeatherService>(
    OpenMeteoWeatherService(),
  );

  locator.registerSingleton<GeocodingService>(
    OpenMeteoGeocodingService(),
  );

  await locator.allReady();

  await loadPackageInfo();
}

/// Initialize backend service.
Future<void> initializeBackend() async {
  final BackendService service = await getBackend();

  await service.init(
    local: useLocalServer,
  );

  locator.registerSingleton<BackendService>(
    service,
  );
}

/// Return backend implementation.
Future<BackendService> getBackend() async {
  return RestBackendService();
}

/// App theme configuration.
ThemeData buildTheme() {
  const textStyle = TextStyle(
    color: AppColors.textColor,
  );

  return ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    scaffoldBackgroundColor: Colors.black,

    dividerColor: AppColors.borderColor,

    colorScheme: ColorScheme.fromSeed(
      seedColor: CupertinoColors.systemBlue,
      brightness: Brightness.dark,
      primary: CupertinoColors.systemBlue,
    ),

    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(4),
      thumbVisibility: WidgetStateProperty.all(true),
    ),

    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(
        milliseconds: 300,
      ),

      verticalOffset: 18,

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),

      textStyle: const TextStyle(
        fontSize: 12,
        color: Colors.white60,
      ),

      decoration: ShapeDecoration(
        color: Colors.grey.shade900,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: textStyle,
      displayMedium: textStyle,
      displaySmall: textStyle,

      headlineMedium: textStyle,
      headlineSmall: textStyle,

      titleLarge: textStyle,

      bodyLarge: textStyle,
      bodyMedium: textStyle,
    ),
  );
}

class DebugRender extends InheritedWidget {
  final bool debugHighlightObserverRebuild;

  const DebugRender({
    super.key,
    required super.child,
    this.debugHighlightObserverRebuild = false,
  });

  static DebugRender? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DebugRender>();
  }

  @override
  bool updateShouldNotify(
    covariant DebugRender oldWidget,
  ) {
    return debugHighlightObserverRebuild !=
        oldWidget.debugHighlightObserverRebuild;
  }
}
