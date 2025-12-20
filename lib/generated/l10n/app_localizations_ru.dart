// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Менеджер проектов DAW';

  @override
  String get projectDetails => 'Детали проекта';

  @override
  String get back => 'Назад';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get launch => 'Открыть';

  @override
  String get view => 'Просмотр';

  @override
  String get openFolder => 'Открыть папку';

  @override
  String get openInDaw => 'Открыть в DAW';

  @override
  String get extract => 'Извлечь';

  @override
  String get extracting => 'Извлечение…';

  @override
  String get extractingMetadata => 'Извлечение метаданных...';

  @override
  String get deepScan => 'Глубокое сканирование';

  @override
  String get rescan => 'Повторное сканирование';

  @override
  String get scanning => 'Сканирование…';

  @override
  String get projectName => 'Название проекта';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Тональность (например: C#m, F мажор)';

  @override
  String get notes => 'Заметки';

  @override
  String get projectPhase => 'Фаза проекта';

  @override
  String get failedToLoad => 'Ошибка загрузки';

  @override
  String get fileMissing => 'Файл отсутствует.';

  @override
  String launchingProject(String projectName) {
    return 'Открытие $projectName…';
  }

  @override
  String get clearLibrary => 'Очистить библиотеку';

  @override
  String get clearLibraryMessage =>
      'Это удалит все сохраненные проекты и исходные папки. Продолжить?';

  @override
  String get clear => 'Очистить';

  @override
  String get roots => 'Корни';

  @override
  String get projects => 'Проекты';

  @override
  String get hidden => 'скрытые';

  @override
  String get profileManager => 'Менеджер профилей';

  @override
  String get createNewProfile => 'Создать новый профиль';

  @override
  String get profileName => 'Имя профиля';

  @override
  String get create => 'Создать';

  @override
  String get profiles => 'Профили';

  @override
  String get active => 'Активный';

  @override
  String get switchProfile => 'Переключить';

  @override
  String get edit => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get searchProjects => 'Поиск проектов...';

  @override
  String get deepScanTooltip =>
      'Глубокое сканирование извлекает полные метаданные из файлов проекта:\n• BPM (ударов в минуту)\n• Музыкальная тональность\n• Версия DAW\nЭто медленнее, но предоставляет полную информацию.';

  @override
  String get deepScanConfirm =>
      'Это просканирует все проекты и извлечет полные метаданные (BPM, тональность, версия DAW). Это может занять некоторое время. Продолжить?';

  @override
  String get metadataExtractedSuccessfully => 'Метаданные успешно извлечены';

  @override
  String failedToExtractMetadata(String error) {
    return 'Ошибка извлечения метаданных: $error';
  }

  @override
  String get saved => 'Сохранено';

  @override
  String get failedToLaunchDaw => 'Не удалось открыть DAW';

  @override
  String get releaseDetails => 'Детали релиза';

  @override
  String get releaseNotFound => 'Релиз не найден';

  @override
  String get error => 'Ошибка';

  @override
  String get loading => 'Загрузка...';

  @override
  String get deleteProfile => 'Удалить профиль';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Вы уверены, что хотите удалить \"$profileName\"? Это удалит все проекты, корни и релизы этого профиля.';
  }

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get changePhoto => 'Изменить фото';

  @override
  String get remove => 'Удалить';

  @override
  String get saveName => 'Сохранить имя';

  @override
  String get profilePhotoUpdated => 'Фото профиля обновлено.';

  @override
  String get profilePhotoRemoved => 'Фото профиля удалено.';

  @override
  String profileRenamed(String newName) {
    return 'Профиль переименован в \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Профиль \"$name\" успешно создан';
  }

  @override
  String profileDeleted(String name) {
    return 'Профиль \"$name\" удален';
  }

  @override
  String get pleaseEnterProfileName => 'Пожалуйста, введите имя профиля';

  @override
  String failedToCreateProfile(String error) {
    return 'Ошибка создания профиля: $error';
  }

  @override
  String get noProfilesFound => 'Профили не найдены. Создайте один выше.';

  @override
  String created(String date) {
    return 'Создано: $date';
  }

  @override
  String get toggleSort => 'Переключить сортировку';

  @override
  String get clearLibraryTooltip => 'Очистить библиотеку (проекты и корни)';

  @override
  String lastModified(String date) {
    return 'Последнее изменение: $date';
  }

  @override
  String get name => 'Название';

  @override
  String get status => 'Статус';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Последнее Изменение';

  @override
  String get actions => 'Действия';

  @override
  String get hide => 'Скрыть';

  @override
  String get unhide => 'Показать';

  @override
  String get extractMetadata => 'Извлечь Метаданные';

  @override
  String get createRelease => 'Создать Релиз';

  @override
  String get clearSelection => 'Очистить Выбор';

  @override
  String get selectAllProjects => 'Выбрать все проекты';

  @override
  String get switchingProfiles => 'Переключение профилей...';

  @override
  String get scanningProjects => 'Сканирование проектов...';

  @override
  String get projectsTab => 'Проекты';

  @override
  String get releasesTab => 'Релизы';

  @override
  String get showHidden => 'Показать Скрытые';

  @override
  String get showAll => 'Показать Все';

  @override
  String get showOnlyHidden => 'Показать Только Скрытые';

  @override
  String get deleteRootPath => 'Удалить Корневой Путь';

  @override
  String deleteRootPathMessage(String path) {
    return 'Вы уверены, что хотите удалить \"$path\"? Это также удалит все проекты из этой папки, которые не находятся в релизах.';
  }

  @override
  String rootsCount(int count) {
    return 'Корни: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Проекты: $count';
  }

  @override
  String get hiddenOnly => '(только скрытые)';

  @override
  String hiddenCount(int count) {
    return '($count скрытых)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count проект$plural скрыт$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count проект$plural показан$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Ошибка скрытия проектов: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Ошибка показа проектов: $error';
  }

  @override
  String releaseCreated(String title) {
    return 'Релиз \"$title\" успешно создан.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Ошибка создания релиза: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Ошибка добавления папки: $error';
  }

  @override
  String get noProjectsFoundInRoots => 'Проекты не найдены в выбранных корнях.';

  @override
  String get selectProjectsFolder => 'Выберите папку проектов';

  @override
  String get enterReleaseTitle => 'Введите Название Релиза';

  @override
  String get releaseTitle => 'Название Релиза';

  @override
  String get enterReleaseTitleHint => 'Введите название релиза';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Метаданные извлечены для $count проект$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count не удалось$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Ошибка записи файла BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Ошибка записи файла тональности: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Ошибка открытия: $error';
  }

  @override
  String get libraryCleared => 'Библиотека очищена.';

  @override
  String scanType(String type) {
    return 'Сканирование $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type завершено: $count проект$plural добавлен$plural/обновлен$plural.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count проект$plural выбран$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Открытие папки для $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Ошибка открытия папки: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Операционная система не поддерживается для открытия папки.';

  @override
  String get noProjectsAvailable =>
      'Проекты недоступны. Пожалуйста, сначала добавьте проекты.';

  @override
  String get createNewRelease => 'Создать Новый Релиз';

  @override
  String get deleteRelease => 'Удалить Релиз';

  @override
  String deleteReleaseMessage(String title) {
    return 'Вы уверены, что хотите удалить \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Релиз \"$title\" удален.';
  }

  @override
  String get selectTracks => 'Выбрать Треки';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get noReleasesYet => 'Пока нет релизов';

  @override
  String get createFirstRelease =>
      'Создайте свой первый релиз, выбрав треки из ваших проектов';

  @override
  String releasesCount(int count) {
    return 'Релизы ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Ошибка загрузки релизов: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Треки ($count)';
  }

  @override
  String get addTracks => 'Добавить Треки';

  @override
  String get allProjectsAlreadyInRelease => 'Все проекты уже в этом релизе.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Добавлен$plural $count трек$plural в релиз.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Файлы Релиза ($count)';
  }

  @override
  String get addFiles => 'Добавить Файлы';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Добавлен$plural $count файл$plural в релиз.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Ошибка добавления файлов: $error';
  }

  @override
  String get noFilesToDownload => 'Нет файлов для загрузки.';

  @override
  String zipFileSaved(String path) {
    return 'ZIP файл сохранен в: $path';
  }

  @override
  String failedToCreateZip(String error) {
    return 'Ошибка создания ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Выбранный файл не существует.';

  @override
  String get imageSavedSuccessfully => 'Изображение успешно сохранено!';

  @override
  String failedToSaveImage(String error) {
    return 'Ошибка сохранения изображения: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Ошибка загрузки релиза: $error';
  }

  @override
  String errorLoadingProjects(String error) {
    return 'Ошибка загрузки проектов: $error';
  }

  @override
  String get releaseSaved => 'Релиз сохранен.';

  @override
  String get releaseDate => 'Дата Релиза';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Ошибка сохранения даты релиза: $error';
  }

  @override
  String get releaseDateSaved => 'Дата релиза сохранена.';

  @override
  String get releaseDateCleared => 'Дата релиза очищена.';

  @override
  String get saveReleaseFilesZip => 'Сохранить ZIP файлы релиза';

  @override
  String failedToOpenFile(String error) {
    return 'Ошибка открытия файла: $error';
  }

  @override
  String failedToPlayAudio(String error) {
    return 'Ошибка воспроизведения аудио: $error';
  }

  @override
  String get renameFile => 'Переименовать Файл';

  @override
  String get selectTracksToAdd => 'Выбрать Треки для Добавления';

  @override
  String get fileNameUpdated => 'Имя файла обновлено.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Ошибка обновления имени файла: $error';
  }

  @override
  String get deleteFile => 'Удалить Файл';

  @override
  String deleteFileMessage(String fileName) {
    return 'Вы уверены, что хотите удалить \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Файл \"$fileName\" удален.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Ошибка удаления файла: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Не удалось открыть папку: $error';
  }

  @override
  String get artwork => 'Обложка';

  @override
  String get title => 'Название';

  @override
  String get tracks => 'Треки';

  @override
  String get description => 'Описание';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Выбрать треки для включения в релиз ($count выбрано)';
  }

  @override
  String get searchTracks => 'Поиск треков';

  @override
  String get searchTracksHint => 'Поиск по названию или типу DAW';

  @override
  String get noTracksFound => 'Треки не найдены';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get fileNotFound => 'Файл не найден';

  @override
  String get fileName => 'Имя Файла';

  @override
  String get editTodo => 'Редактировать Задачу';

  @override
  String get todoText => 'Текст задачи';

  @override
  String get enterTodoText => 'Введите текст задачи';

  @override
  String get addNewTodo => 'Добавить новую задачу';

  @override
  String get enterTodoItem => 'Введите элемент задачи';

  @override
  String get todoList => 'Список Задач';

  @override
  String get addToRelease => 'Добавить в Релиз';

  @override
  String get createNew => 'Создать Новый';

  @override
  String get addToExisting => 'Добавить в Существующий';

  @override
  String get createAndAdd => 'Создать и Добавить';

  @override
  String get selectRelease => 'Выберите релиз';

  @override
  String get noExistingReleasesFound => 'Существующие релизы не найдены.';

  @override
  String get addToSelectedRelease => 'Добавить в Выбранный Релиз';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Ошибка сохранения фото профиля: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Ошибка удаления фото профиля: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Ошибка переименования профиля: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Ошибка удаления профиля: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Ошибка загрузки профилей: $error';
  }

  @override
  String get projectPhaseIdea => 'Идея';

  @override
  String get projectPhaseArranging => 'Аранжировка';

  @override
  String get projectPhaseMixing => 'Сведение';

  @override
  String get projectPhaseMastering => 'Мастеринг';

  @override
  String get projectPhaseFinished => 'Завершено';

  @override
  String get tooltipEditProfileName => 'Редактировать имя профиля';

  @override
  String get tooltipAddTodo => 'Добавить задачу';

  @override
  String get tooltipClearDate => 'Очистить дату';

  @override
  String get tooltipPickDate => 'Выбрать дату';

  @override
  String get tooltipViewDetails => 'Просмотр Деталей';

  @override
  String get tooltipLaunchInDaw => 'Открыть в DAW';

  @override
  String get tooltipRemoveFromRelease => 'Удалить из Релиза';

  @override
  String get profile => 'Профиль';

  @override
  String get noDateSet => 'Дата не установлена';

  @override
  String get imageNotFound => 'Изображение не найдено';

  @override
  String get clickToBrowseArtwork => 'Нажмите, чтобы найти обложку';

  @override
  String get noFilesAddedYet =>
      'Файлы еще не добавлены.\nНажмите \"Добавить Файлы\", чтобы загрузить файлы релиза.';

  @override
  String get noTodosYet => 'Задач пока нет. Добавьте одну выше.';

  @override
  String get done => 'Готово';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get backupExportedSuccessfully => 'Backup exported successfully';

  @override
  String failedToExportBackup(String error) {
    return 'Failed to export backup: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup imported successfully: $projectsCount projects, $rootsCount roots, $releasesCount releases';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Failed to import backup: $error';
  }

  @override
  String get importBackupMessage => 'Choose how to import the backup:';

  @override
  String get mergeWithCurrentProfile => 'Merge with current active profile';

  @override
  String get replaceCurrentProfile =>
      'Replace entirely the current profile (WARNING: This will delete all current profile data)';

  @override
  String get createNewProfileForImport => 'Create a new profile for this data';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup imported to new profile \"$profileName\": $projectsCount projects, $rootsCount roots, $releasesCount releases';
  }

  @override
  String get noProfileSelected => 'No profile selected';
}
