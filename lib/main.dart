import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

// NOVO: Importar providers e serviços para a lógica de auto-scan
import 'providers/providers.dart';
import 'repository/project_repository.dart';
import 'services/scanner_service.dart';

import 'ui/dashboard_page.dart';

// NOVO: Função para executar o scan
Future<void> _runInitialScan(ProjectRepository repo, ProviderContainer container) async {
  try {
    // 1. Limpa arquivos que não existem mais
    await repo.clearMissingFiles();
    
    // 2. Cria o scanner e processa as raízes de scan
    final scanner = ScannerService();
    final scanTime = DateTime.now();
    for (final root in repo.getRoots()) {
      await for (final entity in scanner.scanDirectory(root.path)) {
        await repo.upsertFromFileSystemEntity(entity);
      }
      // Update lastScanAt timestamp for this root
      await repo.updateRootLastScanAt(root.id, scanTime);
    }
    
    // 3. Mark initial scan as complete
    container.read(initialScanStateProvider.notifier).complete();
    
    if (kDebugMode) {
      print("Initial scan completed successfully.");
    }
  } catch (e, st) {
    // Mark as complete even on error so UI doesn't stay frozen
    container.read(initialScanStateProvider.notifier).complete();
    if (kDebugMode) {
      print("Error during initial scan: $e");
      print(st);
    }
  }
}


void main() async {
  // 1. Inicialização do Flutter e Window Manager
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 2. Configurações da Janela
  const initialSize = Size(1800, 1040); // Fits comfortably on 1080p screens
  const minimumSize = Size(800, 600); // Allow resizing to a smaller minimum size
  WindowOptions windowOptions = WindowOptions(
    size: initialSize,
    minimumSize: minimumSize,
    center: true,
    title: "DAW Project Manager",
    titleBarStyle: kDebugMode ? TitleBarStyle.normal : TitleBarStyle.hidden,
  );
  
  // 3. Criação e exibição da janela
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // NOVO: 4. Configuração do Riverpod e Auto-Scan
  final container = ProviderContainer();
  try {
    // 4a. Pré-carrega o ProfileRepository primeiro
    final profileRepo = await container.read(profileRepositoryProvider.future);
    
    // 4b. Pré-carrega o ProjectRepository (que depende do ProfileRepository)
    final repo = await container.read(repositoryProvider.future);
    
    // 4c. Executa o Scan Inicial em segundo plano (não aguardamos o Future)
    // O await repo... em cima garante que o Hive está pronto antes do scan.
    _runInitialScan(repo, container);
    
  } catch (e) {
    // Mark as complete even on error
    container.read(initialScanStateProvider.notifier).complete();
    if (kDebugMode) print("Failed to initialize repository or run initial scan: $e");
  }


  // 5. Roda o app com o container já configurado
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

// ... (O resto da classe MyApp permanece o mesmo)
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5A6B7A), 
      brightness: Brightness.dark,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: const Color(0xFF1E1F22),
      canvasColor: const Color(0xFF1E1F22),
      cardColor: const Color(0xFF2B2D31),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2B2D31),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dividerColor: const Color(0xFF3C3F43),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A6B7A), foregroundColor: Colors.white),
      )
    );

    final currentLocale = ref.watch(localeProvider);
    
    return MaterialApp(
      key: ValueKey('locale_${currentLocale.languageCode}'), // Force rebuild on locale change
      title: 'DAW Project Manager',
      themeMode: ThemeMode.dark,
      theme: baseTheme,
      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('pt', ''), // Portuguese
        Locale('es', ''), // Spanish
        Locale('fr', ''), // French
        Locale('it', ''), // Italian
        Locale('de', ''), // German
        Locale('ru', ''), // Russian
        Locale('ja', ''), // Japanese
        Locale('zh', ''), // Chinese
      ],
      locale: currentLocale,
      // Remove localeResolutionCallback - let Flutter handle it automatically
      // The locale from provider will be used directly
      home: const DashboardPage(),
    );
  }
}
