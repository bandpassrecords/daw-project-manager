# Internationalization (i18n) Setup Guide for DAW Project Manager

## Overview
This guide explains how to add translation support to your Flutter application using Flutter's built-in localization system.

## Step 1: Update pubspec.yaml

Add `flutter_localizations` to your dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # ... your existing dependencies
```

Add the localization configuration:

```yaml
flutter:
  generate: true  # Enable code generation for l10n
  # ... rest of your flutter config
```

## Step 2: Create l10n.yaml Configuration File

Create `l10n.yaml` in the root of your project:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

## Step 3: Create Translation Files (ARB Format)

Create the directory: `lib/l10n/`

Create `app_en.arb` (English - base language):
```json
{
  "@@locale": "en",
  "appTitle": "DAW Project Manager",
  "@appTitle": {
    "description": "The application title"
  },
  "projectDetails": "Project Details",
  "back": "Back",
  "save": "Save",
  "cancel": "Cancel",
  "launch": "Launch",
  "view": "View",
  "openFolder": "Open Folder",
  "extract": "Extract",
  "extracting": "Extracting…",
  "extractingMetadata": "Extracting metadata...",
  "deepScan": "Deep Scan",
  "rescan": "Rescan",
  "scanning": "Scanning…",
  "projectName": "Project Name",
  "bpm": "BPM",
  "key": "Key (e.g., C#m, F major)",
  "notes": "Notes",
  "projectPhase": "Project Phase",
  "failedToLoad": "Failed to load",
  "fileMissing": "File missing.",
  "launchingProject": "Launching {projectName}…",
  "@launchingProject": {
    "placeholders": {
      "projectName": {
        "type": "String"
      }
    }
  },
  "clearLibrary": "Clear Library",
  "clearLibraryMessage": "This will remove all saved projects and source folders. Continue?",
  "clear": "Clear",
  "roots": "Roots",
  "projects": "Projects",
  "hidden": "hidden",
  "profileManager": "Profile Manager",
  "createNewProfile": "Create New Profile",
  "profileName": "Profile Name",
  "create": "Create",
  "profiles": "Profiles",
  "active": "Active",
  "switch": "Switch",
  "edit": "Edit",
  "delete": "Delete",
  "addFolder": "Add Folder",
  "searchProjects": "Search projects..."
}
```

Create `app_pt.arb` (Portuguese example):
```json
{
  "@@locale": "pt",
  "appTitle": "Gerenciador de Projetos DAW",
  "projectDetails": "Detalhes do Projeto",
  "back": "Voltar",
  "save": "Salvar",
  "cancel": "Cancelar",
  "launch": "Abrir",
  "view": "Ver",
  "openFolder": "Abrir Pasta",
  "extract": "Extrair",
  "extracting": "Extraindo…",
  "extractingMetadata": "Extraindo metadados...",
  "deepScan": "Varredura Profunda",
  "rescan": "Reescanear",
  "scanning": "Escaneando…",
  "projectName": "Nome do Projeto",
  "bpm": "BPM",
  "key": "Tom (ex: C#m, F maior)",
  "notes": "Notas",
  "projectPhase": "Fase do Projeto",
  "failedToLoad": "Falha ao carregar",
  "fileMissing": "Arquivo ausente.",
  "launchingProject": "Abrindo {projectName}…",
  "clearLibrary": "Limpar Biblioteca",
  "clearLibraryMessage": "Isso removerá todos os projetos salvos e pastas de origem. Continuar?",
  "clear": "Limpar",
  "roots": "Raízes",
  "projects": "Projetos",
  "hidden": "ocultos",
  "profileManager": "Gerenciador de Perfis",
  "createNewProfile": "Criar Novo Perfil",
  "profileName": "Nome do Perfil",
  "create": "Criar",
  "profiles": "Perfis",
  "active": "Ativo",
  "switch": "Alternar",
  "edit": "Editar",
  "delete": "Excluir",
  "addFolder": "Adicionar Pasta",
  "searchProjects": "Pesquisar projetos..."
}
```

## Step 4: Update main.dart

Add localization delegates to MaterialApp:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In MyApp build method:
return MaterialApp(
  title: 'DAW Project Manager',
  // Add these lines:
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en', ''), // English
    Locale('pt', ''), // Portuguese
    // Add more locales as needed
  ],
  // ... rest of your MaterialApp config
);
```

## Step 5: Use Translations in Your Code

Replace hardcoded strings with translations:

**Before:**
```dart
Text('Project Details')
```

**After:**
```dart
Text(AppLocalizations.of(context)!.projectDetails)
```

**For strings with parameters:**
```dart
// Before:
Text('Launching ${project.displayName}…')

// After:
Text(AppLocalizations.of(context)!.launchingProject(project.displayName))
```

## Step 6: Generate Localization Code

Run this command to generate the localization code:

```bash
flutter gen-l10n
```

Or it will be generated automatically when you run `flutter pub get` if `generate: true` is set in pubspec.yaml.

## Step 7: Add Language Selection (Optional)

You can add a language switcher using a provider or state management:

```dart
// Create a locale provider
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

// In MaterialApp:
locale: ref.watch(localeProvider),

// In your settings UI:
DropdownButton<Locale>(
  value: ref.watch(localeProvider),
  items: [
    DropdownMenuItem(value: Locale('en'), child: Text('English')),
    DropdownMenuItem(value: Locale('pt'), child: Text('Português')),
  ],
  onChanged: (locale) {
    ref.read(localeProvider.notifier).state = locale!;
  },
)
```

## Step 8: Handle Pluralization and Gender (Advanced)

ARB files support pluralization:

```json
{
  "projectCount": "{count, plural, =0{No projects} =1{One project} other{{count} projects}}",
  "@projectCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

Usage:
```dart
AppLocalizations.of(context)!.projectCount(5) // "5 projects"
```

## Best Practices

1. **Extract all strings**: Go through your UI files and identify all hardcoded strings
2. **Use descriptive keys**: Name your translation keys clearly (e.g., `projectDetails` not `pd`)
3. **Keep context**: Add descriptions in ARB files using `@key` annotations
4. **Test all languages**: Make sure UI doesn't break with longer translations
5. **Handle missing translations**: Flutter will fall back to the base language if a translation is missing

## Migration Checklist

- [ ] Update pubspec.yaml
- [ ] Create l10n.yaml
- [ ] Create lib/l10n/ directory
- [ ] Create app_en.arb with all English strings
- [ ] Update main.dart with localization delegates
- [ ] Run `flutter gen-l10n`
- [ ] Replace hardcoded strings in dashboard_page.dart
- [ ] Replace hardcoded strings in project_detail_page.dart
- [ ] Replace hardcoded strings in release_detail_page.dart
- [ ] Replace hardcoded strings in profile_manager_page.dart
- [ ] Create additional language files (pt, es, etc.)
- [ ] Test with different locales
- [ ] Add language switcher (optional)


