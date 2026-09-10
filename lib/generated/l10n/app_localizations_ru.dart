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
  String get enable => 'Включить';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get undo => 'Отменить';

  @override
  String get customInterval => 'Произвольный';

  @override
  String get close => 'Закрыть';

  @override
  String get launch => 'Открыть';

  @override
  String get view => 'Просмотр';

  @override
  String get openFolder => 'Открыть папку';

  @override
  String get openInDaw => 'Запустить в DAW';

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
  String get refreshProject => 'Обновить';

  @override
  String get scanning => 'Сканирование…';

  @override
  String get newProjectBadge => 'НОВОЕ';

  @override
  String get projectName => 'Название проекта';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Тональность (например: C#m, F мажор)';

  @override
  String get notes => 'Заметки';

  @override
  String get expandNotes => 'Развернуть';

  @override
  String get collapseNotes => 'Свернуть';

  @override
  String get projectNotesFromDaw => 'Заметки проекта (из файла DAW)';

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
  String failedToLaunchProject(String projectName) {
    return 'Не удалось открыть $projectName';
  }

  @override
  String get clearLibrary => 'Очистить библиотеку';

  @override
  String get clearLibraryMessage =>
      'Это удалит все сохраненные проекты и исходные папки. Продолжить?';

  @override
  String get clear => 'Очистить';

  @override
  String get roots => 'Папки Проектов';

  @override
  String get pathsSettingsDangerZoneTitle => 'Библиотека';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Очистить все проекты и папки проектов текущего профиля.';

  @override
  String get projectFoldersSectionTitle => 'Папки проектов';

  @override
  String get projectFoldersSectionSubtitle =>
      'Папки, которые будут сканироваться для поиска проектов DAW.';

  @override
  String get projectFoldersEmptyTitle => 'Папки проектов отсутствуют';

  @override
  String get projectFoldersEmptySubtitle =>
      'Добавьте хотя бы одну папку, чтобы начать сканирование проектов.';

  @override
  String get notScannedYet => 'Ещё не сканировано';

  @override
  String lastScan(String date) {
    return 'Последнее сканирование: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Исключённые папки';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Эти папки будут пропускаться при сканировании, даже если они находятся внутри папки проектов.';

  @override
  String get addExcludedFolder => 'Добавить исключение';

  @override
  String get selectExcludedFolder => 'Выберите папку для исключения';

  @override
  String get excludedFoldersEmptyTitle => 'Исключённых папок нет';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Необязательно: добавьте папки, которые вы никогда не хотите сканировать.';

  @override
  String get removeExcludedFolderTitle => 'Удалить исключённую папку?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Эта папка больше не будет исключаться:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Эта папка больше не будет исключаться.';

  @override
  String get desktopOnlyPathsSettings =>
      'Эта страница доступна только в настольном приложении.';

  @override
  String get renameProjectFolderTitle => 'Отображаемое Имя';

  @override
  String get flatpakPortalPathExplanation =>
      'Этот путь — изолированное расположение в песочнице, а не реальный путь к папке — Flatpak не передаёт эту информацию приложению. Используйте имя выше, чтобы идентифицировать её.';

  @override
  String get removeProjectFolderTitle => 'Удалить папку проектов?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Вы уверены, что хотите удалить \"$path\"? Это также удалит все проекты из этой папки, которые не находятся в релизах.';
  }

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
  String get searchReleases => 'Поиск релизов...';

  @override
  String get searchPlaylists => 'Поиск плейлистов...';

  @override
  String get noReleasesFound => 'Релизы не найдены';

  @override
  String get noPlaylistsFound => 'Плейлисты не найдены';

  @override
  String get tryDifferentSearch => 'Попробуйте другой поисковый запрос';

  @override
  String get deepScanConfirm =>
      'Глубокое сканирование извлекает полные метаданные из файлов проекта:\n• BPM (ударов в минуту)\n• Музыкальная тональность\n• Версия DAW\n• Заметки проекта (если поддерживается)\n\nЭто медленнее обычного сканирования и может занять некоторое время. Продолжить?';

  @override
  String get deepScanViewSupportedDaws =>
      'Просмотреть поддерживаемые DAW и поля';

  @override
  String get deepScanOnlyUnscanned =>
      'Сканировать только проекты без метаданных';

  @override
  String get metadataExtractionTitle => 'Извлечение метаданных';

  @override
  String get metadataExtractionSubtitle =>
      'Посмотрите, какие данные поддерживает каждая DAW';

  @override
  String get metadataExtractionIntro =>
      'Глубокое сканирование может автоматически считывать некоторые из этих полей прямо из файла проекта — остальное нужно вводить вручную. В этой таблице показано, что сегодня автоматизировано для каждой поддерживаемой DAW.';

  @override
  String get metadataFieldKey => 'Тональность';

  @override
  String get metadataFieldVersion => 'Версия DAW';

  @override
  String get metadataExtractionManualNote =>
      'Любое поле без автоматической поддержки можно ввести вручную в деталях проекта. Специально для BPM и тональности: файл bpm.txt или key.txt, помещённый рядом с проектом, также будет обнаружен при следующем сканировании.';

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
    return 'Вы уверены, что хотите удалить \"$profileName\"? Это удалит все проекты, папки проектов и релизы этого профиля.';
  }

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get changePhoto => 'Изменить фото';

  @override
  String get remove => 'Удалить';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Вы уверены, что хотите удалить \"$trackName\" из этого релиза?';
  }

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
  String get clearLibraryTooltip =>
      'Очистить библиотеку (проекты и папки проектов)';

  @override
  String lastModified(String date) {
    return 'Последнее изменение: $date';
  }

  @override
  String get name => 'Название';

  @override
  String get status => 'Статус';

  @override
  String get phase => 'Фаза';

  @override
  String get filterByPhase => 'Фильтровать по Фазе';

  @override
  String get filters => 'Фильтры';

  @override
  String get allPhases => 'Все Фазы';

  @override
  String get filterByDaw => 'Фильтр по DAW';

  @override
  String get allDaws => 'Все DAW';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => 'Очистить DAW';

  @override
  String get filterByKey => 'Фильтр по Тональности';

  @override
  String get allKeys => 'Все Тональности';

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
  String get viewModeTable => 'Таблица';

  @override
  String get viewModeCards => 'Карточки';

  @override
  String get selectProject => 'Выбрать проект';

  @override
  String get selectAllProjects => 'Выбрать все проекты';

  @override
  String get switchingProfiles => 'Переключение профилей...';

  @override
  String get scanningProjects => 'Сканирование проектов...';

  @override
  String scanProgressLabel(int current, int total) {
    return 'Загрузка проекта $current из $total…';
  }

  @override
  String get search => 'Поиск';

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
  String get deleteRootPath => 'Удалить папку проектов';

  @override
  String deleteRootPathMessage(String path) {
    return 'Вы уверены, что хотите удалить \"$path\"? Это также удалит все проекты из этой папки, которые не находятся в релизах.';
  }

  @override
  String rootsCount(int count) {
    return 'Папки Проектов: $count';
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
  String get deleteMissingProjects => 'Удалить отсутствующие';

  @override
  String get deleteMissingProjectsTitle => 'Удалить отсутствующие проекты?';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return '$count проект$plural, файл которых не найден на этом компьютере, будут безвозвратно удалены вместе со всеми заметками, сроками и историей сессий. Это действие нельзя отменить.';
  }

  @override
  String get deleteMissingProjectsConfirmButton => 'Удалить навсегда';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return 'Удалено $count отсутствующих проект$plural.';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return 'Также удалить $count проект$plural, входящих в релиз (также удаляет их из этого релиза)';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Вы уверены, что хотите скрыть \"$projectName\"?';
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
  String get folderAlreadyAdded => 'Эта папка уже была добавлена.';

  @override
  String get noProjectsFoundInRoots =>
      'Проекты не найдены в выбранных папках проектов.';

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
  String get scanCancelled => 'Сканирование отменено.';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count проект$plural не удалось загрузить.';
  }

  @override
  String get scanFailuresSnackbarAction => 'Подробнее';

  @override
  String get scanFailuresDialogTitle => 'Ошибки Сканирования';

  @override
  String get scanFailuresDialogIntro =>
      'Эти файлы не удалось прочитать во время сканирования (возможно, они были удалены, перемещены или заблокированы другой программой):';

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
  String releasesSelected(int count, String plural) {
    return 'Выбрано релизов: $count$plural';
  }

  @override
  String get deleteSelectedReleases => 'Удалить выбранное';

  @override
  String deleteSelectedReleasesConfirm(int count, String plural) {
    return 'Удалить выбранные релизы ($count$plural)?';
  }

  @override
  String releasesDeleted(int count, String plural) {
    return 'Удалено релизов: $count$plural';
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
  String get creatingZipFile => 'Создание ZIP-файла...';

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
  String get errorLoadingProjects => 'Ошибка загрузки проектов: null';

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
  String get failedToOpenFile => 'Не удалось открыть файл';

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
  String addTodoAtTimestamp(String timestamp) {
    return 'Добавить задачу на $timestamp';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return 'Задача добавлена на $timestamp';
  }

  @override
  String get todoList => 'Список Задач';

  @override
  String get todoTemplates => 'Шаблоны TODO';

  @override
  String get createTemplate => 'Создать Шаблон';

  @override
  String get editTemplate => 'Редактировать Шаблон';

  @override
  String get deleteTemplate => 'Удалить Шаблон';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Вы уверены, что хотите удалить шаблон \"$name\"?';
  }

  @override
  String get templateName => 'Название Шаблона';

  @override
  String get templateNameHint => 'напр. Чеклист Микширования';

  @override
  String get templateItems => 'Элементы Шаблона';

  @override
  String get templateItemsHint => 'Один элемент на строку';

  @override
  String get templateNameAndItemsRequired => 'Название и элементы обязательны';

  @override
  String get templateItemsRequired => 'Требуется хотя бы один элемент';

  @override
  String get templateCreated => 'Шаблон создан';

  @override
  String get templateUpdated => 'Шаблон обновлен';

  @override
  String get templateDeleted => 'Шаблон удален';

  @override
  String get noTemplatesYet => 'Пока нет шаблонов';

  @override
  String get createFirstTemplate => 'Создайте свой первый шаблон TODO';

  @override
  String templateItemCount(int count) {
    return '$count элемент(ов)';
  }

  @override
  String get selectTemplate => 'Выбрать Шаблон';

  @override
  String get importFromTemplate => 'Импортировать из Шаблона';

  @override
  String get manageTemplates => 'Управление Шаблонами';

  @override
  String get noTemplatesAvailable =>
      'Нет доступных шаблонов. Создайте сначала.';

  @override
  String templateImported(String name, int count) {
    return 'Шаблон \"$name\" импортирован ($count элементов)';
  }

  @override
  String get errorLoadingTemplates => 'Ошибка загрузки шаблонов';

  @override
  String get createProjectStartFrom => 'Как вы хотите начать?';

  @override
  String get createProjectStartFromHint =>
      'Начните с пустой папки или скопируйте зарегистрированный шаблон.';

  @override
  String get createProjectEmptyFolder => 'Пустая Папка';

  @override
  String get createProjectFromTemplate => 'Из Шаблона';

  @override
  String get selectTemplateMainFile => 'Выберите Главный Файл Проекта Шаблона';

  @override
  String get registerTemplate => 'Зарегистрировать Шаблон';

  @override
  String get projectTemplates => 'Шаблоны Проектов';

  @override
  String get searchTemplates => 'Поиск шаблонов...';

  @override
  String get createFirstProjectTemplate =>
      'Зарегистрируйте папку шаблона для повторного использования в новых проектах';

  @override
  String get noMatchingTemplates => 'Нет подходящих шаблонов';

  @override
  String get templateSourceMissing => 'Исходная папка шаблона не найдена';

  @override
  String get useTemplate => 'Использовать';

  @override
  String get selectTemplatesParentFolder =>
      'Выберите Родительскую Папку Шаблонов';

  @override
  String get templateSourceFolder => 'Исходная Папка';

  @override
  String get dateCreatedColumn => 'Создано';

  @override
  String get dateModifiedColumn => 'Изменено';

  @override
  String get manageTemplateFolders => 'Управление Папками';

  @override
  String get addTemplateFolder => 'Добавить Папку';

  @override
  String get removeTemplateFolder => 'Удалить Папку Шаблонов';

  @override
  String removeTemplateFolderConfirm(String path) {
    return 'Удалить \"$path\" из зарегистрированных папок шаблонов? Уже импортированные шаблоны не будут удалены.';
  }

  @override
  String get noTemplateFoldersRegistered =>
      'Нет зарегистрированных папок шаблонов';

  @override
  String get refreshTemplateFolders =>
      'Обновить шаблоны из зарегистрированных папок';

  @override
  String lastRefreshed(String date) {
    return 'Последнее обновление $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return 'Добавлено новых шаблонов: $count';
  }

  @override
  String templatesSelected(int count, String plural) {
    return 'Выбрано шаблонов: $count$plural';
  }

  @override
  String get deleteSelectedTemplates => 'Удалить выбранное';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return 'Удалить выбранные шаблоны ($count$plural)?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return 'Удалено шаблонов: $count$plural';
  }

  @override
  String get templateDetailTitle => 'Template';

  @override
  String get templateNotFound => 'Шаблон не найден';

  @override
  String get saveAsTemplate => 'Сохранить как Шаблон';

  @override
  String get newTemplateNameLabel => 'Название шаблона';

  @override
  String get savedAsTemplate => 'Сохранено как шаблон';

  @override
  String get duplicateTemplate => 'Дублировать';

  @override
  String get templateDuplicated => 'Шаблон продублирован';

  @override
  String get fileInfo => 'Информация о Файле';

  @override
  String get fileSize => 'Размер Файла';

  @override
  String get filePath => 'Путь';

  @override
  String get fileModified => 'Последнее Изменение';

  @override
  String projectsFromThisTemplate(int count) {
    return 'Проекты, Созданные из Этого Шаблона ($count)';
  }

  @override
  String get noProjectsFromThisTemplate =>
      'Пока нет проектов, созданных из этого шаблона';

  @override
  String get importTodos => 'Импортировать Задачи из Файла';

  @override
  String get noTodosInFile => 'Задачи не найдены в файле';

  @override
  String todosImported(int count) {
    return '$count задач(и) импортировано успешно';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Ошибка импорта: $error';
  }

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
  String get changeStatus => 'Изменить Фазу';

  @override
  String get selectNewStatus => 'Выберите новую фазу:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Фаза изменена на \"$status\" для $count проект$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Фаза изменена на \"$status\" для $successCount проект$successPlural, $failCount не удалось$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Ошибка при изменении фазы: $error';
  }

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
  String get dropImageHere => 'Перетащите изображение сюда';

  @override
  String get removeArtwork => 'Удалить обложку';

  @override
  String get removeArtworkConfirm =>
      'Удалить эту обложку? Файл изображения будет удалён.';

  @override
  String get noFilesAddedYet =>
      'Файлы еще не добавлены.\nНажмите \"Добавить Файлы\", чтобы загрузить файлы релиза.';

  @override
  String get noTodosYet => 'Задач пока нет. Добавьте одну выше.';

  @override
  String get done => 'Готово';

  @override
  String get backupAndRestore => 'Резервное копирование и восстановление';

  @override
  String get backupTabLabel => 'Резервная копия';

  @override
  String get aboutTabLabel => 'О программе';

  @override
  String get localBackup => 'Локальная резервная копия';

  @override
  String get appearanceTabLabel => 'Внешний вид';

  @override
  String get exportBackup => 'Экспорт резервной копии';

  @override
  String get importBackup => 'Импорт резервной копии';

  @override
  String get exportProjectInfo => 'Экспорт информации';

  @override
  String get exportProjectInfoTooltip =>
      'Сохранить информацию об этом проекте в текстовый файл';

  @override
  String get exportAllProjectsInfo => 'Экспортировать все проекты в TXT';

  @override
  String get exportAllProjectsInfoSubtitle =>
      'Сохраняет текстовую запись информации обо всех проектах, чтобы она осталась даже после удаления файла DAW';

  @override
  String get projectInfoExported => 'Информация о проекте экспортирована';

  @override
  String allProjectsInfoExported(int count) {
    return 'Экспортирована информация о $count проектах';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return 'Не удалось экспортировать информацию о проекте: $error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return 'Экспортировано: $dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return 'Всего проектов: $count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return 'Проект: $name';
  }

  @override
  String projectExportDawLabel(String dawType) {
    return 'DAW: $dawType';
  }

  @override
  String projectExportDawWithVersionLabel(String dawType, String version) {
    return 'DAW: $dawType $version';
  }

  @override
  String projectExportStatusLabel(String status) {
    return 'Статус: $status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return 'Тональность: $key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return 'Тональность: $key (Camelot $code)';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return 'Путь к файлу: $path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return 'Размер файла: $size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return 'Файл создан: $date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return 'Добавлено в библиотеку: $date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return 'Последнее изменение: $date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return 'Срок: $date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return 'Срок: $date ($status)';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return 'Общее время работы: $duration';
  }

  @override
  String get projectExportNotesLabel => 'Заметки:';

  @override
  String get projectExportTodosLabel => 'Задачи:';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return 'Рабочие сессии ($count):';
  }

  @override
  String get noProjectsToExport => 'Нет проектов для экспорта';

  @override
  String get backupExportedSuccessfully =>
      'Резервная копия успешно экспортирована';

  @override
  String failedToExportBackup(String error) {
    return 'Ошибка при экспорте резервной копии: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Резервная копия успешно импортирована: $projectsCount проектов, $rootsCount папок проектов, $releasesCount релизов';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Ошибка при импорте резервной копии: $error';
  }

  @override
  String get importBackupMessage => 'Выберите способ импорта резервной копии:';

  @override
  String get mergeWithCurrentProfile =>
      'Объединить с текущим активным профилем';

  @override
  String get replaceCurrentProfile =>
      'Полностью заменить текущий профиль (ВНИМАНИЕ: Это удалит все данные текущего профиля)';

  @override
  String get createNewProfileForImport =>
      'Создать новый профиль для этих данных';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Резервная копия импортирована в новый профиль \"$profileName\": $projectsCount проектов, $rootsCount папок проектов, $releasesCount релизов';
  }

  @override
  String get noProfileSelected => 'Профиль не выбран';

  @override
  String get exportBackupDialogTitle => 'Экспорт резервной копии';

  @override
  String get importBackupDialogTitle => 'Импорт резервной копии';

  @override
  String get invalidBackupFileFormat =>
      'Неверный формат файла резервной копии: отсутствует версия';

  @override
  String get profileNameRequiredForNewProfile =>
      'Имя профиля обязательно при создании нового профиля';

  @override
  String get currentProfileRequired =>
      'Текущий профиль обязателен для режима объединения или замены';

  @override
  String get previewSong => 'Превью Трека';

  @override
  String get noPreviewSongTitle => 'Нет песни для предпрослушивания';

  @override
  String get noPreviewSongMessage =>
      'Для этого проекта не задана песня для предпрослушивания. Выберите аудиофайл, чтобы загрузить и воспроизвести его.';

  @override
  String get noPreviewSongDragHint =>
      'Вы также можете перетащить аудиофайл прямо на строку проекта в таблице.';

  @override
  String get previewSongRemoved => 'Превью трека удалено';

  @override
  String get previewSongAdded => 'Превью трека добавлено';

  @override
  String get previewSongFileNotFound => 'Файл превью трека не найден';

  @override
  String get previewSongFileNotFoundMessage =>
      'Файл песни для предварительного прослушивания не найден на диске. Хотите выбрать новый файл или удалить запись?';

  @override
  String get selectNewFile => 'Выбрать новый файл';

  @override
  String failedToPlayPreview(String error) {
    return 'Не удалось воспроизвести превью: $error';
  }

  @override
  String get removePreviewSong => 'Удалить превью трека';

  @override
  String get removePreviewSongConfirm =>
      'Вы уверены, что хотите удалить превью трека? Это действие нельзя отменить.';

  @override
  String get noPreviewSongSelected => 'Превью трека не выбрано';

  @override
  String get changePreviewSong => 'Изменить Превью Трека';

  @override
  String get selectPreviewSong => 'Выбрать Превью Трека';

  @override
  String get dropAudioFileHere => 'Перетащите аудиофайл сюда';

  @override
  String projectAge(String age) {
    return 'Возраст проекта: $age';
  }

  @override
  String createdDate(String date) {
    return 'создан $date';
  }

  @override
  String completedIn(String duration) {
    return 'Завершён за: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'завершён $date';
  }

  @override
  String get dateToday => 'сегодня';

  @override
  String get dateYesterday => 'вчера';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дн. назад',
      one: '1 день назад',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нед. назад',
      one: '1 неделя назад',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мес. назад',
      one: '1 месяц назад',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count г. назад',
      one: '1 год назад',
    );
    return '$_temp0';
  }

  @override
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  ) {
    return '$years г., $months мес.';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years г.';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months мес., $days дн.';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months мес.';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days дн.';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours ч.';
  }

  @override
  String get ageJustNow => 'Только что';

  @override
  String get ageLessThanHour => 'Менее часа';

  @override
  String get viewProfile => 'Просмотр профиля';

  @override
  String get googleDriveSync => 'Синхронизация Google Drive';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Синхронизируйте свои данные с Google Drive для резервного копирования и восстановления между устройствами.';

  @override
  String get manageGoogleDriveSync => 'Управление синхронизацией Google Drive';

  @override
  String get signInToGoogleDrive => 'Войти в Google Drive';

  @override
  String get syncNow => 'Синхронизировать сейчас';

  @override
  String get uploadBackup => 'Загрузить резервную копию';

  @override
  String get downloadBackup => 'Скачать резервную копию';

  @override
  String get newerBackupAvailable => 'Доступна новая резервная копия в облаке';

  @override
  String get restoreProjectFromDrive => 'Восстановить из Drive';

  @override
  String get restoringProjectFromDrive => 'Восстановление из Drive...';

  @override
  String get projectRestoredFromDrive => 'Проект восстановлен из Drive';

  @override
  String get projectNotFoundInBackup =>
      'Этот проект не найден в резервной копии Drive';

  @override
  String get signInToGoogleDriveFirst =>
      'Сначала войдите в Google Drive (откройте настройки Drive Sync)';

  @override
  String get signOut => 'Выйти';

  @override
  String get downloadPreviewSongs => 'Скачать превью-песни';

  @override
  String get downloadPreviewSongsExplanation =>
      'Если не отмечено, превью-песни будут пропущены (экономит время и место). Вы можете скачать их позже при необходимости.';

  @override
  String get replaceLocalData => 'Заменить локальные данные';

  @override
  String get downloadBackupConfirmation =>
      'Это заменит ваши локальные данные резервной копией из Google Drive.\n\nВы уверены, что хотите продолжить?';

  @override
  String get enterAuthorizationCode => 'Ввести код авторизации';

  @override
  String get authorizationCode => 'Код авторизации';

  @override
  String get pasteCodeFromBrowser => 'Вставьте код из браузера';

  @override
  String get sessionActive => 'Сессия активна';

  @override
  String get signedIn => 'Вход выполнен';

  @override
  String get creatingInitialBackup => 'Создание начальной резервной копии...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Успешный вход и резервное копирование в Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Успешный вход и резервное копирование в Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Успешный вход в Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Успешный вход в Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Вход отменен или не удался. Проверьте консоль для деталей.';

  @override
  String get failedToLaunchBrowser => 'Не удалось запустить браузер';

  @override
  String get signInCancelled => 'Вход отменен';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Не удалось обменять код авторизации';

  @override
  String errorSigningIn(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get googleSignInError => 'Ошибка входа Google';

  @override
  String get developerConsoleNotSetUp =>
      'Консоль разработчика настроена неправильно. Пожалуйста, проверьте конфигурацию OAuth в Google Cloud Console.';

  @override
  String get platformError => 'Ошибка платформы';

  @override
  String get signedOutFromGoogleDrive => 'Выход из Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Ошибка выхода: $error';
  }

  @override
  String get syncing => 'Синхронизация...';

  @override
  String get errorNoProfileSelected => 'Ошибка: Профиль не выбран';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Синхронизация завершена! Проекты: +$projectsAdded ~$projectsUpdated, Релизы: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Ошибка синхронизации: $error';
  }

  @override
  String get uploadingBackup => 'Загрузка резервной копии...';

  @override
  String get backupUploadedSuccessfully => 'Резервная копия успешно загружена!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Резервная копия успешно загружена в Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Ошибка загрузки резервной копии: $error';
  }

  @override
  String get downloadingBackup => 'Скачивание резервной копии...';

  @override
  String get checkingForBackup => 'Проверка резервной копии...';

  @override
  String get backupUpToDate => 'Резервная копия актуальна';

  @override
  String errorCheckingBackup(String error) {
    return 'Ошибка проверки резервной копии: $error';
  }

  @override
  String get download => 'Скачать';

  @override
  String get remoteBackupIsNewer =>
      'Удаленная копия новее локальных данных. Загрузка перезапишет её.';

  @override
  String get confirmUpload => 'Подтвердить загрузку';

  @override
  String get noBackupFileFound =>
      'Файл резервной копии не найден в Google Drive. Сначала создайте резервную копию, синхронизировав данные.';

  @override
  String get noBackupFileFoundStatus =>
      'Файл резервной копии не найден. Сначала создайте резервную копию.';

  @override
  String get downloadCancelled => 'Скачивание отменено';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Резервная копия скачана! Проекты: +$projectsAdded ~$projectsUpdated, Релизы: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String backupDownloadedDetailed(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
    int previewSongsDownloaded,
    int previewSongsUpdated,
  ) {
    return 'Резервная копия скачана!\n\nПроекты:\n  • $projectsAdded добавлено\n  • $projectsUpdated обновлено\n\nРелизы:\n  • $releasesAdded добавлено\n  • $releasesUpdated обновлено\n\nПревью песен:\n  • $previewSongsDownloaded скачано\n  • $previewSongsUpdated обновлено';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Ошибка скачивания резервной копии: $error';
  }

  @override
  String get notSignedInYet => 'Не выполнен вход';

  @override
  String get never => 'Никогда';

  @override
  String signedInAs(String email) {
    return 'Вход выполнен как: $email';
  }

  @override
  String lastSync(String date) {
    return 'Последняя синхронизация: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Удаленная копия: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Последняя загрузка: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Последнее скачивание: $date';
  }

  @override
  String get checkForBackup => 'Проверить резервную копию';

  @override
  String get notificationSettings => 'Настройки уведомлений';

  @override
  String get notificationsOnlyOnAndroid =>
      'Уведомления о сроках доступны только на устройствах Android.';

  @override
  String get notificationPermissionRequired =>
      'Требуется разрешение на уведомления';

  @override
  String get notificationPermissionDescription =>
      'Пожалуйста, включите уведомления, чтобы получать напоминания о сроках.';

  @override
  String get notificationPermissionDenied =>
      'Разрешение на уведомления отклонено. Пожалуйста, включите его в настройках.';

  @override
  String get notificationSettingsSaved =>
      'Настройки уведомлений успешно сохранены';

  @override
  String get errorSavingSettings => 'Ошибка сохранения настроек';

  @override
  String get enableDeadlineNotifications => 'Включить уведомления о сроках';

  @override
  String get receiveRemindersForDeadlines =>
      'Получать напоминания о сроках проектов';

  @override
  String get notificationTime => 'Время уведомления';

  @override
  String get timeToReceiveNotifications =>
      'Время суток для получения уведомлений';

  @override
  String get reminderDays => 'Дни напоминания';

  @override
  String get selectDaysBeforeDeadline =>
      'Выберите, за сколько дней до срока вы хотите получать уведомления';

  @override
  String get notifyOnDeadlineDay => 'Уведомить в день срока';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Также получать уведомление в сам день срока';

  @override
  String get howItWorks => 'Как это работает';

  @override
  String get deadlineNotificationsHelp =>
      'Вы будете получать уведомления в указанное время в выбранные дни до каждого срока проекта. Нажмите на уведомление, чтобы открыть детали проекта.';

  @override
  String get oneDay => '1 день';

  @override
  String xDays(int count) {
    return '$count дней';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get searchSettings => 'Поиск по настройкам';

  @override
  String noSettingsFoundFor(String query) {
    return 'Настройки для \"$query\" не найдены';
  }

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get languageSettingDescription =>
      'Язык, используемый во всём приложении.';

  @override
  String get themeSettingDescription => 'Цветовая тема приложения.';

  @override
  String get waveformStyle => 'Стиль волновой формы';

  @override
  String get waveformStyleSettingDescription =>
      'Как отрисовывается волновая форма предпросмотра аудио.';

  @override
  String get waveformStyleDetailed => 'Детальный';

  @override
  String get waveformStyleDetailedDescription =>
      'Столбцы по пикселям с затенённым телом, как в DAW.';

  @override
  String get waveformStyleClassic => 'Классический';

  @override
  String get waveformStyleClassicDescription => 'Один заливной контур.';

  @override
  String get waveformChannels => 'Каналы';

  @override
  String get waveformChannelsSettingDescription =>
      'Разделять ли стерео на две дорожки на волновой форме.';

  @override
  String get waveformChannelsSingle => 'Один';

  @override
  String get waveformChannelsDual => 'Два';

  @override
  String get waveformChannelsSingleDescription =>
      'Одна дорожка со стереомиксом.';

  @override
  String get waveformChannelsDualDescription =>
      'Левый и правый каналы отдельными дорожками.';

  @override
  String get waveformChannelsUnavailable => 'В этом файле только один канал';

  @override
  String get support => 'Поддержать';

  @override
  String get shareDiagnosticLog => 'Поделиться журналом диагностики';

  @override
  String get shareDiagnosticLogEmpty => 'Журнал диагностики пока отсутствует';

  @override
  String get shareDiagnosticLogFolderOpened =>
      'Общий доступ здесь недоступен — вместо этого открыта папка с журналом, чтобы вы могли прикрепить файл вручную.';

  @override
  String get enableDiagnosticLogging => 'Включить журнал диагностики';

  @override
  String get enableDiagnosticLoggingDescription =>
      'Ведёт небольшой журнал сбоев и ошибок на этом устройстве, которым вы можете поделиться, если что-то пойдёт не так. По умолчанию отключено.';

  @override
  String get clearDiagnosticLog => 'Очистить журнал диагностики';

  @override
  String get clearDiagnosticLogConfirmTitle => 'Очистить журнал диагностики?';

  @override
  String get clearDiagnosticLogConfirmMessage =>
      'Файл журнала диагностики будет удалён без возможности восстановления.';

  @override
  String get diagnosticLogCleared => 'Журнал диагностики очищен';

  @override
  String get supportTheProject => 'Поддержать проект';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Не удалось открыть браузер. Пожалуйста, посетите: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Ошибка при открытии браузера: $error';
  }

  @override
  String get generateTestingDatabase => 'Создать тестовую базу данных';

  @override
  String get generateTestingDatabaseMessage =>
      'Это создаст (или обновит) отдельный профиль \"Demo — Screenshots\", заполненный большим количеством разнообразных примеров проектов, релизов и плейлистов для всех поддерживаемых DAW, и переключит вас на него. Остальные ваши профили останутся без изменений. Продолжить?';

  @override
  String get testingDatabaseGenerated =>
      'Демо-профиль готов — вы переключены на него!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Ошибка при создании тестовой базы данных: $error';
  }

  @override
  String get removeTestingDatabase => 'Удалить тестовую базу данных';

  @override
  String get removeTestingDatabaseMessage =>
      'Это навсегда удалит профиль \"Demo — Screenshots\" и все его образцы проектов, релизов, плейлистов и файлов предварительного прослушивания. Продолжить?';

  @override
  String get testingDatabaseRemoved => 'Демо-данные удалены.';

  @override
  String get noTestingDatabaseFound => 'Демо-данные для удаления не найдены.';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return 'Не удалось удалить тестовую базу данных: $error';
  }

  @override
  String get playlists => 'Плейлисты';

  @override
  String get playlistsDesktopOnly => 'Плейлисты доступны только на Android.';

  @override
  String get noPlaylistsYet => 'Плейлистов пока нет';

  @override
  String get createFirstPlaylist => 'Нажмите + чтобы создать первый плейлист';

  @override
  String playlistSongCount(int count) {
    return '$count треков';
  }

  @override
  String get createPlaylist => 'Создать Плейлист';

  @override
  String get playlistName => 'Название Плейлиста';

  @override
  String get playlistNameHint => 'Мой Плейлист';

  @override
  String get playlistNameRequired => 'Название плейлиста обязательно';

  @override
  String get editPlaylist => 'Редактировать Плейлист';

  @override
  String get stopPlaybackBeforeEditing =>
      'Пожалуйста, остановите воспроизведение перед редактированием плейлиста';

  @override
  String get selectPreviewSongs => 'Выбрать Превью';

  @override
  String get deletePlaylist => 'Удалить Плейлист';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Вы уверены, что хотите удалить \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Плейлист удален';

  @override
  String get errorDeletingPlaylist => 'Ошибка удаления плейлиста';

  @override
  String get playlistUpdated => 'Плейлист обновлен';

  @override
  String get changeSong => 'Сменить Песню';

  @override
  String get changeSongConfirm =>
      'Песня сейчас воспроизводится. Хотите переключиться на эту песню?';

  @override
  String get changeSongButton => 'Сменить';

  @override
  String playlistProgress(int current, int total) {
    return '$current из $total';
  }

  @override
  String get noPreviewSongsInPlaylist => 'В этом плейлисте нет превью';

  @override
  String get tapEditToAddSongs =>
      'Нажмите «Изменить», чтобы добавить песни в этот плейлист';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Нет проектов с превью-песнями для добавления';

  @override
  String get noProjectsInDatabase =>
      'Проекты не найдены в базе данных. Пожалуйста, сначала синхронизируйте ваши проекты.';

  @override
  String get firstTimeSyncTitle => 'Похоже, вы здесь впервые!';

  @override
  String get firstTimeSyncMessage =>
      'Давайте синхронизируем ваши данные из Google Drive, чтобы начать';

  @override
  String get syncWithGoogleDrive => 'Синхронизировать с Google Drive';

  @override
  String get errorLoadingPlaylists => 'Ошибка загрузки плейлистов';

  @override
  String get playlistItems => 'Элементы Плейлиста';

  @override
  String get addSongs => 'Добавить Треки';

  @override
  String get addAudioFiles => 'Добавить Аудиофайлы';

  @override
  String get selectAudioFiles => 'Выбрать Аудиофайлы';

  @override
  String get selectFromProjects => 'Выбрать из Проектов';

  @override
  String get add => 'Добавить';

  @override
  String get addTaskAtTimestamp => 'Добавить задачу на текущей позиции';

  @override
  String get taskDescriptionHint => 'Описание задачи';

  @override
  String get taskAdded => 'Задача добавлена';

  @override
  String get fromProject => 'Из Проекта';

  @override
  String get projectDeadline => 'Срок Проекта';

  @override
  String get noDeadlineSet => 'Срок не установлен';

  @override
  String get camelotCode => 'Код Камелот';

  @override
  String get deadline => 'Срок';

  @override
  String get dueToday => 'Истекает сегодня';

  @override
  String daysLate(int days) {
    return '$daysд просрочено';
  }

  @override
  String daysLeft(int days) {
    return '$daysд осталось';
  }

  @override
  String get hideFinished => 'Скрыть Завершенные';

  @override
  String get showOnlyDeadlines => 'Показать дедлайн';

  @override
  String get filterByDeadline => 'Фильтр по Сроку';

  @override
  String get allDeadlines => 'Все Сроки';

  @override
  String get hasDeadline => 'Со Сроком';

  @override
  String get overdue => 'Просрочено';

  @override
  String get dueSoon => 'Скоро Истекает (7д)';

  @override
  String get today => 'Сегодня';

  @override
  String get noPreviewSong => 'Нет превью';

  @override
  String get playPreview => 'Воспроизвести Превью';

  @override
  String get uploadCancelled => 'Загрузка отменена';

  @override
  String get backupUploadCancelledByUser =>
      'Загрузка резервной копии отменена пользователем';

  @override
  String get collectingData => 'Сбор данных...';

  @override
  String get uploadingPreviewSongs => 'Загрузка превью песен...';

  @override
  String get uploadingProfilePhotos => 'Загрузка фото профиля...';

  @override
  String get uploadingReleaseArtwork => 'Загрузка обложек релизов...';

  @override
  String get uploadingDatabase => 'Загрузка базы данных...';

  @override
  String get completed => 'Завершено!';

  @override
  String get cancelling => 'Отмена...';

  @override
  String get uploadingBackupTitle => 'Загрузка Резервной Копии';

  @override
  String get cancellingUpload => 'Отмена загрузки...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Пожалуйста, подождите, пока мы остановим загрузку...';

  @override
  String get downloadingDatabase => 'Скачивание базы данных...';

  @override
  String get downloadingPreviewSongs => 'Скачивание превью песен...';

  @override
  String get downloadingProfilePhotos => 'Скачивание фотографий профиля...';

  @override
  String get downloadingReleaseArtwork => 'Скачивание обложек релизов...';

  @override
  String get mergingData => 'Объединение данных...';

  @override
  String get downloadingBackupTitle => 'Скачивание Резервной Копии';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Исходный файл не найден на этом устройстве';

  @override
  String get metadataExtractionNotSupportedForDaw =>
      'Извлечение метаданных не поддерживается для этой DAW';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Исходный файл не найден на этом устройстве — режим только метаданных. Вы всё равно можете редактировать и экспортировать метаданные.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Превью недоступно. Пожалуйста, сначала загрузите резервную копию.';

  @override
  String get sharePreviewSong => 'Поделиться превью';

  @override
  String get shareAsZip => 'Поделиться как ZIP';

  @override
  String get share => 'Поделиться';

  @override
  String get convertingAudioForSharing => 'Подготовка аудио к отправке…';

  @override
  String get shareSheetUnavailable =>
      'Системное меню отправки здесь недоступно — используйте кнопку «Перетащить, чтобы поделиться» в предпрослушивании трека, чтобы перетащить файл в другое приложение.';

  @override
  String get dragToShare => 'Перетащить, чтобы поделиться';

  @override
  String get dragToShareTooltip =>
      'Перетащите это в окно другого приложения (например, WhatsApp), чтобы поделиться файлом напрямую — полезно, если кнопка \"Поделиться\" не открывает меню отправки.';

  @override
  String get mp3ConversionFailed =>
      'Конвертация аудио недоступна в этой системе — будет отправлен исходный файл, который некоторые приложения, например WhatsApp, могут отклонить.';

  @override
  String get shareZip => 'Поделиться ZIP';

  @override
  String get saveCopy => 'Сохранить копию';

  @override
  String savedCopyTo(String path) {
    return 'Сохранено в $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Не удалось поделиться превью: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Не удалось поделиться превью как ZIP: $error';
  }

  @override
  String get biographySaved => 'Биография сохранена';

  @override
  String failedToSaveBiography(String error) {
    return 'Не удалось сохранить биографию: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Файл сохранён в $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Не удалось скачать файл: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Все файлы сохранены в $filename';
  }

  @override
  String get artworkAdded => 'Обложка добавлена';

  @override
  String failedToAddArtwork(String error) {
    return 'Не удалось добавить обложку: $error';
  }

  @override
  String get artworkRemoved => 'Обложка удалена';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Не удалось удалить обложку: $error';
  }

  @override
  String get pressKitFileAdded => 'Файл пресс-кита добавлен';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Не удалось добавить файл пресс-кита: $error';
  }

  @override
  String get pressKitFileRemoved => 'Файл пресс-кита удалён';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Не удалось удалить файл пресс-кита: $error';
  }

  @override
  String get selectFilesToDownload => 'Выберите файлы для загрузки';

  @override
  String get biography => 'Биография';

  @override
  String get biographyWillBeSaved => 'Будет сохранена как biography.txt';

  @override
  String get artworkFiles => 'Файлы обложек';

  @override
  String get pressKitFiles => 'Файлы пресс-кита';

  @override
  String get additionalAssets => 'Дополнительные ресурсы';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Скачать $count файл$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count файл$plural сохранено в $filename';
  }

  @override
  String get addAsset => 'Добавить ресурс';

  @override
  String get assetNameLabel => 'Название ресурса';

  @override
  String get assetNameHint => 'Например: Логотип, Баннер, Фото';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName успешно добавлен';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Не удалось добавить ресурс: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName удалён';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Не удалось удалить ресурс: $error';
  }

  @override
  String get profileNotFound => 'Профиль не найден';

  @override
  String get downloadFilesSectionTitle => 'Скачать файлы';

  @override
  String get downloadFilesSectionDescription =>
      'Скачайте все файлы этого профиля — биографию, обложку, пресс-кит и дополнительные ресурсы — в виде одного ZIP-архива, либо выберите, что включить.';

  @override
  String get selectFiles => 'Выбрать файлы';

  @override
  String get downloadAll => 'Скачать всё';

  @override
  String get saveBiographyTooltip => 'Сохранить биографию';

  @override
  String get enterBiographyHint => 'Введите биографию профиля...';

  @override
  String get addArtwork => 'Добавить обложку';

  @override
  String get addFile => 'Добавить файл';

  @override
  String get openFile => 'Открыть файл';

  @override
  String get menuView => 'Вид';

  @override
  String get menuAbout => 'О программе DAW Project Manager';

  @override
  String get menuDocumentation => 'Документация';

  @override
  String get menuLanguage => 'Язык';

  @override
  String get menuWarnBeforeQuit => 'Предупреждать перед выходом (⌘+Q)';

  @override
  String get menuQuit => 'Выйти из DAW Project Manager';

  @override
  String get quitConfirmTitle => 'Выйти из DAW Project Manager?';

  @override
  String get quitConfirmMessage => 'Вы уверены, что хотите выйти?';

  @override
  String get quit => 'Выйти';

  @override
  String get trayNoticeTitle => 'Продолжает работать в фоне';

  @override
  String get trayNoticeBody =>
      'DAW Project Manager свёрнут в системный трей. Используйте значок в трее, чтобы открыть приложение снова или выйти.';

  @override
  String get trayShowWindow => 'Показать DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return 'Последнее резервное копирование: $when';
  }

  @override
  String get trayNeverBackedUp => 'Резервное копирование ещё не выполнялось';

  @override
  String get trayBackupNow => 'Создать резервную копию';

  @override
  String get trayPauseSession => 'Приостановить сеанс';

  @override
  String get trayResumeSession => 'Возобновить сеанс';

  @override
  String get closeToTray => 'Закрывать в трей';

  @override
  String get closeToTrayDescription =>
      'Продолжать работать в фоне (значок в трее) при закрытии окна, чтобы автоматическое резервное копирование и уведомления продолжали работать';

  @override
  String get autoStart => 'Запускать при входе в систему';

  @override
  String get autoStartDescription =>
      'Автоматически открывать DAW Project Manager при входе в систему';

  @override
  String get startMinimized => 'Запускать свёрнутым в трей';

  @override
  String get startMinimizedDescription =>
      'При запуске вместе с компьютером открывать приложение скрытым в трее, а не показывать окно';

  @override
  String get onboardingStartMinimized => 'Запускать свёрнутым';

  @override
  String get autoStartFailed =>
      'Не удалось изменить параметр автозапуска. Возможно, ваша система этого не разрешает.';

  @override
  String get onboardingStartupTitle => 'Запуск при входе в систему';

  @override
  String get onboardingStartupBody =>
      'Открывайте DAW Project Manager автоматически при входе в систему, чтобы фоновые резервные копии и напоминания о сроках продолжали работать.';

  @override
  String get menuWindow => 'Окно';

  @override
  String get donate => 'Пожертвовать';

  @override
  String get website => 'Сайт';

  @override
  String get license => 'Лицензия';

  @override
  String get reportIssue => 'Сообщить о проблеме';

  @override
  String get switchToClassicDark => 'Переключить на Classic Dark';

  @override
  String get switchToNeonDark => 'Переключить на Neon Dark';

  @override
  String get switchToClassicTheme => 'Переключить на Classic тему';

  @override
  String get switchToNeonTheme => 'Переключить на Neon тему';

  @override
  String get switchToStudioLight => 'Переключить на Studio Light';

  @override
  String get menuTheme => 'Тема';

  @override
  String get appDescription =>
      'Менеджер проектов для музыкальных продюсеров и звуковых дизайнеров.';

  @override
  String get neonDarkThemeName => 'Неоновая тёмная';

  @override
  String get classicDarkThemeName => 'Классическая тёмная';

  @override
  String get studioLightThemeName => 'Студийная светлая';

  @override
  String get statisticsTab => 'Статистика';

  @override
  String get statsTotalProjects => 'Всего проектов';

  @override
  String get statsInProgress => 'В работе';

  @override
  String get statsFinished => 'Завершено';

  @override
  String get statsAvgCompletion => 'Ср. завершение';

  @override
  String get statsPhaseDistribution => 'Проекты по фазам';

  @override
  String get statsAvgTimePerPhase => 'Ср. дней на фазу';

  @override
  String get statsProductivity => 'Продуктивность';

  @override
  String get statsCreatedSeries => 'Создано';

  @override
  String get statsProjectHealth => 'Возраст и состояние проектов';

  @override
  String get statsCatalogInsights => 'Анализ каталога';

  @override
  String get statsBpmDistribution => 'Распределение BPM';

  @override
  String get statsTopKeys => 'Популярные тональности';

  @override
  String get statsDawTypes => 'Типы DAW';

  @override
  String get statsProjectActivity => 'Активность проектов';

  @override
  String get statsSingleProjectActivity => 'Активность проекта';

  @override
  String get statsNoData => 'Нет данных';

  @override
  String get statsNoPhaseData => 'Данные появятся после смены фаз.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Последняя активность: $days дн. назад';
  }

  @override
  String get statsLastActivityToday => 'Активен сегодня';

  @override
  String get statsNoEvents => 'Событий пока нет';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Фаза: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Обновлено: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Выполнено: $text';
  }

  @override
  String get statsEventFileModified => 'Файл изменён на диске';

  @override
  String get statsClearHistory => 'Очистить историю';

  @override
  String get statsClearHistoryConfirm =>
      'Удалить все записанные события для этого проекта?';

  @override
  String get statsSearchProjects => 'Поиск проектов…';

  @override
  String statsEventCount(int count) {
    return '$count событий';
  }

  @override
  String get statsViewHistory => 'Статистика проекта';

  @override
  String get statsPhaseHistory => 'История фаз';

  @override
  String get statsEventBreakdown => 'Сводка событий';

  @override
  String statsDaysSoFar(int days) {
    return 'Уже $daysд';
  }

  @override
  String get statsNoProjectsFound => 'Проекты не найдены';

  @override
  String statsNotTouchedDays(int days) {
    return 'Не изменялся $days дн.';
  }

  @override
  String get sortByDeadline => 'Срок';

  @override
  String get sortByLabel => 'Сортировать по';

  @override
  String get cardInitialsTitle => 'Инициалы карточки';

  @override
  String get cardInitialsDescription =>
      'Буквы на карточке этого проекта, когда у него нет обложки.';

  @override
  String get cardInitialsEmptyHint =>
      'Оставьте пустым, чтобы использовать инициалы названия.';

  @override
  String get sortByLastModified => 'Дата изменения';

  @override
  String get sortByName => 'Имя';

  @override
  String get sortByPhase => 'Фаза';

  @override
  String get sortByCreatedAt => 'Дата добавления';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => 'Сначала новые';

  @override
  String get sortOldestFirst => 'Сначала старые';

  @override
  String get sortTitleAZ => 'Название А–Я';

  @override
  String get sortTitleZA => 'Название Я–А';

  @override
  String get musicPlayerTab => 'Музыкальный плеер';

  @override
  String get previewAudioChangedRefreshing =>
      'Аудио предпросмотра изменилось на диске — обновление формы волны…';

  @override
  String get audioFileChangedRefreshing =>
      'Аудиофайл изменился на диске — обновление формы волны…';

  @override
  String get autoFitAllColumns => 'Автоподбор столбцов';

  @override
  String get uploadAutoDetectedPreviewSongs =>
      'Загружать автоматически найденные превью-треки';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      'Включать треки, автоматически найденные сканером, а не только заданные вручную.';

  @override
  String get monoGenerating => 'Моно…';

  @override
  String errorHandlingDroppedFiles(String error) {
    return 'Ошибка обработки перетащенных файлов: $error';
  }

  @override
  String get resetOnboardingConfirm =>
      'Это перезапустит мастер настройки. Продолжить?';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return 'Не удалось запустить $daw: $error';
  }

  @override
  String get couldNotOpenLink => 'Не удалось открыть ссылку.';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => 'Моно';

  @override
  String get monoToggleTooltip => 'Переключить моно воспроизведение';

  @override
  String get monoRequiresWav => 'Для монофонического микса требуется WAV-файл';

  @override
  String get monoUnsupportedFormat =>
      'Не удалось создать монофонический микс — неподдерживаемый формат';

  @override
  String monoSwitchFailed(String error) {
    return 'Ошибка переключения моно: $error';
  }

  @override
  String get analyzeLabel => 'Анализировать';

  @override
  String get reAnalyzeLabel => 'Повторный анализ';

  @override
  String get analysisRequiresWav => 'Для анализа требуется WAV-файл';

  @override
  String get noResultsForFilter => 'Нет результатов для текущего фильтра';

  @override
  String get noResultsForFilterHint => 'Попробуйте изменить поиск или фильтры.';

  @override
  String get noProjectsFound => 'Проекты не найдены';

  @override
  String get noProjectsFoundHint =>
      'Добавьте корневую папку в настройках, чтобы начать.';

  @override
  String get noProjectsFoundInFoldersHint =>
      'Попробуйте добавить другую папку с проектами DAW.';

  @override
  String get queueTab => 'Задачи';

  @override
  String get queueSearchHint => 'Поиск задач...';

  @override
  String get queueNoPendingTasks => 'Всё готово!';

  @override
  String get queueNoPendingTasksHint =>
      'Нет незавершённых задач в ваших проектах.';

  @override
  String get queueNoMatchingTasks => 'Задачи не найдены';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks незавершённых задач в $projects проектах';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager $version';
  }

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get renameProjectFileTitle => 'Переименовать файл проекта';

  @override
  String get renameFileButtonLabel => 'Переименовать файл';

  @override
  String get newFileNameLabel => 'Новое имя файла (без расширения)';

  @override
  String renameAlreadyExists(String name) {
    return 'Файл с именем \"$name\" уже существует.';
  }

  @override
  String renameSuccess(String name) {
    return 'Переименовано в \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Не удалось переименовать: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Имя не может быть пустым';

  @override
  String get nameInvalidCharacters => 'Имя не может содержать / \\ :';

  @override
  String get alsoRenameContainingFolder =>
      'Также переименовать содержащую папку';

  @override
  String get renameButton => 'Переименовать';

  @override
  String get previewMixdownFolderTitle => 'Папки миксов для предпросмотра';

  @override
  String get previewMixdownFolderSubtitle =>
      'Имена подпапок в каждой папке проекта, проверяемые первыми по порядку при автоматическом обнаружении песен для предпросмотра. Оставьте пустым для использования настроек DAW по умолчанию.';

  @override
  String get previewMixdownFolderHint => 'например, Миксы';

  @override
  String get mixdownFoldersInfoTooltip => 'Как это работает';

  @override
  String get mixdownFoldersInfoDialogTitle =>
      'Как работает обнаружение предпросмотра';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'Если для проекта не выбрана песня для предпросмотра вручную, приложение ищет самый недавно измененный аудиофайл для использования в качестве предпросмотра. Сначала проверяются ваши пользовательские папки ниже, по порядку, а затем используется список папок по умолчанию на основе DAW проекта.';

  @override
  String get mixdownFoldersDawDefaultsHeading =>
      'Папки по умолчанию для каждой DAW';

  @override
  String get mixdownFoldersOtherDawLabel => 'Другое / нераспознанная DAW';

  @override
  String get addMixdownFolder => 'Добавить';

  @override
  String get noCustomMixdownFolders =>
      'Пользовательские папки не добавлены — будут использованы значения по умолчанию DAW.';

  @override
  String get mixdownFoldersTabLabel => 'Папки для микса';

  @override
  String get mixdownFoldersSectionDescription =>
      'Определяет, в какой папке приложение ищет экспортированное/сведённое аудио проекта, используемое как превью-песня, если она не задана вручную. Разверните DAW ниже, чтобы увидеть имена папок, проверяемые по умолчанию, и добавьте свои, если в вашей настройке используется другое имя.';

  @override
  String get mixdownFoldersDefaultsLabel => 'Проверяемые по умолчанию папки:';

  @override
  String get mixdownFoldersCustomLabel => 'Ваши добавления для этой DAW:';

  @override
  String get dawLaunchCommandsTabLabel => 'DAW Locations';

  @override
  String get dawLaunchCommandsSectionDescription =>
      '\"Launch in DAW\" normally hands the project to the system\'s default application. When that doesn\'t work, point it here at the exact DAW program to run — an executable on Windows and Linux (or an AppImage), or the .app on macOS — and the app will open projects of that type with it directly. On Linux this is usually required; on Windows and macOS it\'s a fallback for when the standard launch fails. You can add more than one location per DAW (e.g. two versions); the app asks which to use when you launch.';

  @override
  String get dawLaunchCommandNotConfigured => 'Not configured';

  @override
  String get dawLaunchCommandMissingTooltip => 'This location no longer exists';

  @override
  String get dawLaunchCommandConfigureButton => 'Configure';

  @override
  String get dawLaunchCommandAddButton => 'Add location';

  @override
  String dawLaunchCommandDialogTitle(String dawType) {
    return 'Launch command for $dawType';
  }

  @override
  String dawLaunchCommandDialogBody(String dawType) {
    return 'Point this at the $dawType program — an executable on Windows and Linux (or an AppImage), or the .app on macOS. The app will run it directly with the project file as its only argument.';
  }

  @override
  String dawLaunchCommandDialogLaunchFailedBanner(String dawType) {
    return 'DAW Project Manager couldn\'t open this project through the system. Point it at the $dawType program below and it will try launching the project with it directly.';
  }

  @override
  String dawLaunchCommandDialogMissingBanner(String dawType, String path) {
    return 'The saved location(s) for $dawType no longer exist:\n$path';
  }

  @override
  String dawLaunchPickerTitle(String dawType) {
    return 'Which $dawType?';
  }

  @override
  String dawLaunchPickerBody(String dawType, String project) {
    return 'Choose which $dawType location to open “$project” with.';
  }

  @override
  String get dawLaunchCommandDialogDetectedHeading => 'Detected on this system';

  @override
  String get dawLaunchCommandDialogManualHint => '/path/to/executable';

  @override
  String get dawLaunchCommandDialogBrowseButton => 'Browse…';

  @override
  String get dawLaunchCommandDialogSaveButton => 'Save';

  @override
  String get dawLaunchCommandDialogSaveAndLaunchButton => 'Save & Launch';

  @override
  String get dawLaunchCommandDialogInvalidPath => 'This file doesn\'t exist';

  @override
  String get dawLaunchCommandsEmptyState =>
      'DAWs will appear here once you scan projects for them.';

  @override
  String dawInfoLabel(String daw) {
    return 'DAW: $daw';
  }

  @override
  String bpmInfoLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String keyInfoLabel(String key) {
    return 'Тональность: $key';
  }

  @override
  String get audioFileNotFound => 'Аудиофайл не найден';

  @override
  String errorPlayingAudio(String error) {
    return 'Ошибка воспроизведения аудио: $error';
  }

  @override
  String get notificationTestTitle =>
      'Тестирование уведомлений для проверки часового пояса и планирования:';

  @override
  String get notificationSendNow => 'Отправить сейчас';

  @override
  String get notificationSchedule30s => 'Запланировать +30с';

  @override
  String get notificationShowDebugInfo => 'Показать отладочную информацию';

  @override
  String get notificationRescheduleAll => 'Перепланировать все';

  @override
  String get notificationTestSent => '✅ Тестовое уведомление отправлено!';

  @override
  String get notificationTestScheduled =>
      '✅ Тестовое уведомление запланировано на 30 секунд! Проверьте журналы консоли.';

  @override
  String notificationTestError(String error) {
    return '❌ Ошибка: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Отладочная информация';

  @override
  String get autoDetected => 'Определено автоматически';

  @override
  String get matchedInDescription => 'Совпадение в описании';

  @override
  String get matchedInProjectNotes => 'Совпадение в заметках проекта DAW';

  @override
  String get relocateFolderDialogTitle => 'Переместить папку';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Обновлено $count путей проектов',
      one: 'Обновлён 1 путь проекта',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Настроить вкладки';

  @override
  String get alwaysVisible => '(всегда видно)';

  @override
  String get customizeTabsDescription =>
      'Выберите, какие вкладки отображать на панели навигации. Вкладка «Проекты» всегда видима.';

  @override
  String get keyboardShortcuts => 'Сочетания клавиш';

  @override
  String get shortcutGroupGlobal => 'Глобальные';

  @override
  String get shortcutGroupProjectsTable =>
      'Таблица проектов (таблица должна быть в фокусе)';

  @override
  String get shortcutGroupReleasesTable =>
      'Таблица релизов (таблица должна быть в фокусе)';

  @override
  String get shortcutGroupNavigation => 'Навигация';

  @override
  String get shortcutFocusSearch => 'Перейти к строке поиска';

  @override
  String get shortcutRescan => 'Повторно сканировать папки';

  @override
  String get shortcutFocusTable => 'Перейти к таблице проектов';

  @override
  String get shortcutPlayPause => 'Воспроизвести / пауза превью';

  @override
  String get shortcutOpenInDaw => 'Открыть проект в DAW';

  @override
  String get shortcutViewDetails => 'Просмотр деталей проекта';

  @override
  String get shortcutOpenFolder => 'Открыть папку проекта';

  @override
  String get shortcutNavigateRows => 'Навигация по строкам';

  @override
  String get shortcutEditCell => 'Открыть детали проекта';

  @override
  String get shortcutViewRelease => 'Просмотр деталей релиза';

  @override
  String get shortcutGoBack => 'Назад';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Стандартный режим';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Режим сессии';

  @override
  String get shortcutToggleSession => 'Начать / Завершить сессию';

  @override
  String get shortcutGroupPreviewPlayer => 'Плеер предпросмотра';

  @override
  String get shortcutPlayerPlayPause => 'Воспроизведение / пауза';

  @override
  String get shortcutPlayerSeek5 => 'Перемотка ±5 секунд';

  @override
  String get shortcutPlayerSeek30 => 'Перемотка ±30 секунд';

  @override
  String get startupDialogTitle => 'Добро пожаловать в DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Добавьте папку с проектами или восстановите резервную копию с Google Диска.';

  @override
  String get startupAddFolderTitle => 'Добавить папку проектов';

  @override
  String get startupAddFolderSubtitle =>
      'Выберите папку с вашими DAW-проектами.';

  @override
  String get startupGoogleDriveTitle =>
      'Синхронизировать резервную копию Google Диска';

  @override
  String get startupGoogleDriveSubtitle =>
      'Восстановите проекты из резервной копии на Google Диске.';

  @override
  String get startupDontShowAgain => 'Не показывать при запуске';

  @override
  String get pinnedLibraryWarningTitle => 'Используется тестовая библиотека';

  @override
  String get pinnedLibraryWarningBody =>
      'Эта сборка хранит данные в отдельной тестовой библиотеке и не изменяет библиотеку установленного приложения. Проекты, профили и настройки, изменённые здесь, там не появятся.';

  @override
  String get pinnedLibraryWarningLibraryLabel => 'Библиотека';

  @override
  String get pinnedLibraryWarningLocationLabel => 'Расположение';

  @override
  String get pinnedLibraryWarningDontShowAgain =>
      'Больше не предупреждать об этой библиотеке';

  @override
  String get deleteAllData => 'Удалить все данные';

  @override
  String get deleteAllDataSubtitle =>
      'Удалить все профили, проекты, релизы, плейлисты и настройки с этого устройства.';

  @override
  String get deleteAllDataConfirm1Title => 'Удалить все данные?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Это навсегда удалит все профили, проекты, релизы, плейлисты и настройки с этого устройства. Резервная копия на Google Диске (если есть) не пострадает.';

  @override
  String get deleteAllDataConfirm2Title => 'Вы абсолютно уверены?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Это действие необратимо. Приложение вернётся в исходное состояние.';

  @override
  String get deleteEverything => 'Удалить всё';

  @override
  String get allDataDeleted => 'Все данные были удалены.';

  @override
  String get newerExportFound => 'Найден более новый экспорт';

  @override
  String newerExportFoundMessage(String filename) {
    return 'В той же папке найден более новый файл:\n$filename\n\nЗаменить песню для предпросмотра?';
  }

  @override
  String get replaceAndPlay => 'Заменить и воспроизвести';

  @override
  String get keepCurrent => 'Оставить текущую';

  @override
  String get autoBackup => 'Автоматическая резервная копия';

  @override
  String get autoBackupDescription =>
      'Автоматически загружает резервную копию на Google Drive с выбранным интервалом.';

  @override
  String get autoBackupInterval => 'Интервал резервного копирования';

  @override
  String get autoBackupOff => 'Выкл.';

  @override
  String get autoBackupEvery30Min => 'Каждые 30 минут';

  @override
  String get autoBackupHourly => 'Каждый час';

  @override
  String get autoBackupEvery6Hours => 'Каждые 6 часов';

  @override
  String get autoBackupDaily => 'Ежедневно';

  @override
  String autoBackupNextBackup(String time) {
    return 'Следующий бэкап: $time';
  }

  @override
  String get autoBackupNextSoon => 'скоро';

  @override
  String autoBackupNextInMinutes(int count) {
    return 'через $count мин';
  }

  @override
  String get autoBackupNextInOneHour => 'через 1 час';

  @override
  String autoBackupNextInHours(int count) {
    return 'через $count ч';
  }

  @override
  String get autoBackupNextInOneDay => 'через 1 день';

  @override
  String autoBackupNextInDays(int count) {
    return 'через $count дн.';
  }

  @override
  String get playerTitle => 'Музыкальный плеер';

  @override
  String get playerToggleQueue => 'Переключить очередь';

  @override
  String get playerSearchHint => 'Поиск треков…';

  @override
  String playerTrackCount(int count) {
    return '$count треков';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'Треки для предпросмотра не найдены.\nОткройте проект и добавьте трек.';

  @override
  String playerNoTracksMatch(String query) {
    return 'Треки не найдены:\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay =>
      'Дважды щёлкните по треку для воспроизведения';

  @override
  String get playerSingleClickToPreview =>
      'Одиночный клик — предпросмотр в панели ниже';

  @override
  String get playerQueueTitle => 'Очередь';

  @override
  String get playerClearQueue => 'Очистить очередь';

  @override
  String get playerQueueEmptyHint =>
      'Дважды щёлкните для начала,\nили перетащите треки сюда.';

  @override
  String get playerPrev => 'Предыдущий';

  @override
  String get playerNext => 'Следующий';

  @override
  String get playerGoToProject => 'Перейти к проекту';

  @override
  String get playerAddToQueue => 'Добавить в очередь';

  @override
  String get playerRemoveFromQueue => 'Убрать из очереди';

  @override
  String get playerDismissDetail => 'Закрыть детали';

  @override
  String get playerNotes => 'ЗАМЕТКИ';

  @override
  String get playerTasks => 'ЗАДАЧИ';

  @override
  String get playerNoTasks => 'Задач пока нет.';

  @override
  String get playerAddTaskHint => 'Добавить задачу…';

  @override
  String playerCompletedTasks(int count) {
    return '$count выполнено';
  }

  @override
  String get playerPreviousTrack => 'Предыдущий трек';

  @override
  String get playerNextTrack => 'Следующий трек';

  @override
  String get playerOpenProject => 'Открыть проект';

  @override
  String get playerRepeatAll => 'Повторить всё';

  @override
  String get playerShuffle => 'Перемешать';

  @override
  String get volumeMute => 'Отключить звук';

  @override
  String get volumeUnmute => 'Включить звук';

  @override
  String totalWorkTime(String time) {
    return 'Всего работы: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Сессия: $time';
  }

  @override
  String headerAgeOld(String age) {
    return 'возраст: $age';
  }

  @override
  String headerEdited(String when) {
    return 'изменено $when';
  }

  @override
  String headerWorked(String time) {
    return 'отработано $time';
  }

  @override
  String get sessionHistory => 'История сессий';

  @override
  String get noSessionsYet => 'Сессии ещё не записаны';

  @override
  String get removeSessionTitle => 'Удалить сессию?';

  @override
  String get editSessionTitle => 'Изменить длительность сессии';

  @override
  String get editSessionHours => 'Часы';

  @override
  String get editSessionInvalid => 'Длительность должна быть не менее 1 минуты';

  @override
  String get sessionTableDate => 'Дата';

  @override
  String get sessionTableTime => 'Время';

  @override
  String get sessionTableDuration => 'Длительность';

  @override
  String get sessionTableTotal => 'Итого';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сессий',
      few: '$count сессии',
      one: '$count сессия',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'Работа по фазам';

  @override
  String get tabPosition => 'Расположение вкладок';

  @override
  String get tabPositionTop => 'Сверху';

  @override
  String get tabPositionLeft => 'Слева';

  @override
  String updateAvailableMessage(String version) {
    return 'Доступна версия $version';
  }

  @override
  String get dismiss => 'Закрыть';

  @override
  String get checkForUpdates => 'Проверять обновления';

  @override
  String get checkForUpdatesDescription =>
      'Получать уведомления о выходе новых версий.';

  @override
  String get checkNow => 'Проверить сейчас';

  @override
  String updateAvailable(String version) {
    return 'Доступно обновление: v$version';
  }

  @override
  String get upToDate => 'Приложение актуально';

  @override
  String get updateAvailableTitle => 'Доступно обновление';

  @override
  String updateAvailableVersion(String version) {
    return 'Версия $version готова.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Вы используете v$version.';
  }

  @override
  String get viewUpdateDetails => 'Подробнее';

  @override
  String get getOnMicrosoftStore => 'Получить в Microsoft Store';

  @override
  String get downloadFromGitHub => 'Скачать с GitHub';

  @override
  String get updateWindowsInstructions =>
      'Откройте Microsoft Store и обновите DAW Project Manager, или нажмите кнопку ниже.';

  @override
  String get updateMacInstructions =>
      'Скачайте последнюю версию с GitHub и замените текущее приложение.';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions =>
      'Обновление происходит на месте с последующим перезапуском.';

  @override
  String get updateNowButtonLabel => 'Обновить сейчас';

  @override
  String get appImageUpdateFetching => 'Поиск обновления…';

  @override
  String get appImageUpdateDownloading => 'Загрузка обновления…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return 'Загрузка обновления… $percent%';
  }

  @override
  String get appImageUpdateVerifying => 'Проверка и установка…';

  @override
  String get appImageUpdateReadyTitle => 'Обновление готово';

  @override
  String appImageUpdateReadyMessage(String version) {
    return 'Обновлено до версии $version. Перезапустите сейчас, чтобы завершить.';
  }

  @override
  String get appImageUpdateRestartNow => 'Перезапустить сейчас';

  @override
  String get appImageUpdateFailedTitle => 'Не удалось обновить';

  @override
  String get appImageUpdateRetry => 'Повторить';

  @override
  String get appImageUpdateErrorMessage =>
      'Во время обновления произошла ошибка. Вы можете повторить попытку или просмотреть подробности ошибки ниже.';

  @override
  String get appImageUpdateErrorDetailsLabel => 'Подробности ошибки';

  @override
  String get appImageUpdateCopyErrorDetails => 'Скопировать подробности ошибки';

  @override
  String get appImageUpdateErrorDetailsCopied =>
      'Подробности ошибки скопированы';

  @override
  String get resetOnboarding => 'Сбросить обучение';

  @override
  String get onboardingWelcomeTitle => 'Добро пожаловать в DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Управляйте всеми музыкальными проектами в одном месте.';

  @override
  String get onboardingFeatureScanFolders =>
      'Автоматически сканирует папки проектов DAW';

  @override
  String get onboardingFeatureTrackMetadata =>
      'Отслеживает BPM, тональность, статус и сроки';

  @override
  String get onboardingFeatureSyncDrive =>
      'Синхронизирует метаданные с Google Drive';

  @override
  String get onboardingFeatureTrackTime =>
      'Отслеживает время, потраченное на каждый проект';

  @override
  String get onboardingLanguageTitle => 'Выберите язык';

  @override
  String get onboardingThemeTitle => 'Выберите тему';

  @override
  String get onboardingFoldersTitle => 'Добавить папки проектов';

  @override
  String get onboardingFoldersBody =>
      'Добавьте корневую папку, в которой хранятся ваши DAW-проекты.';

  @override
  String get onboardingDriveTitle => 'Синхронизация с Google Drive';

  @override
  String get onboardingDriveBody =>
      'Резервное копирование и синхронизация метаданных проектов с Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Проверка обновлений';

  @override
  String get onboardingUpdatesBody =>
      'Получать уведомления о выходе новых версий.';

  @override
  String get onboardingDoneTitle => 'Всё готово!';

  @override
  String get onboardingDoneBody => 'Начните изучать свои проекты.';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingBack => 'Назад';

  @override
  String get onboardingGetStarted => 'Начать';

  @override
  String get dawSession => 'Сессия DAW';

  @override
  String get clearDawSession => 'Очистить сессию';

  @override
  String get stop => 'Стоп';

  @override
  String get pause => 'Пауза';

  @override
  String get playPauseTooltip => 'Воспроизвести / Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get workTimerSection => 'Напоминания о рабочей сессии';

  @override
  String get workTimerSectionDesc =>
      'Получайте периодические уведомления, пока рабочая сессия активна';

  @override
  String get workTimerRequiresSessionMode =>
      'Включите режим сессии выше, чтобы использовать напоминания о рабочей сессии';

  @override
  String get workTimerEnabled => 'Включить напоминания о рабочей сессии';

  @override
  String get workTimerIntervalLabel => 'Уведомлять каждые';

  @override
  String get minutes => 'минут';

  @override
  String workTimerNotifBody(String time) {
    return 'Вы работаете уже $time';
  }

  @override
  String get sendTestNotification => 'Отправить тестовое уведомление';

  @override
  String get testNotificationTitle => 'Тестовое уведомление';

  @override
  String get testNotificationBody =>
      'Это тестовое уведомление от DAW Project Manager.';

  @override
  String get general => 'Общие';

  @override
  String get expand => 'Развернуть';

  @override
  String get collapse => 'Свернуть';

  @override
  String get lastModifiedColors => 'Цвета даты последнего изменения';

  @override
  String get lastModifiedColorsDescription =>
      'Окрашивает дату последнего изменения в зависимости от возраста и статуса. Зелёный = Завершено. Более старые даты плавно переходят от жёлтого к красному — более насыщенный красный означает, что проект не трогали дольше.';

  @override
  String get sessionMode => 'Режим сессии';

  @override
  String get sessionModeDescription =>
      'Начните сессию для проекта, чтобы отслеживать рабочее время и управлять им с панели инструментов';

  @override
  String get workSessionsTabLabel => 'Рабочие сессии';

  @override
  String get normalMode => 'Обычный режим';

  @override
  String get normalModeDescription =>
      'Проекты открываются напрямую в своей DAW при запуске.';

  @override
  String get sessionModeCardDescription =>
      'Начните сессию, чтобы отслеживать вашу активность и время работы над проектом.';

  @override
  String get startSession => 'Начать сессию';

  @override
  String get endSession => 'Завершить сессию';

  @override
  String get switchSession => 'Сменить сессию';

  @override
  String get switchSessionBody => 'Завершить текущую сессию и начать новую?';

  @override
  String switchSessionCurrent(String project) {
    return 'Текущий: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'Новый: $project';
  }

  @override
  String get sessionDuration => 'Время сессии';

  @override
  String get scanModeLabel => 'Режим сканирования:';

  @override
  String get scanModeSectionTitle => 'Режим сканирования';

  @override
  String get scanModeSectionDescription =>
      'Управляет отображением проектов в каждой папке в таблице — в виде обычного плоского списка или сгруппированных по подпапке.';

  @override
  String get smartFolderOptionsSectionTitle => 'Параметры умных папок';

  @override
  String get smartFolderOptionsSectionDescription =>
      'Настройте поведение групп умных папок в таблице проектов.';

  @override
  String get excludeSmartFoldersFromSort =>
      'Не учитывать умные папки при сортировке';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      'При сортировке таблицы проектов по столбцу группы умных папок остаются на месте, а не перемещаются вместе с сортировкой — переупорядочиваются только проекты внутри них (и любые несгруппированные проекты). Экспериментальная функция: по умолчанию отключена.';

  @override
  String get mergeSmartFoldersByName =>
      'Объединять умные папки с одинаковым названием';

  @override
  String get mergeSmartFoldersByNameDescription =>
      'Если у двух корневых папок сканирования (например, разных DAW) есть папка верхнего уровня с одинаковым названием, они рассматриваются как одна объединённая группа в таблице проектов, а не как две отдельные.';

  @override
  String get alwaysShowSmartFolders => 'Всегда показывать умные папки';

  @override
  String get alwaysShowSmartFoldersDescription =>
      'Показывать умную папку как отдельную строку группы, даже если сейчас виден только один из её проектов (например, после поиска или фильтра), вместо того чтобы сворачивать её в обычную несгруппированную строку.';

  @override
  String get scanModeFlat => 'Простой';

  @override
  String get scanModeSmartFolder => 'Умная папка';

  @override
  String get scanModeFlatDescription =>
      'Отображает все проекты в виде простого списка. Просто и быстро.';

  @override
  String get scanModeSmartFolderDescription =>
      'Группирует проекты по папке, если папка содержит более одного проекта.';

  @override
  String get skip => 'Пропустить';

  @override
  String get suggestionsLabel => 'Предложения';

  @override
  String get suggestionsRefresh => 'Обновить';

  @override
  String get suggestionsEmptyState =>
      'Нет предложений. Нажмите «Обновить», чтобы сбросить скрытые элементы.';

  @override
  String get suggestionNewProject => 'Новый';

  @override
  String get showSuggestions => 'Показывать предложения';

  @override
  String get showSuggestionsDescription =>
      'Показывает умные предложения на панели инструментов, когда сессия не запущена';

  @override
  String get onboardingSuggestionsTitle => 'Умные предложения';

  @override
  String get onboardingSuggestionsBody =>
      'Получайте персонализированные рекомендации проектов на панели инструментов во время работы';

  @override
  String get onboardingSessionModeTitle => 'Режим сессии';

  @override
  String get onboardingSessionModeBody =>
      'Начинайте сфокусированные рабочие сессии и автоматически отслеживайте время, затраченное на каждый проект';

  @override
  String get suggestionsFeatureDeadlines =>
      'Напоминания о дедлайнах для предстоящих проектов';

  @override
  String get suggestionsFeatureResume =>
      'Продолжить последний проект, над которым вы работали';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Продолжить недавно изменённые треки';

  @override
  String get suggestionsEnableToggle => 'Включить умные предложения';

  @override
  String get canBeChangedInSettings => 'Можно изменить позже в Настройках';

  @override
  String get next => 'Далее';

  @override
  String get createProject => 'Создать';

  @override
  String get createProjectTooltip => 'Создать новую папку проекта';

  @override
  String get createProjectSelectFolder => 'Выбрать расположение';

  @override
  String get createProjectSelectFolderHint =>
      'Выберите папку для нового проекта';

  @override
  String get createProjectNameTitle => 'Назовите проект';

  @override
  String get createProjectNameHint =>
      'Выберите схему именования для новой папки';

  @override
  String get createProjectSchemeArtistTrack => 'Исполнитель — Трек';

  @override
  String get createProjectSchemeCollab => 'Совместная работа';

  @override
  String get createProjectSchemeDate => 'Дата — Трек';

  @override
  String get createProjectSchemeCustom => 'Произвольное';

  @override
  String get createProjectSchemeRemix => 'Ремикс';

  @override
  String get createProjectArtistName => 'Имя исполнителя';

  @override
  String get createProjectTrackName => 'Название трека';

  @override
  String get createProjectCustomName => 'Имя папки';

  @override
  String get createProjectAddArtist => 'Добавить исполнителя';

  @override
  String get createProjectOriginalArtist => 'Оригинальный исполнитель';

  @override
  String get createProjectRemixerName => 'Ремиксер';

  @override
  String get createProjectAddRemixer => 'Добавить ремиксера';

  @override
  String get createProjectSelectDaw => 'Открыть в DAW';

  @override
  String get createProjectSelectDawHint => 'Выберите DAW для этого проекта';

  @override
  String get createProjectDetectDaws => 'Найти установленные DAW';

  @override
  String get createProjectSkipDaw => 'Только создать папку';

  @override
  String get createProjectNoDawsFound =>
      'DAW не найдены. Папка всё равно будет создана.';

  @override
  String get createProjectCreateOnly => 'Создать папку';

  @override
  String get createProjectCreateAndOpen => 'Создать и открыть';

  @override
  String get createProjectFolderExists => 'Папка с таким именем уже существует';

  @override
  String get createProjectInvalidChars =>
      'Имя папки содержит недопустимые символы';

  @override
  String get createProjectError => 'Не удалось создать папку';

  @override
  String get createProjectIncludeDate => 'Включить префикс даты';

  @override
  String get createProjectCreatedTitle => 'Папка создана';

  @override
  String get createProjectCreatedMessage => 'Папка проекта создана:';

  @override
  String get createProjectCopyName => 'Скопировать имя папки';

  @override
  String get createProjectNameCopied => 'Имя папки скопировано';

  @override
  String get createProjectTrackSession => 'Отслеживать сеанс с этого момента';

  @override
  String get pendingFolderSessionTitle => 'Обнаружен рабочий сеанс';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'Вы работали над \"$projectName\" в течение $duration.';
  }

  @override
  String get pendingFolderSessionContinue => 'Продолжить сеанс';

  @override
  String get pendingFolderSessionEndRecord => 'Завершить и записать';

  @override
  String get activeSessionSwitchTitle => 'Сессия уже активна';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'Запущена сессия для «$current». Переключиться на «$next» и сохранить текущую сессию?';
  }

  @override
  String get activeSessionSwitch => 'Переключить';

  @override
  String get pendingProjectWaiting => 'Ожидание файла проекта…';

  @override
  String get pendingProjectDelete => 'Удалить пустую папку';

  @override
  String get pendingProjectDeleteTitle => 'Удалить папку?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return 'Удалить «$folderName» и её содержимое?';
  }

  @override
  String get pendingProjectDismiss => 'Прекратить отслеживание папки';

  @override
  String get pendingProjectDismissTitle => 'Остановить отслеживание?';

  @override
  String get pendingProjectDismissKeep => 'Сохранить папку';

  @override
  String get pendingProjectDismissDelete => 'Удалить и закрыть';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'Папка не пуста';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return 'Папка «$folderName» содержит файлы. Удалить всё безвозвратно?';
  }

  @override
  String get pendingProjectRefresh => 'Проверить файл проекта';

  @override
  String get pendingProjectNotFound => 'Файл проекта пока не найден';

  @override
  String get phases => 'Фазы';

  @override
  String get phasesSubtitle =>
      'Добавление, удаление и изменение порядка фаз проекта';

  @override
  String get phasesDescription =>
      'Фазы отслеживают этап каждого проекта в вашем рабочем процессе (например, Идея → Сведение → Мастеринг). Перетаскивайте для изменения порядка, нажмите на цветную точку, чтобы изменить цвет, и отметьте фазу как завершённую, чтобы считать её завершённой во всём приложении.';

  @override
  String get resetToDefaults => 'Сбросить до стандартных';

  @override
  String get addPhase => 'Добавить фазу';

  @override
  String get phaseNameHint => 'Название фазы';

  @override
  String get phaseDuplicateError => 'Фаза с таким названием уже существует';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count проектов используют эту фазу',
      many: '$count проектов используют эту фазу',
      few: '$count проекта используют эту фазу',
      one: '$count проект использует эту фазу',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Выбрать цвет';

  @override
  String get markAsFinished => 'Отметить как завершённую фазу';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count проекта используют фазы, которых больше не будет.',
      many: '$count проектов используют фазы, которых больше не будет.',
      few: '$count проекта используют фазы, которых больше не будет.',
      one: '1 проект использует фазу, которой больше не будет.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Эти проекты сохранят текущий статус, но не будут отображаться в фильтрах фаз. Вы всегда можете снова добавить эти фазы позже.';

  @override
  String get resetPhasesConfirm =>
      'Сбросить все пользовательские фазы, цвета и флаги завершённых фаз к значениям по умолчанию?';

  @override
  String get camelotGenerateButton => 'Создать микс';

  @override
  String get camelotDialogTitle => 'Микс Camelot';

  @override
  String get camelotDialogDescription =>
      'Сортирует треки по гармонической совместимости с помощью колеса Camelot. Близость BPM используется как дополнительный критерий.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count треков подходят (тональность задана)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count будут пропущены (нет тональности)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'Ни один трек не имеет заданной тональности. Откройте проект и задайте тональность.';

  @override
  String get camelotGenerate => 'Создать';

  @override
  String camelotQueueGenerated(int count) {
    return 'Очередь заполнена $count треками в гармоническом порядке';
  }

  @override
  String get camelotWheelGuideTooltip => 'Руководство по колесу Camelot';

  @override
  String get camelotWheelGuideTitle => 'Руководство по колесу Camelot';

  @override
  String get camelotGuideRingsTitle => 'Кольца';

  @override
  String get camelotGuideRingsBody =>
      'Внутреннее кольцо (A)  →  минорные тональности\nВнешнее кольцо (B)  →  мажорные тональности';

  @override
  String get camelotGuideNumbersTitle => 'Цифры 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Позиции расставлены по часовой стрелке. Каждое число представляет гармоническое окружение — соседи разделяют сильные тональные связи.';

  @override
  String get camelotGuideColoursTitle => 'Цветовой гид';

  @override
  String get camelotGuideColoursBody =>
      '● Яркий  →  тональность вашей песни\n● Мягкий  →  совместим для сведения\n● Приглушённый  →  избегать для плавного сведения';

  @override
  String get camelotGuideTransitionsTitle => 'Совместимые переходы';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (тот же номер, смена кольца)\n  Параллельный мажор/минор — практически незаметно.\n\n8A → 7A или 9A  (±1, то же кольцо)\n  Соседняя тональность — плавное, тонкое изменение.\n\n8A → 1A или 3A  (±7, то же кольцо)\n  Подъём или падение энергии — более резкий переход.';

  @override
  String get playerMixSuggestions => 'ПРЕДЛОЖЕНИЯ МИКСА';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get noPreviewSongsAvailable => 'Нет доступных песен для предпросмотра';

  @override
  String get upNext => 'Далее';

  @override
  String get playbackModeNormal => 'Обычный';

  @override
  String get playbackModeRepeat => 'Повтор';

  @override
  String get playbackModeShuffle => 'Перемешать';

  @override
  String get hideDatesInNames => 'Скрывать даты в названиях проектов';

  @override
  String get hideDatesInNamesDescription =>
      'Некоторые DAW добавляют дату создания в начало имени файла проекта (например, «2026-08-02 - Мой трек»). Скройте её, чтобы отображался только заголовок. Сами файлы не переименовываются.';

  @override
  String get findPreviewAutomatically => 'Найти автоматически';

  @override
  String get noPreviewSongFoundAutomatically =>
      'В папках сведения этого проекта не найдено превью.';

  @override
  String get selectProjects => 'Выбрать';

  @override
  String sharePreviewSongText(String name) {
    return 'Превью: $name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return 'Превью (ZIP): $name';
  }

  @override
  String get songParts => 'Инструменты и партии';

  @override
  String partsProgress(int done, int total) {
    return '$done из $total финальных дублей';
  }

  @override
  String get noPartsYet => 'Партии пока не добавлены';

  @override
  String get noPartsYetHint =>
      'Перечислите инструменты, которые нужны треку, кто их играет и на какой стадии каждый дубль.';

  @override
  String get addPart => 'Добавить партию';

  @override
  String get addPartHint => 'например: Барабаны, Ведущий вокал, Бас';

  @override
  String get partNameLabel => 'Партия';

  @override
  String get partNameRequired => 'Укажите название партии';

  @override
  String get partPerformerLabel => 'Исполнитель';

  @override
  String get partPerformerHint => 'Кто играет';

  @override
  String get partNotesLabel => 'Заметки к партии';

  @override
  String get partStatusLabel => 'Статус дубля';

  @override
  String get partStatusNeeded => 'Нужно записать';

  @override
  String get partStatusRecording => 'Записывается';

  @override
  String get partStatusEarlyTake => 'Черновой дубль';

  @override
  String get partStatusFinalTake => 'Финальный дубль';

  @override
  String get editPart => 'Изменить партию';

  @override
  String get deletePart => 'Удалить партию';

  @override
  String get partsUnassignedPerformer => 'Не назначен';

  @override
  String get partTemplates => 'Шаблоны партий';

  @override
  String get importPartsFromTemplate => 'Импортировать партии из шаблона';

  @override
  String get managePartTemplates => 'Управление шаблонами партий';

  @override
  String get selectPartTemplate => 'Выберите шаблон партий';

  @override
  String get noPartTemplatesAvailable => 'Нет доступных шаблонов партий';

  @override
  String get noPartTemplatesYet => 'Шаблонов партий пока нет';

  @override
  String get createFirstPartTemplate =>
      'Создайте шаблон, чтобы переиспользовать один и тот же состав в разных треках';

  @override
  String get createPartTemplate => 'Создать шаблон партий';

  @override
  String get editPartTemplate => 'Изменить шаблон партий';

  @override
  String get deletePartTemplate => 'Удалить шаблон партий';

  @override
  String deletePartTemplateConfirm(String name) {
    return 'Удалить шаблон партий «$name»?';
  }

  @override
  String get partTemplateCreated => 'Шаблон партий создан';

  @override
  String get partTemplateUpdated => 'Шаблон партий обновлён';

  @override
  String get partTemplateDeleted => 'Шаблон партий удалён';

  @override
  String get partTemplateItems => 'Партии (по одной в строке)';

  @override
  String get partTemplateItemsHint =>
      'Барабаны — Алекс\nБас — Сэм\nВедущий вокал';

  @override
  String get partTemplateItemsHelp =>
      'По одной партии в строке. Исполнителя укажите после тире: Барабаны — Алекс';

  @override
  String get partTemplateItemsRequired => 'Добавьте хотя бы одну партию';

  @override
  String get partTemplateNameAndItemsRequired =>
      'Нужны название и хотя бы одна партия';

  @override
  String partTemplateItemCount(int count) {
    return 'Партий: $count';
  }

  @override
  String partTemplateImported(String name, int count) {
    return 'Шаблон партий «$name» импортирован ($count партий)';
  }

  @override
  String get errorLoadingPartTemplates => 'Ошибка загрузки шаблонов партий';

  @override
  String get exportPartsCsv => 'Экспортировать партии в CSV';

  @override
  String get exportAllPartsCsv => 'Экспортировать партии всех треков в CSV';

  @override
  String get exportAllPartsCsvSubtitle =>
      'Одна строка таблицы на каждую партию по всем проектам — чтобы делиться прогрессом с соавторами';

  @override
  String get noPartsToExport => 'Нет партий для экспорта';

  @override
  String partsCsvExported(int count) {
    return 'Экспортировано партий: $count';
  }

  @override
  String get projectExportPartsLabel => 'Партии:';

  @override
  String get csvHeaderProject => 'Проект';

  @override
  String get csvHeaderPart => 'Партия';

  @override
  String get csvHeaderPerformer => 'Исполнитель';

  @override
  String get csvHeaderStatus => 'Статус';

  @override
  String get csvHeaderNotes => 'Заметки';

  @override
  String get exportPartsXlsx => 'Экспортировать партии в Excel (.xlsx)';

  @override
  String get exportAllPartsXlsx =>
      'Экспортировать партии всех треков в Excel (.xlsx)';

  @override
  String get exportAllPartsXlsxSubtitle =>
      'Та же таблица, что и CSV, но с закреплённой шапкой, фильтрами и цветными статусами дублей';

  @override
  String get importPartsFromSpreadsheet => 'Импортировать партии из таблицы';

  @override
  String get partsImportPickerTitle => 'Выберите файл CSV или Excel';

  @override
  String partsImported(int added, int updated) {
    return 'Добавлено партий: $added, обновлено: $updated';
  }

  @override
  String get partsImportNothingFound => 'В этом файле не найдено партий';

  @override
  String partsImportFailed(String error) {
    return 'Не удалось прочитать эту таблицу: $error';
  }

  @override
  String get partsMoreActions => 'Другие действия с партиями';

  @override
  String partsPageTitle(String name) {
    return '$name — партии';
  }

  @override
  String get manageParts => 'Управление партиями';

  @override
  String partsMoreCount(int count) {
    return 'ещё $count';
  }

  @override
  String get searchParts => 'Поиск по партиям';

  @override
  String get allStatuses => 'Все статусы';

  @override
  String get allPerformers => 'Все исполнители';

  @override
  String partsSelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get setPartStatus => 'Задать статус';

  @override
  String get assignPartPerformer => 'Назначить исполнителя';

  @override
  String get deleteSelectedParts => 'Удалить выбранные';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return 'Удалить партий из этого трека: $count?';
  }

  @override
  String partsDeleted(int count) {
    return 'Удалено партий: $count';
  }

  @override
  String get noPartsMatchFilters => 'Нет партий, подходящих под эти фильтры';

  @override
  String get reorderNeedsUnfilteredList =>
      'Сбросьте поиск, фильтры и сортировку, чтобы менять порядок партий';

  @override
  String get projectMarkers => 'Маркеры';

  @override
  String projectMarkerUnnamed(int index) {
    return 'Маркер $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return 'Регион $index';
  }

  @override
  String get projectMarkerJumpTooltip => 'Перейти к этому месту в превью трека';

  @override
  String get projectMarkerNoPreviewSong =>
      'Добавьте превью трека, чтобы переходить к маркерам';

  @override
  String get projectDetailLayout => 'Макет Деталей Проекта';

  @override
  String get projectDetailLayoutSettingDescription =>
      'Как устроена страница деталей проекта.';

  @override
  String get projectDetailLayoutClassic => 'Классический';

  @override
  String get projectDetailLayoutClassicDescription => 'Всё в одной прокрутке.';

  @override
  String get projectDetailLayoutSectioned => 'Разделы';

  @override
  String get projectDetailLayoutSectionedDescription =>
      'Панель слева выбирает по одному разделу.';

  @override
  String get stackAsVersions => 'Объединить как версии';

  @override
  String get stackNeedsTwoVersions =>
      'Выберите не менее двух проектов, чтобы объединить их как версии одного основного проекта.';

  @override
  String stackCreatedMessage(int count) {
    return '$count версий объединены в один основной проект.';
  }

  @override
  String get stackVersionsTitle => 'Версии';

  @override
  String stackVersionCount(int count) {
    return 'Версий: $count';
  }

  @override
  String get stackAddVersion => 'Добавить версию';

  @override
  String get stackAddVersionTitle => 'Добавить версию';

  @override
  String get stackAddVersionEmpty =>
      'Нет проектов вне стеков, которые можно добавить.';

  @override
  String get stackRemoveVersion => 'Убрать из стека';

  @override
  String get stackRemoveVersionMessage =>
      'Файл проекта остаётся на диске и возвращается в список как отдельный проект.';

  @override
  String get stackUnstack => 'Разъединить';

  @override
  String get stackUnstackTitle => 'Разъединить этот основной проект?';

  @override
  String get stackUnstackMessage =>
      'Каждая версия снова станет отдельным проектом с метаданными, которые были до объединения. Общие заметки, задачи и срок, хранившиеся в основном проекте, будут удалены.';

  @override
  String get stackDefaultVersion => 'Открывается по умолчанию';

  @override
  String get stackSetDefaultVersion => 'Открывать эту версию по умолчанию';

  @override
  String get stackChooseVersionToOpen => 'Какую версию открыть?';

  @override
  String get stackMemberOf => 'Версия проекта';

  @override
  String get stackMemberNotice =>
      'Этот файл — одна из версий объединённого проекта. Общие метаданные, задачи и рабочее время хранятся в основном проекте, а не здесь.';

  @override
  String get stackOpenMainProject => 'Открыть основной проект';

  @override
  String get stackWorkTimeAcrossVersions => 'Всего по всем версиям';

  @override
  String get scanModeVersionStack => 'Стек версий';

  @override
  String get scanModeVersionStackDescription =>
      'Все файлы проектов в папке становятся одним основным проектом с общими метаданными, задачами и рабочим временем. Новые файлы добавляются автоматически.';

  @override
  String stackTooltipStacked(int count) {
    return '$count версий объединены в один основной проект';
  }

  @override
  String get stackMetadataSourceTitle => 'Какой проект сделать основным?';

  @override
  String get stackMetadataSourceBody =>
      'У нескольких из них уже есть собственные данные. Выбранный станет основным проектом: его имя, BPM, тональность, заметки, задачи и срок будут использоваться стеком. Ничего не объединяется и не теряется — остальные сохраняют свои данные, и разъединение их вернёт.';

  @override
  String get stackMetadataSourceOldestHint => 'Самая старая — рекомендуется';

  @override
  String get stackMetadataNoneLabel => 'Пока нет данных';

  @override
  String stackMetadataTodosLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задач',
      few: '$count задачи',
      one: '1 задача',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataNotesLabel => 'заметки';

  @override
  String get stackNotStackedYet => 'Пока не объединено';

  @override
  String get stackStartFromHere =>
      'Добавьте другие файлы проектов, и они станут версиями одного основного проекта с общими метаданными, задачами и рабочим временем.';

  @override
  String get stackSearchProjects => 'Поиск проектов';

  @override
  String get stackSearchNoMatches => 'Нет проектов, соответствующих запросу.';

  @override
  String get stackStartedMessage => 'Объединено в один основной проект.';

  @override
  String get stackDefaultVersionTooltip =>
      'Эта версия открывается по умолчанию при запуске DAW.';

  @override
  String stackAddVersionsConfirm(int count) {
    return 'Добавить: $count';
  }

  @override
  String get stackAddVersionMultiTitle => 'Добавить версии';

  @override
  String get stackSelectAll => 'Выбрать все';

  @override
  String get stackClearSelection => 'Очистить';

  @override
  String stackMetadataPartsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count партий',
      few: '$count партии',
      one: '1 партия',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataDeadlineLabel => 'срок';

  @override
  String get stackMetadataRenamedLabel => 'своё название';

  @override
  String stackMetadataWorkHours(String hours) {
    return 'записано $hours ч';
  }

  @override
  String get stackUnstackReleaseTitle => 'Какая версия останется в релизе?';

  @override
  String stackUnstackReleaseBody(String releases) {
    return 'Этот проект — трек в $releases. При разъединении объединённая запись исчезает, поэтому её место должна занять одна из версий — выберите, на какую будет ссылаться релиз.';
  }

  @override
  String get stackAutoConfirmTitle => 'Объединить эти версии?';

  @override
  String stackAutoConfirmBody(int projects, int folders) {
    return 'Стек версий сгруппирует $projects проектов в $folders папках. Каждая папка станет основным проектом с общими метаданными, задачами и рабочим временем. Ничего не удаляется, и позже их можно разъединить.';
  }

  @override
  String get stackAutoConfirmApply => 'Объединить';

  @override
  String stackAutoFolderEntry(String folder, int count) {
    return '$folder — версий: $count';
  }

  @override
  String get stackAutoJoinsExisting =>
      'добавится к существующему основному проекту';

  @override
  String get untitledTheme => 'Тема без названия';

  @override
  String switchToTheme(String themeName) {
    return 'Переключиться на $themeName';
  }

  @override
  String get newTheme => 'Новая тема';

  @override
  String get editTheme => 'Изменить тему';

  @override
  String get duplicateTheme => 'Дублировать';

  @override
  String get deleteThemeTitle => 'Удалить тему?';

  @override
  String deleteThemeMessage(String name) {
    return '«$name» будет удалена. Это действие необратимо.';
  }

  @override
  String get themeNameLabel => 'Название темы';

  @override
  String get themeNameHint => 'например, Studio Amber';

  @override
  String get themeNameRequired => 'Укажите название темы.';

  @override
  String get themeColorAccent => 'Акцент';

  @override
  String get themeColorSecondaryAccent => 'Дополнительный акцент';

  @override
  String get themeColorBackground => 'Фон';

  @override
  String get themeColorCards => 'Карточки и панели';

  @override
  String get themeCardRoundness => 'Скругление карточек';

  @override
  String get themeButtonRoundness => 'Скругление кнопок';

  @override
  String themeLowContrastWarning(String ratio) {
    return 'Низкий контраст ($ratio:1). Текст может быть трудно читать.';
  }

  @override
  String get exportTheme => 'Экспорт темы';

  @override
  String get importTheme => 'Импорт темы';

  @override
  String themeExported(String path) {
    return 'Тема экспортирована в $path';
  }

  @override
  String themeImported(String name) {
    return '«$name» импортирована';
  }

  @override
  String get themeImportFailed => 'Этот файл не является допустимой темой.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexInvalid => 'Используйте #RRGGBB';

  @override
  String get apply => 'Применить';

  @override
  String themeCopyName(String name) {
    return '$name — копия';
  }

  @override
  String get suggestedColorsLabel => 'Предлагаемые цвета';
}
