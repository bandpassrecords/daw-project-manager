# DAW Project Manager

A cross-platform desktop application built with Flutter for managing and organizing Digital Audio Workstation (DAW) project files. Track your music production projects, manage metadata, organize releases, and keep your creative workflow organized.

## Features

### Project Management
- **Multi-DAW Support**: Automatically detects and manages projects from 13+ popular DAWs
- **Lightweight Scanning**: Fast initial scan that only extracts DAW type information
- **Deep Metadata Extraction**: Optional full metadata extraction (BPM, key, DAW version) on-demand
- **Project Organization**: Organize projects by status (Idea, Arranging, Mixing, Mastering, Finished)
- **Custom Metadata**: Add custom display names, BPM, musical key, and notes to each project
- **Todo Lists**: Track tasks and todos for each project
- **Project Hiding**: Hide projects from the main list without deleting them
- **Quick Launch**: Launch projects directly in their respective DAWs

### Release Management
- **Release Organization**: Group projects into releases with metadata
- **Release Files**: Attach files (stems, mixes, artwork) to releases
- **Release Status Tracking**: Track release status and completion

### Profile System
- **Multiple Profiles**: Create and switch between multiple user profiles
- **Profile-Specific Roots**: Each profile can have its own set of scan root directories
- **Profile Persistence**: All data is stored per-profile using Hive database

### User Interface
- **Custom Window Controls**: Native-feeling window controls for Windows and macOS
- **Dark Theme**: Modern dark theme optimized for long production sessions
- **Advanced Table View**: Sortable, filterable project table with PlutoGrid
- **Search Functionality**: Quick search across all projects
- **Responsive Layout**: Adapts to different window sizes

### Internationalization
- **9 Languages Supported**: English, Portuguese, Spanish, French, Italian, German, Russian, Japanese, Chinese
- **Language Switcher**: Easy language switching from the UI
- **Localized Interface**: All UI elements are translated

## Supported DAWs

The application supports projects from the following Digital Audio Workstations:

- **Ableton Live** (`.als`, `.alp`)
- **Bitwig Studio** (`.bwproject`)
- **Cubase** (`.cpr`)
- **FL Studio** (`.flp`)
- **Logic Pro** (`.logicx`)
- **Maschine** (`.maschine`, `.maschine2`)
- **Nuendo** (`.npr`)
- **Pro Tools** (`.ptx`, `.pts`)
- **Reaper** (`.rpp`)
- **Studio One** (`.song`)

## Requirements

### Development
- **Flutter SDK**: 3.24.x or higher
- **Dart SDK**: 3.9.2 or higher (included with Flutter)
- **Platform Support**:
  - Windows 10/11 (x64)
  - macOS 10.14+ (Intel/Apple Silicon)
  - Linux (experimental)

### Runtime
- **Windows**: Windows 10 or later (64-bit)
- **macOS**: macOS 10.14 or later
- **Disk Space**: ~100 MB for application + storage for project database

## Installation

### Pre-built Releases

Download the latest release from the [Releases page](https://github.com/yourusername/daw_project_manager/releases):

- **Windows**: Download `DAW_Project_Manager_Installer_vX.X.X.exe` and run the installer
- **macOS**: Download `DAW_Project_Manager_macOS_vX.X.X.zip`, extract, and move the app to Applications

### Building from Source

#### Prerequisites

1. Install Flutter SDK:
   ```bash
   # Follow official Flutter installation guide
   # https://docs.flutter.dev/get-started/install
   ```

2. Verify Flutter installation:
   ```bash
   flutter doctor
   ```

#### Build Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/daw_project_manager.git
   cd daw_project_manager
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate localization files**:
   ```bash
   flutter gen-l10n
   ```

4. **Generate Hive adapters** (for data models):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Build for your platform**:

   **Windows**:
   ```bash
   flutter build windows --release
   ```
   The executable will be in `build\windows\x64\runner\Release\`

   **macOS**:
   ```bash
   flutter build macos --release
   ```
   The app bundle will be in `build\macos\Build\Products\Release\`

   **Linux**:
   ```bash
   flutter build linux --release
   ```

## Development

### Project Structure

```
lib/
├── generated/          # Generated files (localizations, Hive adapters)
│   └── l10n/          # Localization files
├── l10n/              # ARB translation files
├── main.dart          # Application entry point
├── models/            # Data models (MusicProject, Release, Profile, etc.)
├── providers/         # Riverpod state management
├── repository/        # Data persistence layer (Hive)
├── services/          # Business logic (Scanner, MetadataExtractor)
├── ui/                # UI components
│   ├── dashboard_page.dart
│   ├── project_detail_page.dart
│   ├── release_detail_page.dart
│   ├── profile_manager_page.dart
│   └── widgets/       # Reusable widgets
└── utils/             # Utility functions
```

### Development Setup

1. **Fork and clone the repository**

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate required files**:
   ```bash
   # Generate localizations
   flutter gen-l10n
   
   # Generate Hive adapters
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run in development mode**:
   ```bash
   flutter run -d windows    # Windows
   flutter run -d macos       # macOS
   flutter run -d linux       # Linux
   ```

### Code Generation

The project uses code generation for:
- **Hive Adapters**: Run `dart run build_runner build` after modifying models
- **Localizations**: Run `flutter gen-l10n` after modifying `.arb` files

### Adding Translations

1. Edit the appropriate `.arb` file in `lib/l10n/`:
   - `app_en.arb` - English (template)
   - `app_pt.arb` - Portuguese
   - `app_es.arb` - Spanish
   - etc.

2. Regenerate localization files:
   ```bash
   flutter gen-l10n
   ```

3. Use in code:
   ```dart
   final l10n = AppLocalizations.of(context);
   Text(l10n.someKey);
   ```

### State Management

The project uses **Riverpod** for state management:
- Providers are defined in `lib/providers/providers.dart`
- Use `ConsumerWidget` or `ConsumerStatefulWidget` to access providers
- Example:
  ```dart
  class MyWidget extends ConsumerWidget {
    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final projects = ref.watch(projectsProvider);
      // ...
    }
  }
  ```

### Data Persistence

Data is stored using **Hive** (NoSQL database):
- Each profile has its own Hive box
- Data is stored in the platform's app data directory
- Models are annotated with `@HiveType` and `@HiveField`

### Testing

Run tests with:
```bash
flutter test
```

### Debugging

Enable debug mode for additional logging:
- The app automatically uses debug mode when running `flutter run`
- Window title bar is visible in debug mode
- Check console output for debug messages

## Configuration

### Scan Roots

Add directories to scan for projects:
1. Click "Add Folder" in the dashboard
2. Select a directory containing DAW project files
3. The app will automatically scan for supported project files

### Profiles

Create and manage profiles:
1. Click the profile button in the top bar
2. Create a new profile or switch between existing ones
3. Each profile maintains its own projects and scan roots

## Troubleshooting

### Build Issues

**Error: Couldn't resolve package 'flutter_gen'**
- Run `flutter clean` and `flutter pub get`
- Ensure `flutter gen-l10n` has been run

**Error: Hive adapter not found**
- Run `dart run build_runner build --delete-conflicting-outputs`

**Error: Localization files not found**
- Run `flutter gen-l10n` to generate localization files
- Check that `l10n.yaml` is properly configured

### Runtime Issues

**Projects not appearing after scan**
- Check that the file extensions are supported
- Verify the scan root directory is accessible
- Check console for error messages

**Metadata not extracting**
- Use "Deep Scan" or "Extract Metadata" for full metadata extraction
- Some DAWs may not store metadata in accessible formats
- Check file permissions

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and ensure code quality:
   ```bash
   flutter analyze
   flutter test
   ```
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small
- Write tests for new features

## License

[Add your license information here]

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- State management with [Riverpod](https://riverpod.dev/)
- Data persistence with [Hive](https://pub.dev/packages/hive)
- Table component with [PlutoGrid](https://pub.dev/packages/pluto_grid)
- Window management with [window_manager](https://pub.dev/packages/window_manager)

---

For questions, issues, or feature requests, please open an issue on GitHub.
