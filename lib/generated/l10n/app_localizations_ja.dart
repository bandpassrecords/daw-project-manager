// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'DAWプロジェクトマネージャー';

  @override
  String get projectDetails => 'プロジェクトの詳細';

  @override
  String get back => '戻る';

  @override
  String get save => '保存';

  @override
  String get enable => '有効にする';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get undo => '元に戻す';

  @override
  String get customInterval => 'カスタム';

  @override
  String get close => '閉じる';

  @override
  String get launch => '開く';

  @override
  String get view => '表示';

  @override
  String get openFolder => 'フォルダを開く';

  @override
  String get openInDaw => 'DAWで起動';

  @override
  String get extract => '抽出';

  @override
  String get extracting => '抽出中…';

  @override
  String get extractingMetadata => 'メタデータを抽出中...';

  @override
  String get deepScan => '詳細スキャン';

  @override
  String get rescan => '再スキャン';

  @override
  String get refreshProject => '更新';

  @override
  String get scanning => 'スキャン中…';

  @override
  String get newProjectBadge => '新規';

  @override
  String get projectName => 'プロジェクト名';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'キー（例：C#m、F major）';

  @override
  String get notes => 'メモ';

  @override
  String get expandNotes => '展開';

  @override
  String get collapseNotes => '折りたたむ';

  @override
  String get projectNotesFromDaw => 'プロジェクトノート（DAWファイルより）';

  @override
  String get projectPhase => 'プロジェクトフェーズ';

  @override
  String get failedToLoad => '読み込みに失敗しました';

  @override
  String get fileMissing => 'ファイルが見つかりません。';

  @override
  String launchingProject(String projectName) {
    return '$projectNameを開いています…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return '$projectNameを開けませんでした';
  }

  @override
  String get clearLibrary => 'ライブラリをクリア';

  @override
  String get clearLibraryMessage =>
      'これにより、保存されたすべてのプロジェクトとソースフォルダが削除されます。続行しますか？';

  @override
  String get clear => 'クリア';

  @override
  String get roots => 'プロジェクトフォルダ';

  @override
  String get pathsSettingsDangerZoneTitle => 'ライブラリ';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      '現在のプロファイルのすべてのプロジェクトとプロジェクトフォルダーをクリアします。';

  @override
  String get projectFoldersSectionTitle => 'プロジェクトフォルダー';

  @override
  String get projectFoldersSectionSubtitle => 'DAWプロジェクトを探すためにスキャンされるフォルダーです。';

  @override
  String get projectFoldersEmptyTitle => 'プロジェクトフォルダーがありません';

  @override
  String get projectFoldersEmptySubtitle =>
      '少なくとも1つのフォルダーを追加して、プロジェクトのスキャンを開始してください。';

  @override
  String get notScannedYet => '未スキャン';

  @override
  String lastScan(String date) {
    return '最終スキャン: $date';
  }

  @override
  String get excludedFoldersSectionTitle => '除外フォルダー';

  @override
  String get excludedFoldersSectionSubtitle =>
      'これらのフォルダーは、プロジェクトフォルダー内にあってもスキャン時にスキップされます。';

  @override
  String get addExcludedFolder => '除外を追加';

  @override
  String get selectExcludedFolder => '除外するフォルダーを選択';

  @override
  String get excludedFoldersEmptyTitle => '除外フォルダーはありません';

  @override
  String get excludedFoldersEmptySubtitle => '任意: スキャンしたくないフォルダーを追加できます。';

  @override
  String get removeExcludedFolderTitle => '除外フォルダーを削除しますか？';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'このフォルダーは除外されなくなります:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath => 'このフォルダーは除外されなくなります。';

  @override
  String get desktopOnlyPathsSettings => 'このページはデスクトップアプリでのみ利用できます。';

  @override
  String get renameProjectFolderTitle => '表示名';

  @override
  String get flatpakPortalPathExplanation =>
      'このパスはサンドボックス化された場所であり、実際のフォルダーの場所ではありません — Flatpakはこの情報をアプリと共有しません。代わりに上の名前で識別してください。';

  @override
  String get removeProjectFolderTitle => 'プロジェクトフォルダーを削除しますか？';

  @override
  String removeProjectFolderMessage(String path) {
    return '「$path」を削除してもよろしいですか？これにより、リリースに含まれていないこのフォルダー内のプロジェクトも削除されます。';
  }

  @override
  String get projects => 'プロジェクト';

  @override
  String get hidden => '非表示';

  @override
  String get profileManager => 'プロファイルマネージャー';

  @override
  String get createNewProfile => '新しいプロファイルを作成';

  @override
  String get profileName => 'プロファイル名';

  @override
  String get create => '作成';

  @override
  String get profiles => 'プロファイル';

  @override
  String get active => 'アクティブ';

  @override
  String get switchProfile => '切り替え';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get addFolder => 'フォルダを追加';

  @override
  String get searchProjects => 'プロジェクトを検索...';

  @override
  String get searchReleases => 'リリースを検索...';

  @override
  String get searchPlaylists => 'プレイリストを検索...';

  @override
  String get noReleasesFound => 'リリースが見つかりません';

  @override
  String get noPlaylistsFound => 'プレイリストが見つかりません';

  @override
  String get tryDifferentSearch => '別の検索用語を試してください';

  @override
  String get deepScanConfirm =>
      '詳細スキャンは、プロジェクトファイルから完全なメタデータを抽出します：\n• BPM（1分あたりのビート数）\n• 音楽キー\n• DAWバージョン\n• プロジェクトノート（対応DAWのみ）\n\n通常のスキャンより時間がかかります。続行しますか？';

  @override
  String get deepScanViewSupportedDaws => '対応DAWとフィールドを見る';

  @override
  String get deepScanOnlyUnscanned => 'メタデータのないプロジェクトのみスキャン';

  @override
  String get metadataExtractionTitle => 'メタデータ抽出';

  @override
  String get metadataExtractionSubtitle => '各DAWがサポートするデータを確認';

  @override
  String get metadataExtractionIntro =>
      '詳細スキャンは、これらの項目の一部をプロジェクトファイルから自動的に読み取ることができます — 残りは手動で入力する必要があります。この表は、各対応DAWで現在何が自動化されているかを示しています。';

  @override
  String get metadataFieldKey => 'キー';

  @override
  String get metadataFieldVersion => 'DAWバージョン';

  @override
  String get metadataExtractionManualNote =>
      '自動対応していない項目は、プロジェクト詳細で手動入力できます。特にBPMとキーについては、プロジェクトの隣にbpm.txtまたはkey.txtファイルを置くと、次回のスキャンで読み込まれます。';

  @override
  String get metadataExtractedSuccessfully => 'メタデータの抽出に成功しました';

  @override
  String failedToExtractMetadata(String error) {
    return 'メタデータの抽出に失敗しました: $error';
  }

  @override
  String get saved => '保存しました';

  @override
  String get failedToLaunchDaw => 'DAWを開けませんでした';

  @override
  String get releaseDetails => 'リリースの詳細';

  @override
  String get releaseNotFound => 'リリースが見つかりません';

  @override
  String get error => 'エラー';

  @override
  String get loading => '読み込み中...';

  @override
  String get deleteProfile => 'プロファイルを削除';

  @override
  String deleteProfileMessage(String profileName) {
    return '「$profileName」を削除してもよろしいですか？これにより、このプロファイルのすべてのプロジェクト、プロジェクトフォルダ、リリースが削除されます。';
  }

  @override
  String get editProfile => 'プロファイルを編集';

  @override
  String get changePhoto => '写真を変更';

  @override
  String get remove => '削除';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'このリリースから「$trackName」を削除してもよろしいですか？';
  }

  @override
  String get saveName => '名前を保存';

  @override
  String get profilePhotoUpdated => 'プロファイル写真を更新しました。';

  @override
  String get profilePhotoRemoved => 'プロファイル写真を削除しました。';

  @override
  String profileRenamed(String newName) {
    return 'プロファイル名を「$newName」に変更しました';
  }

  @override
  String profileCreated(String name) {
    return 'プロファイル「$name」を作成しました';
  }

  @override
  String profileDeleted(String name) {
    return 'プロファイル「$name」を削除しました';
  }

  @override
  String get pleaseEnterProfileName => 'プロファイル名を入力してください';

  @override
  String failedToCreateProfile(String error) {
    return 'プロファイルの作成に失敗しました: $error';
  }

  @override
  String get noProfilesFound => 'プロファイルが見つかりません。上で作成してください。';

  @override
  String get clearLibraryTooltip => 'ライブラリをクリア（プロジェクトとプロジェクトフォルダ）';

  @override
  String lastModified(String date) {
    return '最終更新: $date';
  }

  @override
  String get name => '名前';

  @override
  String get status => 'ステータス';

  @override
  String get phase => 'フェーズ';

  @override
  String get filterByPhase => 'フェーズでフィルター';

  @override
  String get filters => 'フィルター';

  @override
  String get allPhases => 'すべてのフェーズ';

  @override
  String get filterByDaw => 'DAWでフィルター';

  @override
  String get allDaws => 'すべてのDAW';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => 'DAWをクリア';

  @override
  String get filterByKey => 'キーでフィルター';

  @override
  String get allKeys => 'すべてのキー';

  @override
  String get lastModifiedColumn => '最終更新';

  @override
  String get actions => 'アクション';

  @override
  String get hide => '非表示にする';

  @override
  String get unhide => '表示する';

  @override
  String get extractMetadata => 'メタデータを抽出';

  @override
  String get createRelease => 'リリースを作成';

  @override
  String get clearSelection => '選択をクリア';

  @override
  String get selectAllProjects => 'すべてのプロジェクトを選択';

  @override
  String get switchingProfiles => 'プロファイルを切り替え中...';

  @override
  String get scanningProjects => 'プロジェクトをスキャン中...';

  @override
  String scanProgressLabel(int current, int total) {
    return 'プロジェクトを読み込み中 $current / $total…';
  }

  @override
  String get search => '検索';

  @override
  String get projectsTab => 'プロジェクト';

  @override
  String get releasesTab => 'リリース';

  @override
  String get showHidden => '非表示を表示';

  @override
  String get showAll => 'すべて表示';

  @override
  String get showOnlyHidden => '非表示のみ表示';

  @override
  String get deleteRootPath => 'プロジェクトフォルダーを削除';

  @override
  String deleteRootPathMessage(String path) {
    return '「$path」を削除してもよろしいですか？これにより、リリースに含まれていないこのフォルダ内のすべてのプロジェクトも削除されます。';
  }

  @override
  String rootsCount(int count) {
    return 'プロジェクトフォルダ: $count';
  }

  @override
  String projectsCount(int count) {
    return 'プロジェクト: $count';
  }

  @override
  String get hiddenOnly => '（非表示のみ）';

  @override
  String hiddenCount(int count) {
    return '（$count非表示）';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$countプロジェクト$pluralを非表示にしました。';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$countプロジェクト$pluralを表示しました。';
  }

  @override
  String failedToHideProjects(String error) {
    return 'プロジェクトの非表示に失敗しました: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'プロジェクトの表示に失敗しました: $error';
  }

  @override
  String get deleteMissingProjects => '見つからない項目を削除';

  @override
  String get deleteMissingProjectsTitle => '見つからないプロジェクトを削除しますか？';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return 'このマシンでファイルが見つからなかった$count件のプロジェクト$pluralは、すべてのメモ、締切、セッション履歴とともに完全に削除されます。この操作は元に戻せません。';
  }

  @override
  String get deleteMissingProjectsConfirmButton => '完全に削除';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return '見つからないプロジェクト$pluralを$count件削除しました。';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return 'リリースの一部である$count件のプロジェクト$pluralも削除する（そのリリースからも削除されます）';
  }

  @override
  String hideProjectMessage(String projectName) {
    return '「$projectName」を非表示にしてもよろしいですか？';
  }

  @override
  String releaseCreated(String title) {
    return 'リリース「$title」を作成しました。';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'リリースの作成に失敗しました: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'フォルダの追加エラー: $error';
  }

  @override
  String get folderAlreadyAdded => 'このフォルダはすでに追加されています。';

  @override
  String get noProjectsFoundInRoots => '選択したプロジェクトフォルダにプロジェクトが見つかりませんでした。';

  @override
  String get selectProjectsFolder => 'プロジェクトフォルダを選択';

  @override
  String get enterReleaseTitle => 'リリースタイトルを入力';

  @override
  String get releaseTitle => 'リリースタイトル';

  @override
  String get enterReleaseTitleHint => 'リリースタイトルを入力';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return '$countプロジェクト$pluralのメタデータを抽出しました。$failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count失敗しました。';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'BPMファイルの書き込みに失敗しました: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'キーファイルの書き込みに失敗しました: $error';
  }

  @override
  String failedToLaunch(String error) {
    return '起動に失敗しました: $error';
  }

  @override
  String get libraryCleared => 'ライブラリをクリアしました。';

  @override
  String scanType(String type) {
    return '$typeスキャン';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type完了: $countプロジェクト$pluralを追加/更新しました。';
  }

  @override
  String get scanCancelled => 'スキャンをキャンセルしました。';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count件のプロジェクト$pluralを読み込めませんでした。';
  }

  @override
  String get scanFailuresSnackbarAction => '詳細';

  @override
  String get scanFailuresDialogTitle => 'スキャンエラー';

  @override
  String get scanFailuresDialogIntro =>
      'スキャン中にこれらのファイルを読み取れませんでした（削除、移動、または他のプログラムによってロックされている可能性があります）：';

  @override
  String projectsSelected(int count, String plural) {
    return '$countプロジェクト$pluralを選択しました';
  }

  @override
  String openingFolder(String projectName) {
    return '$projectNameのフォルダを開いています…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'フォルダを開けませんでした: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder => 'フォルダを開くためのOSがサポートされていません。';

  @override
  String get noProjectsAvailable => 'プロジェクトがありません。まずプロジェクトを追加してください。';

  @override
  String get createNewRelease => '新しいリリースを作成';

  @override
  String get deleteRelease => 'リリースを削除';

  @override
  String deleteReleaseMessage(String title) {
    return '「$title」を削除してもよろしいですか？';
  }

  @override
  String releaseDeleted(String title) {
    return 'リリース「$title」を削除しました。';
  }

  @override
  String releasesSelected(int count, String plural) {
    return '$count件のリリース$pluralを選択しました';
  }

  @override
  String get deleteSelectedReleases => '選択項目を削除';

  @override
  String deleteSelectedReleasesConfirm(int count, String plural) {
    return '$count件のリリース$pluralを削除してもよろしいですか?';
  }

  @override
  String releasesDeleted(int count, String plural) {
    return '$count件のリリース$pluralを削除しました';
  }

  @override
  String get selectTracks => 'トラックを選択';

  @override
  String get continueButton => '続行';

  @override
  String get noReleasesYet => 'まだリリースがありません';

  @override
  String get createFirstRelease => 'プロジェクトからトラックを選択して最初のリリースを作成してください';

  @override
  String releasesCount(int count) {
    return 'リリース（$count）';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'リリースの読み込みエラー: $error';
  }

  @override
  String tracksCount(int count) {
    return 'トラック（$count）';
  }

  @override
  String get addTracks => 'トラックを追加';

  @override
  String get allProjectsAlreadyInRelease => 'すべてのプロジェクトがすでにこのリリースに含まれています。';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'リリースに$countトラック$pluralを追加しました。';
  }

  @override
  String releaseFilesCount(int count) {
    return 'リリースファイル（$count）';
  }

  @override
  String get addFiles => 'ファイルを追加';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'リリースに$countファイル$pluralを追加しました。';
  }

  @override
  String failedToAddFiles(String error) {
    return 'ファイルの追加に失敗しました: $error';
  }

  @override
  String get noFilesToDownload => 'ダウンロードするファイルがありません。';

  @override
  String zipFileSaved(String path) {
    return 'ZIPファイルを保存しました: $path';
  }

  @override
  String get creatingZipFile => 'ZIPファイルを作成中...';

  @override
  String failedToCreateZip(String error) {
    return 'ZIPの作成に失敗しました: $error';
  }

  @override
  String get selectedFileDoesNotExist => '選択したファイルが存在しません。';

  @override
  String get imageSavedSuccessfully => '画像を正常に保存しました！';

  @override
  String failedToSaveImage(String error) {
    return '画像の保存に失敗しました: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'リリースの読み込みエラー: $error';
  }

  @override
  String get errorLoadingProjects => 'プロジェクトの読み込みエラー: null';

  @override
  String get releaseSaved => 'リリースを保存しました。';

  @override
  String get releaseDate => 'リリース日';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'リリース日の保存に失敗しました: $error';
  }

  @override
  String get releaseDateSaved => 'リリース日を保存しました。';

  @override
  String get releaseDateCleared => 'リリース日をクリアしました。';

  @override
  String get saveReleaseFilesZip => 'リリースファイルZIPを保存';

  @override
  String get failedToOpenFile => 'ファイルを開けませんでした';

  @override
  String failedToPlayAudio(String error) {
    return 'オーディオの再生に失敗しました: $error';
  }

  @override
  String get renameFile => 'ファイル名を変更';

  @override
  String get selectTracksToAdd => '追加するトラックを選択';

  @override
  String get fileNameUpdated => 'ファイル名を更新しました。';

  @override
  String errorUpdatingFileName(String error) {
    return 'ファイル名の更新エラー: $error';
  }

  @override
  String get deleteFile => 'ファイルを削除';

  @override
  String deleteFileMessage(String fileName) {
    return '「$fileName」を削除してもよろしいですか？';
  }

  @override
  String fileDeleted(String fileName) {
    return 'ファイル「$fileName」を削除しました。';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'ファイルの削除に失敗しました: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'フォルダを開けませんでした: $error';
  }

  @override
  String get artwork => 'アートワーク';

  @override
  String get title => 'タイトル';

  @override
  String get tracks => 'トラック';

  @override
  String get description => '説明';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'リリースに含めるトラックを選択（$count選択済み）';
  }

  @override
  String get searchTracks => 'トラックを検索';

  @override
  String get searchTracksHint => '名前またはDAWタイプで検索';

  @override
  String get noTracksFound => 'トラックが見つかりませんでした';

  @override
  String get unknown => '不明';

  @override
  String get fileNotFound => 'ファイルが見つかりません';

  @override
  String get fileName => 'ファイル名';

  @override
  String get editTodo => 'タスクを編集';

  @override
  String get todoText => 'タスクテキスト';

  @override
  String get enterTodoText => 'タスクテキストを入力';

  @override
  String get addNewTodo => '新しいタスクを追加';

  @override
  String get enterTodoItem => 'タスク項目を入力';

  @override
  String addTodoAtTimestamp(String timestamp) {
    return '$timestampにToDoを追加';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return '$timestampにToDoを追加しました';
  }

  @override
  String get todoList => 'タスクリスト';

  @override
  String get todoTemplates => 'TODOテンプレート';

  @override
  String get createTemplate => 'テンプレート作成';

  @override
  String get editTemplate => 'テンプレート編集';

  @override
  String get deleteTemplate => 'テンプレート削除';

  @override
  String deleteTemplateConfirm(String name) {
    return 'テンプレート「$name」を削除してもよろしいですか？';
  }

  @override
  String get templateName => 'テンプレート名';

  @override
  String get templateNameHint => '例：ミキシングチェックリスト';

  @override
  String get templateItems => 'テンプレート項目';

  @override
  String get templateItemsHint => '1行に1項目';

  @override
  String get templateNameAndItemsRequired => 'テンプレート名と項目が必要です';

  @override
  String get templateItemsRequired => '少なくとも1つの項目が必要です';

  @override
  String get templateCreated => 'テンプレートを作成しました';

  @override
  String get templateUpdated => 'テンプレートを更新しました';

  @override
  String get templateDeleted => 'テンプレートを削除しました';

  @override
  String get noTemplatesYet => 'まだテンプレートがありません';

  @override
  String get createFirstTemplate => '最初のTODOテンプレートを作成';

  @override
  String templateItemCount(int count) {
    return '$count個の項目';
  }

  @override
  String get selectTemplate => 'テンプレート選択';

  @override
  String get importFromTemplate => 'テンプレートからインポート';

  @override
  String get manageTemplates => 'テンプレート管理';

  @override
  String get noTemplatesAvailable => 'テンプレートがありません。最初に作成してください。';

  @override
  String templateImported(String name, int count) {
    return 'テンプレート「$name」をインポート（$count項目）';
  }

  @override
  String get errorLoadingTemplates => 'テンプレート読み込みエラー';

  @override
  String get createProjectStartFrom => 'どのように開始しますか？';

  @override
  String get createProjectStartFromHint => '空のフォルダから開始するか、登録済みテンプレートをコピーします。';

  @override
  String get createProjectEmptyFolder => '空のフォルダ';

  @override
  String get createProjectFromTemplate => 'テンプレートから';

  @override
  String get selectTemplateMainFile => 'テンプレートのメインプロジェクトファイルを選択';

  @override
  String get registerTemplate => 'テンプレートを登録';

  @override
  String get projectTemplates => 'プロジェクトテンプレート';

  @override
  String get searchTemplates => 'テンプレートを検索...';

  @override
  String get createFirstProjectTemplate => '新しいプロジェクトで再利用するテンプレートフォルダを登録します';

  @override
  String get noMatchingTemplates => '一致するテンプレートがありません';

  @override
  String get templateSourceMissing => 'テンプレートの元フォルダが見つかりません';

  @override
  String get useTemplate => '使用';

  @override
  String get selectTemplatesParentFolder => 'テンプレートの親フォルダを選択';

  @override
  String get templateSourceFolder => '元フォルダ';

  @override
  String get dateCreatedColumn => '作成日';

  @override
  String get dateModifiedColumn => '更新日';

  @override
  String get manageTemplateFolders => 'フォルダを管理';

  @override
  String get addTemplateFolder => 'フォルダを追加';

  @override
  String get removeTemplateFolder => 'テンプレートフォルダを削除';

  @override
  String removeTemplateFolderConfirm(String path) {
    return '登録済みのテンプレートフォルダから「$path」を削除しますか？すでにインポート済みのテンプレートは削除されません。';
  }

  @override
  String get noTemplateFoldersRegistered => '登録されたテンプレートフォルダがありません';

  @override
  String get refreshTemplateFolders => '登録フォルダからテンプレートを更新';

  @override
  String lastRefreshed(String date) {
    return '最終更新: $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return '$count件の新しいテンプレートを追加しました';
  }

  @override
  String templatesSelected(int count, String plural) {
    return '$count件のテンプレート$pluralを選択しました';
  }

  @override
  String get deleteSelectedTemplates => '選択項目を削除';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return '$count件のテンプレート$pluralを削除してもよろしいですか?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return '$count件のテンプレート$pluralを削除しました';
  }

  @override
  String get templateDetailTitle => 'Template';

  @override
  String get templateNotFound => 'テンプレートが見つかりません';

  @override
  String get saveAsTemplate => 'テンプレートとして保存';

  @override
  String get newTemplateNameLabel => 'テンプレート名';

  @override
  String get savedAsTemplate => 'テンプレートとして保存しました';

  @override
  String get duplicateTemplate => '複製';

  @override
  String get templateDuplicated => 'テンプレートを複製しました';

  @override
  String get fileInfo => 'ファイル情報';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get filePath => 'パス';

  @override
  String get fileModified => '最終更新';

  @override
  String projectsFromThisTemplate(int count) {
    return 'このテンプレートから作成されたプロジェクト（$count件）';
  }

  @override
  String get noProjectsFromThisTemplate => 'このテンプレートから作成されたプロジェクトはまだありません';

  @override
  String get importTodos => 'ファイルからタスクをインポート';

  @override
  String get noTodosInFile => 'ファイルにタスクが見つかりません';

  @override
  String todosImported(int count) {
    return '$count個のタスクをインポートしました';
  }

  @override
  String errorImportingTodos(String error) {
    return 'インポートエラー: $error';
  }

  @override
  String get addToRelease => 'リリースに追加';

  @override
  String get createNew => '新規作成';

  @override
  String get addToExisting => '既存に追加';

  @override
  String get createAndAdd => '作成して追加';

  @override
  String get selectRelease => 'リリースを選択';

  @override
  String get noExistingReleasesFound => '既存のリリースが見つかりませんでした。';

  @override
  String get addToSelectedRelease => '選択したリリースに追加';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'プロファイル写真の保存に失敗しました: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'プロファイル写真の削除に失敗しました: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'プロファイルの名前変更に失敗しました: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'プロファイルの削除に失敗しました: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'プロファイルの読み込みエラー: $error';
  }

  @override
  String get projectPhaseIdea => 'アイデア';

  @override
  String get projectPhaseArranging => 'アレンジ';

  @override
  String get projectPhaseMixing => 'ミキシング';

  @override
  String get projectPhaseMastering => 'マスタリング';

  @override
  String get projectPhaseFinished => '完了';

  @override
  String get changeStatus => 'フェーズを変更';

  @override
  String get selectNewStatus => '新しいフェーズを選択:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return '$count プロジェクト$pluralのフェーズを「$status」に変更しました';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return '$successCount プロジェクト$successPluralのフェーズを「$status」に変更しましたが、$failCount が失敗$failPluralしました';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'フェーズの変更に失敗しました: $error';
  }

  @override
  String get tooltipEditProfileName => 'プロファイル名を編集';

  @override
  String get tooltipAddTodo => 'タスクを追加';

  @override
  String get tooltipClearDate => '日付をクリア';

  @override
  String get tooltipPickDate => '日付を選択';

  @override
  String get tooltipViewDetails => '詳細を表示';

  @override
  String get tooltipLaunchInDaw => 'DAWで開く';

  @override
  String get tooltipRemoveFromRelease => 'リリースから削除';

  @override
  String get profile => 'プロファイル';

  @override
  String get noDateSet => '日付が設定されていません';

  @override
  String get imageNotFound => '画像が見つかりません';

  @override
  String get clickToBrowseArtwork => 'アートワークを参照するにはクリック';

  @override
  String get dropImageHere => 'ここに画像をドロップ';

  @override
  String get removeArtwork => 'アートワークを削除';

  @override
  String get removeArtworkConfirm => 'このアートワークを削除しますか？画像ファイルが削除されます。';

  @override
  String get noFilesAddedYet =>
      'まだファイルが追加されていません。\n「ファイルを追加」をクリックしてリリースファイルをアップロードしてください。';

  @override
  String get noTodosYet => 'まだタスクがありません。上に追加してください。';

  @override
  String get done => '完了';

  @override
  String get backupAndRestore => 'バックアップと復元';

  @override
  String get backupTabLabel => 'バックアップ';

  @override
  String get aboutTabLabel => 'アプリについて';

  @override
  String get localBackup => 'ローカルバックアップ';

  @override
  String get appearanceTabLabel => '外観';

  @override
  String get exportBackup => 'バックアップをエクスポート';

  @override
  String get importBackup => 'バックアップをインポート';

  @override
  String get exportProjectInfo => '情報をエクスポート';

  @override
  String get exportProjectInfoTooltip => 'このプロジェクトの情報をテキストファイルに保存';

  @override
  String get exportAllProjectsInfo => '全プロジェクトをTXTにエクスポート';

  @override
  String get exportAllProjectsInfoSubtitle =>
      'DAWファイルを削除した後も残るよう、すべてのプロジェクト情報をテキストで保存します';

  @override
  String get projectInfoExported => 'プロジェクト情報をエクスポートしました';

  @override
  String allProjectsInfoExported(int count) {
    return '$count件のプロジェクト情報をエクスポートしました';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return 'プロジェクト情報のエクスポートに失敗しました: $error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return 'エクスポート日時: $dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return '総プロジェクト数: $count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return 'プロジェクト: $name';
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
    return 'ステータス: $status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return 'キー: $key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return 'キー: $key（Camelot $code）';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return 'ファイルパス: $path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return 'ファイルサイズ: $size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return 'ファイル作成日: $date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return 'ライブラリに追加: $date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return '最終更新日: $date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return '締切: $date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return '締切: $date（$status）';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return '総作業時間: $duration';
  }

  @override
  String get projectExportNotesLabel => 'メモ:';

  @override
  String get projectExportTodosLabel => 'ToDo:';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return '作業セッション（$count件）:';
  }

  @override
  String get noProjectsToExport => 'エクスポートするプロジェクトがありません';

  @override
  String get backupExportedSuccessfully => 'バックアップのエクスポートに成功しました';

  @override
  String failedToExportBackup(String error) {
    return 'バックアップのエクスポートに失敗しました: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'バックアップのインポートに成功しました: $projectsCount プロジェクト、$rootsCount プロジェクトフォルダ、$releasesCount リリース';
  }

  @override
  String failedToImportBackup(String error) {
    return 'バックアップのインポートに失敗しました: $error';
  }

  @override
  String get importBackupMessage => 'バックアップのインポート方法を選択してください:';

  @override
  String get mergeWithCurrentProfile => '現在のアクティブなプロフィールとマージ';

  @override
  String get replaceCurrentProfile =>
      '現在のプロフィールを完全に置き換える（警告: これにより現在のプロフィールのすべてのデータが削除されます）';

  @override
  String get createNewProfileForImport => 'このデータ用に新しいプロフィールを作成';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return '新しいプロフィール \"$profileName\" にバックアップをインポートしました: $projectsCount プロジェクト、$rootsCount プロジェクトフォルダ、$releasesCount リリース';
  }

  @override
  String get noProfileSelected => 'プロフィールが選択されていません';

  @override
  String get exportBackupDialogTitle => 'バックアップをエクスポート';

  @override
  String get importBackupDialogTitle => 'バックアップをインポート';

  @override
  String get invalidBackupFileFormat => '無効なバックアップファイル形式: バージョンがありません';

  @override
  String get profileNameRequiredForNewProfile =>
      '新しいプロフィールを作成する際は、プロフィール名が必要です';

  @override
  String get currentProfileRequired => 'マージまたは置き換えモードには現在のプロフィールが必要です';

  @override
  String get previewSong => 'プレビュー曲';

  @override
  String get noPreviewSongTitle => 'プレビュー曲なし';

  @override
  String get noPreviewSongMessage =>
      'このプロジェクトにはプレビュー曲が設定されていません。オーディオファイルを選択して読み込み、再生してください。';

  @override
  String get noPreviewSongDragHint =>
      'テーブルのプロジェクト行にオーディオファイルを直接ドラッグ＆ドロップすることもできます。';

  @override
  String get previewSongRemoved => 'プレビュー曲が削除されました';

  @override
  String get previewSongAdded => 'プレビュー曲が追加されました';

  @override
  String get previewSongFileNotFound => 'プレビュー曲のファイルが見つかりません';

  @override
  String get previewSongFileNotFoundMessage =>
      'プレビュー曲のファイルがディスク上に見つかりませんでした。新しいファイルを選択するか、エントリを削除しますか？';

  @override
  String get selectNewFile => '新しいファイルを選択';

  @override
  String failedToPlayPreview(String error) {
    return 'プレビューの再生に失敗しました: $error';
  }

  @override
  String get removePreviewSong => 'プレビュー曲を削除';

  @override
  String get removePreviewSongConfirm => 'プレビュー曲を削除してもよろしいですか？この操作は元に戻せません。';

  @override
  String get noPreviewSongSelected => 'プレビュー曲が選択されていません';

  @override
  String get changePreviewSong => 'プレビュー曲を変更';

  @override
  String get selectPreviewSong => 'プレビュー曲を選択';

  @override
  String get dropAudioFileHere => 'オーディオファイルをここにドロップ';

  @override
  String projectAge(String age) {
    return 'プロジェクト経過時間: $age';
  }

  @override
  String createdDate(String date) {
    return '$dateに作成';
  }

  @override
  String completedIn(String duration) {
    return '完成までの期間: $duration';
  }

  @override
  String finishedDate(String date) {
    return '$dateに完成';
  }

  @override
  String get dateToday => '今日';

  @override
  String get dateYesterday => '昨日';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日前',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count週間前',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countヶ月前',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count年前',
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
    return '$years年$monthsヶ月';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years年';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$monthsヶ月$days日';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$monthsヶ月';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days日';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours時間';
  }

  @override
  String get ageJustNow => 'たった今';

  @override
  String get ageLessThanHour => '1時間未満';

  @override
  String get viewProfile => 'プロフィールを表示';

  @override
  String get googleDriveSync => 'Google Drive同期';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Google Driveとデータを同期して、デバイス間でバックアップと復元を行います。';

  @override
  String get manageGoogleDriveSync => 'Google Drive同期を管理';

  @override
  String get signInToGoogleDrive => 'Google Driveにサインイン';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get uploadBackup => 'バックアップをアップロード';

  @override
  String get downloadBackup => 'バックアップをダウンロード';

  @override
  String get newerBackupAvailable => 'クラウドに新しいバックアップが利用可能';

  @override
  String get restoreProjectFromDrive => 'Driveから復元';

  @override
  String get restoringProjectFromDrive => 'Driveから復元中...';

  @override
  String get projectRestoredFromDrive => 'プロジェクトをDriveから復元しました';

  @override
  String get projectNotFoundInBackup => 'このプロジェクトはDriveのバックアップに見つかりませんでした';

  @override
  String get signInToGoogleDriveFirst =>
      'まずGoogle Driveにサインインしてください（Drive Sync設定を開く）';

  @override
  String get signOut => 'サインアウト';

  @override
  String get downloadPreviewSongs => 'プレビュー曲をダウンロード';

  @override
  String get downloadPreviewSongsExplanation =>
      'チェックを外すと、プレビュー曲はスキップされます（時間とストレージを節約）。必要に応じて後でダウンロードできます。';

  @override
  String get replaceLocalData => 'ローカルデータを置き換え';

  @override
  String get downloadBackupConfirmation =>
      'これにより、ローカルデータがGoogle Driveのバックアップに置き換えられます。\n\n続行してもよろしいですか？';

  @override
  String get enterAuthorizationCode => '認証コードを入力';

  @override
  String get authorizationCode => '認証コード';

  @override
  String get pasteCodeFromBrowser => 'ブラウザからコードを貼り付け';

  @override
  String get sessionActive => 'セッション有効';

  @override
  String get signedIn => 'サインイン済み';

  @override
  String get creatingInitialBackup => '初期バックアップを作成中...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Google Driveに正常にサインインし、バックアップしました';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Google Driveに正常にサインインし、バックアップしました！';

  @override
  String get successfullySignedInToGoogleDrive => 'Google Driveに正常にサインインしました';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Google Driveに正常にサインインしました！';

  @override
  String get signInCancelledOrFailed =>
      'サインインがキャンセルされたか失敗しました。詳細はコンソールを確認してください。';

  @override
  String get failedToLaunchBrowser => 'ブラウザの起動に失敗しました';

  @override
  String get signInCancelled => 'サインインがキャンセルされました';

  @override
  String get failedToExchangeAuthorizationCode => '認証コードの交換に失敗しました';

  @override
  String errorSigningIn(String error) {
    return 'サインインエラー: $error';
  }

  @override
  String get unknownError => '不明なエラー';

  @override
  String get googleSignInError => 'Googleサインインエラー';

  @override
  String get developerConsoleNotSetUp =>
      '開発者コンソールが正しく設定されていません。Google Cloud ConsoleでOAuth設定を確認してください。';

  @override
  String get platformError => 'プラットフォームエラー';

  @override
  String get signedOutFromGoogleDrive => 'Google Driveからサインアウトしました';

  @override
  String errorSigningOut(String error) {
    return 'サインアウトエラー: $error';
  }

  @override
  String get syncing => '同期中...';

  @override
  String get errorNoProfileSelected => 'エラー: プロフィールが選択されていません';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '同期完了！プロジェクト: +$projectsAdded ~$projectsUpdated、リリース: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return '同期エラー: $error';
  }

  @override
  String get uploadingBackup => 'バックアップをアップロード中...';

  @override
  String get backupUploadedSuccessfully => 'バックアップが正常にアップロードされました！';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Google Driveにバックアップが正常にアップロードされました！';

  @override
  String errorUploadingBackup(String error) {
    return 'バックアップのアップロードエラー: $error';
  }

  @override
  String get downloadingBackup => 'バックアップをダウンロード中...';

  @override
  String get checkingForBackup => 'バックアップを確認中...';

  @override
  String get backupUpToDate => 'バックアップは最新です';

  @override
  String errorCheckingBackup(String error) {
    return 'バックアップの確認エラー: $error';
  }

  @override
  String get download => 'ダウンロード';

  @override
  String get remoteBackupIsNewer =>
      'リモートバックアップはローカルデータより新しいです。アップロードすると上書きされます。';

  @override
  String get confirmUpload => 'アップロードを確認';

  @override
  String get noBackupFileFound =>
      'Google Driveにバックアップファイルが見つかりません。データを同期して最初にバックアップを作成してください。';

  @override
  String get noBackupFileFoundStatus =>
      'バックアップファイルが見つかりません。最初にバックアップを作成してください。';

  @override
  String get downloadCancelled => 'ダウンロードがキャンセルされました';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'バックアップをダウンロードしました！プロジェクト: +$projectsAdded ~$projectsUpdated、リリース: +$releasesAdded ~$releasesUpdated';
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
    return 'バックアップがダウンロードされました!\n\nプロジェクト:\n  • $projectsAdded 追加\n  • $projectsUpdated 更新\n\nリリース:\n  • $releasesAdded 追加\n  • $releasesUpdated 更新\n\nプレビュー曲:\n  • $previewSongsDownloaded ダウンロード\n  • $previewSongsUpdated 更新';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'バックアップのダウンロードエラー: $error';
  }

  @override
  String get notSignedInYet => 'サインインしていません';

  @override
  String get never => 'なし';

  @override
  String signedInAs(String email) {
    return 'サインイン: $email';
  }

  @override
  String lastSync(String date) {
    return '最終同期: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'リモートバックアップ: $date';
  }

  @override
  String lastUploadTime(String date) {
    return '最後のアップロード: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return '最後のダウンロード: $date';
  }

  @override
  String get checkForBackup => 'バックアップを確認';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get notificationsOnlyOnAndroid => '期限通知はAndroidデバイスでのみ利用可能です。';

  @override
  String get notificationPermissionRequired => '通知の許可が必要です';

  @override
  String get notificationPermissionDescription =>
      '期限のリマインダーを受け取るには、通知を有効にしてください。';

  @override
  String get notificationPermissionDenied => '通知の許可が拒否されました。設定で有効にしてください。';

  @override
  String get notificationSettingsSaved => '通知設定を正常に保存しました';

  @override
  String get errorSavingSettings => '設定の保存エラー';

  @override
  String get enableDeadlineNotifications => '期限通知を有効にする';

  @override
  String get receiveRemindersForDeadlines => 'プロジェクトの期限のリマインダーを受け取る';

  @override
  String get notificationTime => '通知時刻';

  @override
  String get timeToReceiveNotifications => '通知を受け取る時刻';

  @override
  String get reminderDays => 'リマインダー日数';

  @override
  String get selectDaysBeforeDeadline => '期限の何日前に通知を受け取るか選択してください';

  @override
  String get notifyOnDeadlineDay => '期限当日に通知';

  @override
  String get receiveNotificationOnDeadlineDay => '期限当日にも通知を受け取る';

  @override
  String get howItWorks => '使い方';

  @override
  String get deadlineNotificationsHelp =>
      '各プロジェクトの期限の前に選択した日数で、指定された時刻に通知を受け取ります。通知をタップするとプロジェクトの詳細が開きます。';

  @override
  String get oneDay => '1日';

  @override
  String xDays(int count) {
    return '$count日';
  }

  @override
  String get settings => '設定';

  @override
  String get searchSettings => '設定を検索';

  @override
  String noSettingsFoundFor(String query) {
    return '「$query」に一致する設定は見つかりませんでした';
  }

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get languageSettingDescription => 'アプリ全体で使用される言語です。';

  @override
  String get themeSettingDescription => 'アプリのカラーテーマです。';

  @override
  String get waveformStyle => '波形スタイル';

  @override
  String get waveformStyleSettingDescription => 'オーディオプレビューの波形の描画方法。';

  @override
  String get waveformStyleDetailed => '詳細';

  @override
  String get waveformStyleDetailedDescription => 'DAW のようなピクセル単位のバーと陰影のある本体。';

  @override
  String get waveformStyleClassic => 'クラシック';

  @override
  String get waveformStyleClassicDescription => '塗りつぶしの輪郭のみ。';

  @override
  String get waveformChannels => 'チャンネル';

  @override
  String get waveformChannelsSettingDescription => '波形でステレオを 2 段に分けて表示するかどうか。';

  @override
  String get waveformChannelsSingle => 'シングル';

  @override
  String get waveformChannelsDual => 'デュアル';

  @override
  String get waveformChannelsSingleDescription => 'ステレオをミックスした 1 段表示。';

  @override
  String get waveformChannelsDualDescription => '左右を別々の段に分けて表示。';

  @override
  String get waveformChannelsUnavailable => 'このファイルは 1 チャンネルのみです';

  @override
  String get support => 'サポート';

  @override
  String get shareDiagnosticLog => '診断ログを共有';

  @override
  String get shareDiagnosticLogEmpty => '診断ログはまだありません';

  @override
  String get shareDiagnosticLogFolderOpened =>
      'この環境では共有を利用できません。代わりにログフォルダーを開いたので、ファイルを手動で添付してください。';

  @override
  String get enableDiagnosticLogging => '診断ログを有効にする';

  @override
  String get enableDiagnosticLoggingDescription =>
      'このデバイス上にクラッシュやエラーの小さなログを保持し、問題が発生した場合に共有できるようにします。デフォルトではオフです。';

  @override
  String get clearDiagnosticLog => '診断ログを消去';

  @override
  String get clearDiagnosticLogConfirmTitle => '診断ログを消去しますか？';

  @override
  String get clearDiagnosticLogConfirmMessage =>
      '診断ログファイルは完全に削除されます。この操作は元に戻せません。';

  @override
  String get diagnosticLogCleared => '診断ログを消去しました';

  @override
  String get supportTheProject => 'プロジェクトをサポート';

  @override
  String couldNotOpenBrowser(String url) {
    return 'ブラウザを開けませんでした。次のURLにアクセスしてください: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'ブラウザを開く際にエラーが発生しました: $error';
  }

  @override
  String get generateTestingDatabase => 'テストデータベースを生成';

  @override
  String get generateTestingDatabaseMessage =>
      'これにより、対応するすべてのDAWにわたる多様なサンプルプロジェクト、リリース、プレイリストが含まれた専用の「Demo — Screenshots」プロファイルが作成（または更新）され、そのプロファイルに切り替わります。他のプロファイルは変更されません。続行しますか？';

  @override
  String get testingDatabaseGenerated => 'デモプロファイルの準備ができました — 切り替えました！';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'テストデータベースの生成に失敗しました: $error';
  }

  @override
  String get removeTestingDatabase => 'テストデータベースを削除';

  @override
  String get removeTestingDatabaseMessage =>
      '「Demo — Screenshots」プロファイルと、そのすべてのサンプルプロジェクト、リリース、プレイリスト、プレビュー音声ファイルが完全に削除されます。続行しますか？';

  @override
  String get testingDatabaseRemoved => 'デモデータを削除しました。';

  @override
  String get noTestingDatabaseFound => '削除するデモデータが見つかりませんでした。';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return 'テストデータベースの削除に失敗しました: $error';
  }

  @override
  String get playlists => 'プレイリスト';

  @override
  String get playlistsDesktopOnly => 'プレイリストはAndroidでのみ利用可能です。';

  @override
  String get noPlaylistsYet => 'まだプレイリストがありません';

  @override
  String get createFirstPlaylist => '+ボタンをタップして最初のプレイリストを作成';

  @override
  String playlistSongCount(int count) {
    return '$count曲';
  }

  @override
  String get createPlaylist => 'プレイリスト作成';

  @override
  String get playlistName => 'プレイリスト名';

  @override
  String get playlistNameHint => 'マイプレイリスト';

  @override
  String get playlistNameRequired => 'プレイリスト名が必要です';

  @override
  String get editPlaylist => 'プレイリスト編集';

  @override
  String get stopPlaybackBeforeEditing => 'プレイリストを編集する前に再生を停止してください';

  @override
  String get selectPreviewSongs => 'プレビュー曲を選択';

  @override
  String get deletePlaylist => 'プレイリスト削除';

  @override
  String deletePlaylistConfirm(String name) {
    return '本当に「$name」を削除しますか？';
  }

  @override
  String get playlistDeleted => 'プレイリストを削除しました';

  @override
  String get errorDeletingPlaylist => 'プレイリスト削除エラー';

  @override
  String get playlistUpdated => 'プレイリストを更新しました';

  @override
  String get changeSong => '曲を変更';

  @override
  String get changeSongConfirm => '現在曲が再生中です。この曲に切り替えますか？';

  @override
  String get changeSongButton => '変更';

  @override
  String playlistProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get noPreviewSongsInPlaylist => 'このプレイリストに利用可能なプレビュー曲がありません';

  @override
  String get tapEditToAddSongs => '編集をタップして、このプレイリストに曲を追加してください';

  @override
  String get noProjectsAvailableForPlaylist => '追加できるプレビュー曲を持つプロジェクトがありません';

  @override
  String get noProjectsInDatabase => 'データベースにプロジェクトが見つかりません。まずプロジェクトを同期してください。';

  @override
  String get firstTimeSyncTitle => '初めてのご利用のようですね！';

  @override
  String get firstTimeSyncMessage => 'Google Driveからデータを同期して始めましょう';

  @override
  String get syncWithGoogleDrive => 'Google Driveと同期';

  @override
  String get errorLoadingPlaylists => 'プレイリスト読み込みエラー';

  @override
  String get playlistItems => 'プレイリスト項目';

  @override
  String get addSongs => '曲を追加';

  @override
  String get addAudioFiles => 'オーディオファイルを追加';

  @override
  String get selectAudioFiles => 'オーディオファイルを選択';

  @override
  String get selectFromProjects => 'プロジェクトから選択';

  @override
  String get add => '追加';

  @override
  String get addTaskAtTimestamp => '現在の再生位置にタスクを追加';

  @override
  String get taskDescriptionHint => 'タスクの説明';

  @override
  String get taskAdded => 'タスクを追加しました';

  @override
  String get fromProject => 'プロジェクトから';

  @override
  String get projectDeadline => 'プロジェクトの期限';

  @override
  String get noDeadlineSet => '期限未設定';

  @override
  String get camelotCode => 'キャメロットコード';

  @override
  String get deadline => '期限';

  @override
  String get dueToday => '今日期限';

  @override
  String daysLate(int days) {
    return '$days日遅延';
  }

  @override
  String daysLeft(int days) {
    return '残り$days日';
  }

  @override
  String get hideFinished => '完了を非表示';

  @override
  String get showOnlyDeadlines => '期限を表示';

  @override
  String get filterByDeadline => '期限でフィルタ';

  @override
  String get allDeadlines => 'すべての期限';

  @override
  String get hasDeadline => '期限あり';

  @override
  String get overdue => '期限超過';

  @override
  String get dueSoon => 'もうすぐ期限 (7日)';

  @override
  String get today => '今日';

  @override
  String get noPreviewSong => 'プレビューなし';

  @override
  String get playPreview => 'プレビュー再生';

  @override
  String get uploadCancelled => 'アップロードがキャンセルされました';

  @override
  String get backupUploadCancelledByUser => 'ユーザーによってバックアップのアップロードがキャンセルされました';

  @override
  String get collectingData => 'データを収集中...';

  @override
  String get uploadingPreviewSongs => 'プレビュー曲をアップロード中...';

  @override
  String get uploadingProfilePhotos => 'プロフィール写真をアップロード中...';

  @override
  String get uploadingReleaseArtwork => 'リリースアートワークをアップロード中...';

  @override
  String get uploadingDatabase => 'データベースをアップロード中...';

  @override
  String get completed => '完了！';

  @override
  String get cancelling => 'キャンセル中...';

  @override
  String get uploadingBackupTitle => 'バックアップをアップロード中';

  @override
  String get cancellingUpload => 'アップロードをキャンセル中...';

  @override
  String get pleaseWaitCancellingUpload => 'アップロードを停止していますのでお待ちください...';

  @override
  String get downloadingDatabase => 'データベースをダウンロード中...';

  @override
  String get downloadingPreviewSongs => 'プレビュー曲をダウンロード中...';

  @override
  String get downloadingProfilePhotos => 'プロフィール写真をダウンロード中...';

  @override
  String get downloadingReleaseArtwork => 'リリースアートワークをダウンロード中...';

  @override
  String get mergingData => 'データを統合中...';

  @override
  String get downloadingBackupTitle => 'バックアップをダウンロード中';

  @override
  String get sourceFileNotFoundOnThisMachine => 'このマシンにソースファイルが見つかりません';

  @override
  String get metadataExtractionNotSupportedForDaw =>
      'このDAWではメタデータの抽出はサポートされていません';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'このマシンにソースファイルが見つかりません — メタデータのみモード。メタデータの編集とエクスポートは引き続き可能です。';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'プレビュー曲が利用できません。先にバックアップをダウンロードしてください。';

  @override
  String get sharePreviewSong => 'プレビュー曲を共有';

  @override
  String get shareAsZip => 'ZIPとして共有';

  @override
  String get share => '共有';

  @override
  String get convertingAudioForSharing => '共有用にオーディオを準備しています…';

  @override
  String get shareSheetUnavailable =>
      'システムの共有メニューはここでは利用できません。代わりに、曲のプレビューにある「ドラッグして共有」チップでファイルを他のアプリへドラッグしてください。';

  @override
  String get dragToShare => 'ドラッグして共有';

  @override
  String get dragToShareTooltip =>
      'これを他のアプリ（WhatsAppなど）のウィンドウにドラッグすると、ファイルを直接共有できます。共有ボタンで共有メニューが開かない場合に便利です。';

  @override
  String get mp3ConversionFailed =>
      'このシステムではオーディオ変換を利用できません。元のファイルを共有しますが、WhatsAppなど一部のアプリでは拒否される場合があります。';

  @override
  String get shareZip => 'ZIPを共有';

  @override
  String get saveCopy => 'コピーを保存';

  @override
  String savedCopyTo(String path) {
    return '$path に保存しました';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'プレビュー曲を共有できませんでした: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'プレビュー曲をZIPとして共有できませんでした: $error';
  }

  @override
  String get biographySaved => 'プロフィールが保存されました';

  @override
  String failedToSaveBiography(String error) {
    return 'プロフィールを保存できませんでした: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'ファイルを $filename に保存しました';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'ファイルをダウンロードできませんでした: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'すべてのファイルを $filename に保存しました';
  }

  @override
  String get artworkAdded => 'アートワークを追加しました';

  @override
  String failedToAddArtwork(String error) {
    return 'アートワークを追加できませんでした: $error';
  }

  @override
  String get artworkRemoved => 'アートワークを削除しました';

  @override
  String failedToRemoveArtwork(String error) {
    return 'アートワークを削除できませんでした: $error';
  }

  @override
  String get pressKitFileAdded => 'プレスキットファイルを追加しました';

  @override
  String failedToAddPressKitFile(String error) {
    return 'プレスキットファイルを追加できませんでした: $error';
  }

  @override
  String get pressKitFileRemoved => 'プレスキットファイルを削除しました';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'プレスキットファイルを削除できませんでした: $error';
  }

  @override
  String get selectFilesToDownload => 'ダウンロードするファイルを選択';

  @override
  String get biography => 'プロフィール';

  @override
  String get biographyWillBeSaved => 'biography.txt として保存されます';

  @override
  String get artworkFiles => 'アートワークファイル';

  @override
  String get pressKitFiles => 'プレスキットファイル';

  @override
  String get additionalAssets => '追加アセット';

  @override
  String downloadNFiles(int count, String plural) {
    return '$count個のファイル$pluralをダウンロード';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count個のファイル$pluralを $filename に保存しました';
  }

  @override
  String get addAsset => 'アセットを追加';

  @override
  String get assetNameLabel => 'アセット名';

  @override
  String get assetNameHint => '例：ロゴ、バナー、写真';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName を正常に追加しました';
  }

  @override
  String failedToAddAsset(String error) {
    return 'アセットを追加できませんでした: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName を削除しました';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'アセットを削除できませんでした: $error';
  }

  @override
  String get profileNotFound => 'プロフィールが見つかりません';

  @override
  String get downloadFilesSectionTitle => 'ファイルをダウンロード';

  @override
  String get downloadFilesSectionDescription =>
      'このプロフィールのすべてのファイル（プロフィール文、アートワーク、プレスキット、追加アセット）を1つのZIPとしてダウンロードするか、含めるものを選択できます。';

  @override
  String get selectFiles => 'ファイルを選択';

  @override
  String get downloadAll => 'すべてダウンロード';

  @override
  String get saveBiographyTooltip => 'プロフィールを保存';

  @override
  String get enterBiographyHint => 'プロフィールの経歴を入力...';

  @override
  String get addArtwork => 'アートワークを追加';

  @override
  String get addFile => 'ファイルを追加';

  @override
  String get openFile => 'ファイルを開く';

  @override
  String get menuView => '表示';

  @override
  String get menuAbout => 'DAW Project Manager について';

  @override
  String get menuDocumentation => 'ドキュメント';

  @override
  String get menuLanguage => '言語';

  @override
  String get menuWarnBeforeQuit => '終了前に警告する (⌘+Q)';

  @override
  String get menuQuit => 'DAW Project Manager を終了';

  @override
  String get quitConfirmTitle => 'DAW Project Manager を終了しますか？';

  @override
  String get quitConfirmMessage => '本当に終了しますか？';

  @override
  String get quit => '終了';

  @override
  String get trayNoticeTitle => 'バックグラウンドで実行中です';

  @override
  String get trayNoticeBody =>
      'DAW Project Manager はシステムトレイに最小化されました。トレイアイコンから再表示または終了できます。';

  @override
  String get trayShowWindow => 'DAW Project Manager を表示';

  @override
  String trayLastBackup(String when) {
    return '最終バックアップ: $when';
  }

  @override
  String get trayNeverBackedUp => 'バックアップはまだありません';

  @override
  String get trayBackupNow => '今すぐバックアップ';

  @override
  String get trayPauseSession => 'セッションを一時停止';

  @override
  String get trayResumeSession => 'セッションを再開';

  @override
  String get closeToTray => 'トレイに閉じる';

  @override
  String get closeToTrayDescription =>
      'ウィンドウを閉じてもバックグラウンドで実行を継続し(トレイアイコン)、自動バックアップと通知が引き続き機能するようにします';

  @override
  String get autoStart => '起動時に自動で開く';

  @override
  String get autoStartDescription =>
      'コンピューターにサインインしたときに DAW Project Manager を自動的に開きます';

  @override
  String get startMinimized => 'トレイに最小化した状態で起動';

  @override
  String get startMinimizedDescription =>
      'コンピューターと一緒に起動するとき、ウィンドウを表示せずトレイに隠した状態で開きます';

  @override
  String get onboardingStartMinimized => '最小化して起動';

  @override
  String get autoStartFailed => '起動設定を変更できませんでした。お使いのシステムで許可されていない可能性があります。';

  @override
  String get onboardingStartupTitle => '起動時に自動で開く';

  @override
  String get onboardingStartupBody =>
      'サインイン時に DAW Project Manager を自動的に開き、バックグラウンドのバックアップと期限のリマインダーを継続します。';

  @override
  String get menuWindow => 'ウィンドウ';

  @override
  String get donate => '寄付';

  @override
  String get website => 'ウェブサイト';

  @override
  String get license => 'ライセンス';

  @override
  String get reportIssue => '問題を報告';

  @override
  String get switchToClassicDark => 'Classic Dark に切り替え';

  @override
  String get switchToNeonDark => 'Neon Dark に切り替え';

  @override
  String get switchToClassicTheme => 'Classic テーマに切り替え';

  @override
  String get switchToNeonTheme => 'Neon テーマに切り替え';

  @override
  String get switchToStudioLight => 'Studio Light に切り替え';

  @override
  String get menuTheme => 'テーマ';

  @override
  String get appDescription => '音楽プロデューサーとサウンドデザイナーのためのプロジェクト管理ツール。';

  @override
  String get neonDarkThemeName => 'ネオンダーク';

  @override
  String get classicDarkThemeName => 'クラシックダーク';

  @override
  String get studioLightThemeName => 'スタジオライト';

  @override
  String get statisticsTab => '統計';

  @override
  String get statsTotalProjects => '総プロジェクト数';

  @override
  String get statsInProgress => '進行中';

  @override
  String get statsFinished => '完成';

  @override
  String get statsAvgCompletion => '平均完成時間';

  @override
  String get statsPhaseDistribution => 'フェーズ別プロジェクト';

  @override
  String get statsAvgTimePerPhase => 'フェーズあたりの平均日数';

  @override
  String get statsProductivity => '生産性';

  @override
  String get statsCreatedSeries => '作成';

  @override
  String get statsProjectHealth => 'プロジェクトの年齢と健全性';

  @override
  String get statsCatalogInsights => 'カタログの洞察';

  @override
  String get statsBpmDistribution => 'BPM分布';

  @override
  String get statsTopKeys => '主な音楽キー';

  @override
  String get statsDawTypes => 'DAWの種類';

  @override
  String get statsProjectActivity => 'プロジェクトのアクティビティ';

  @override
  String get statsSingleProjectActivity => 'プロジェクトのアクティビティ';

  @override
  String get statsNoData => 'データなし';

  @override
  String get statsNoPhaseData => 'フェーズ移行後にデータが表示されます。';

  @override
  String statsLastActivityDaysAgo(int days) {
    return '最終活動: $days日前';
  }

  @override
  String get statsLastActivityToday => '今日アクティブ';

  @override
  String get statsNoEvents => 'まだイベントなし';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'フェーズ: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return '更新: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return '完了: $text';
  }

  @override
  String get statsEventFileModified => 'ディスク上のファイルが変更されました';

  @override
  String get statsClearHistory => '履歴をクリア';

  @override
  String get statsClearHistoryConfirm => 'このプロジェクトのすべてのイベントをクリアしますか？';

  @override
  String get statsSearchProjects => 'プロジェクトを検索…';

  @override
  String statsEventCount(int count) {
    return '$count件のイベント';
  }

  @override
  String get statsViewHistory => 'プロジェクト統計';

  @override
  String get statsPhaseHistory => 'フェーズ履歴';

  @override
  String get statsEventBreakdown => 'イベント内訳';

  @override
  String statsDaysSoFar(int days) {
    return '現在$days日';
  }

  @override
  String get statsNoProjectsFound => 'プロジェクトが見つかりません';

  @override
  String statsNotTouchedDays(int days) {
    return '$days日間変更なし';
  }

  @override
  String get sortByLastModified => '最終更新';

  @override
  String get sortByName => '名前';

  @override
  String get sortByPhase => 'フェーズ';

  @override
  String get sortByCreatedAt => '追加日';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => '新しい順';

  @override
  String get sortOldestFirst => '古い順';

  @override
  String get sortTitleAZ => 'タイトル A–Z';

  @override
  String get sortTitleZA => 'タイトル Z–A';

  @override
  String get musicPlayerTab => '音楽プレーヤー';

  @override
  String get previewAudioChangedRefreshing => 'プレビュー音声がディスク上で変更されました — 波形を更新中…';

  @override
  String get audioFileChangedRefreshing => '音声ファイルがディスク上で変更されました — 波形を更新中…';

  @override
  String get autoFitAllColumns => '列を自動調整';

  @override
  String get uploadAutoDetectedPreviewSongs => '自動検出されたプレビュー曲をアップロード';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      '手動で設定した曲だけでなく、スキャナーが自動的に見つけた曲も含めます。';

  @override
  String get monoGenerating => 'モノラル…';

  @override
  String errorHandlingDroppedFiles(String error) {
    return 'ドロップされたファイルの処理エラー: $error';
  }

  @override
  String get resetOnboardingConfirm => 'セットアップウィザードが再起動されます。続行しますか？';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return '$daw を起動できませんでした: $error';
  }

  @override
  String get couldNotOpenLink => 'リンクを開けませんでした。';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => 'モノ';

  @override
  String get monoToggleTooltip => 'モノラル再生を切り替え';

  @override
  String get monoRequiresWav => 'モノラルミックスにはWAVファイルが必要です';

  @override
  String get monoUnsupportedFormat => 'モノラルミックスを作成できません — サポートされていない形式';

  @override
  String monoSwitchFailed(String error) {
    return 'モノラル切り替えに失敗しました: $error';
  }

  @override
  String get analyzeLabel => '分析';

  @override
  String get reAnalyzeLabel => '再分析';

  @override
  String get analysisRequiresWav => '分析にはWAVファイルが必要です';

  @override
  String get noResultsForFilter => '現在のフィルターに一致する結果がありません';

  @override
  String get noResultsForFilterHint => '検索条件やフィルターを調整してみてください。';

  @override
  String get noProjectsFound => 'プロジェクトが見つかりません';

  @override
  String get noProjectsFoundHint => '設定でルートフォルダを追加してください。';

  @override
  String get noProjectsFoundInFoldersHint => 'DAWプロジェクトが含まれる別のフォルダを追加してみてください。';

  @override
  String get queueTab => 'タスク';

  @override
  String get queueSearchHint => 'タスクを検索...';

  @override
  String get queueNoPendingTasks => '全部完了！';

  @override
  String get queueNoPendingTasksHint => 'プロジェクトに未完了のタスクはありません。';

  @override
  String get queueNoMatchingTasks => '一致するタスクが見つかりません';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$projects個のプロジェクトに$tasks件の未完了タスク';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager $version';
  }

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String get renameProjectFileTitle => 'プロジェクトファイルの名前変更';

  @override
  String get renameFileButtonLabel => 'ファイルを名前変更';

  @override
  String get newFileNameLabel => '新しいファイル名（拡張子なし）';

  @override
  String renameAlreadyExists(String name) {
    return '「$name」という名前のファイルが既に存在します。';
  }

  @override
  String renameSuccess(String name) {
    return '「$name」に名前を変更しました';
  }

  @override
  String renameFailed(String error) {
    return '名前の変更に失敗しました: $error';
  }

  @override
  String get nameCannotBeEmpty => '名前を空にすることはできません';

  @override
  String get nameInvalidCharacters => '名前に / \\ : を含めることはできません';

  @override
  String get alsoRenameContainingFolder => '含まれるフォルダも名前変更する';

  @override
  String get renameButton => '名前変更';

  @override
  String get previewMixdownFolderTitle => 'プレビューミックスダウンフォルダ';

  @override
  String get previewMixdownFolderSubtitle =>
      'プレビュー曲の自動検出時に、順番に最初に確認する各プロジェクトフォルダ内のサブフォルダ名。空にするとDAWのデフォルトを使用します。';

  @override
  String get previewMixdownFolderHint => '例：Mixdowns';

  @override
  String get mixdownFoldersInfoTooltip => '仕組みを見る';

  @override
  String get mixdownFoldersInfoDialogTitle => 'プレビュー検出の仕組み';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'プロジェクトに手動で選択したプレビュー曲がない場合、アプリは最も最近更新されたオーディオファイルをプレビューとして探します。まず以下のカスタムフォルダを順番に確認し、その後プロジェクトのDAWに基づくデフォルトフォルダ名のリストにフォールバックします。';

  @override
  String get mixdownFoldersDawDefaultsHeading => 'DAWごとのデフォルトフォルダ';

  @override
  String get mixdownFoldersOtherDawLabel => 'その他 / 不明なDAW';

  @override
  String get addMixdownFolder => '追加';

  @override
  String get noCustomMixdownFolders => 'カスタムフォルダが追加されていません — DAWのデフォルトが使用されます。';

  @override
  String get mixdownFoldersTabLabel => 'ミックスダウンフォルダ';

  @override
  String get mixdownFoldersSectionDescription =>
      '手動でプレビュー曲が設定されていない場合に、プロジェクトのエクスポート/バウンス済み音声を探すフォルダを制御します。以下のDAWを展開すると、デフォルトで確認されるフォルダ名が表示されます。異なる名前を使用している場合は、独自のフォルダ名を追加できます。';

  @override
  String get mixdownFoldersDefaultsLabel => 'デフォルトで確認されるフォルダ:';

  @override
  String get mixdownFoldersCustomLabel => 'このDAW用に追加したフォルダ:';

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
    return 'キー: $key';
  }

  @override
  String get audioFileNotFound => 'オーディオファイルが見つかりません';

  @override
  String errorPlayingAudio(String error) {
    return 'オーディオ再生エラー: $error';
  }

  @override
  String get notificationTestTitle => 'タイムゾーンとスケジュールを確認するための通知テスト:';

  @override
  String get notificationSendNow => '今すぐ送信';

  @override
  String get notificationSchedule30s => '+30秒後にスケジュール';

  @override
  String get notificationShowDebugInfo => 'デバッグ情報を表示';

  @override
  String get notificationRescheduleAll => 'すべて再スケジュール';

  @override
  String get notificationTestSent => '✅ テスト通知を送信しました！';

  @override
  String get notificationTestScheduled =>
      '✅ テスト通知をス30秒後にスケジュールしました！コンソールログを確認してください。';

  @override
  String notificationTestError(String error) {
    return '❌ エラー: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 デバッグ情報';

  @override
  String get autoDetected => '自動検出';

  @override
  String get matchedInDescription => '説明文でマッチ';

  @override
  String get matchedInProjectNotes => 'DAWプロジェクトノートでマッチ';

  @override
  String get relocateFolderDialogTitle => 'フォルダを移動';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプロジェクトパスを更新しました',
      one: '1件のプロジェクトパスを更新しました',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'タブのカスタマイズ';

  @override
  String get alwaysVisible => '（常に表示）';

  @override
  String get customizeTabsDescription =>
      'ナビゲーションバーに表示するタブを選択します。プロジェクトタブは常に表示されます。';

  @override
  String get keyboardShortcuts => 'キーボードショートカット';

  @override
  String get shortcutGroupGlobal => 'グローバル';

  @override
  String get shortcutGroupProjectsTable => 'プロジェクトテーブル（テーブルがフォーカスされている必要があります）';

  @override
  String get shortcutGroupReleasesTable => 'リリーステーブル（テーブルがフォーカスされている必要があります）';

  @override
  String get shortcutGroupNavigation => 'ナビゲーション';

  @override
  String get shortcutFocusSearch => '検索バーにフォーカス';

  @override
  String get shortcutRescan => 'プロジェクトフォルダを再スキャン';

  @override
  String get shortcutFocusTable => 'プロジェクトテーブルにフォーカス';

  @override
  String get shortcutPlayPause => 'プレビュー曲を再生／一時停止';

  @override
  String get shortcutOpenInDaw => 'DAWでプロジェクトを開く';

  @override
  String get shortcutViewDetails => 'プロジェクトの詳細を表示';

  @override
  String get shortcutOpenFolder => 'プロジェクトフォルダを開く';

  @override
  String get shortcutNavigateRows => '行を移動';

  @override
  String get shortcutEditCell => 'プロジェクト詳細を開く';

  @override
  String get shortcutViewRelease => 'リリースの詳細を表示';

  @override
  String get shortcutGoBack => '戻る';

  @override
  String get shortcutGroupProjectsTableStandardMode => '標準モード';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'セッションモード';

  @override
  String get shortcutToggleSession => 'セッション開始 / 終了';

  @override
  String get shortcutGroupPreviewPlayer => 'プレビュープレーヤー';

  @override
  String get shortcutPlayerPlayPause => '再生 / 一時停止';

  @override
  String get shortcutPlayerSeek5 => '±5秒シーク';

  @override
  String get shortcutPlayerSeek30 => '±30秒シーク';

  @override
  String get startupDialogTitle => 'DAW Project Manager へようこそ';

  @override
  String get startupDialogSubtitle =>
      'プロジェクトフォルダを追加するか、Google ドライブのバックアップを復元して始めましょう。';

  @override
  String get startupAddFolderTitle => 'プロジェクトフォルダを追加';

  @override
  String get startupAddFolderSubtitle => 'DAW プロジェクトが入っているフォルダを選択してください。';

  @override
  String get startupGoogleDriveTitle => 'Google ドライブのバックアップを同期';

  @override
  String get startupGoogleDriveSubtitle => 'Google ドライブのバックアップからプロジェクトを復元します。';

  @override
  String get startupDontShowAgain => '起動時に表示しない';

  @override
  String get pinnedLibraryWarningTitle => 'テスト用ライブラリを使用中';

  @override
  String get pinnedLibraryWarningBody =>
      'このビルドは専用のテスト用ライブラリにデータを保存するため、インストール済みのアプリが使うライブラリには影響しません。ここで変更したプロジェクト・プロファイル・設定は、そちらには表示されません。';

  @override
  String get pinnedLibraryWarningLibraryLabel => 'ライブラリ';

  @override
  String get pinnedLibraryWarningLocationLabel => '場所';

  @override
  String get pinnedLibraryWarningDontShowAgain => 'このライブラリについて今後警告しない';

  @override
  String get deleteAllData => 'すべてのデータを削除';

  @override
  String get deleteAllDataSubtitle =>
      'このデバイスからすべてのプロフィール、プロジェクト、リリース、プレイリスト、設定を削除します。';

  @override
  String get deleteAllDataConfirm1Title => 'すべてのデータを削除しますか？';

  @override
  String get deleteAllDataConfirm1Message =>
      'このデバイスからすべてのプロフィール、プロジェクト、リリース、プレイリスト、設定が完全に消去されます。Google ドライブのバックアップ（ある場合）には影響しません。';

  @override
  String get deleteAllDataConfirm2Title => '本当によろしいですか？';

  @override
  String get deleteAllDataConfirm2Message => 'この操作は元に戻せません。アプリは初期状態に戻ります。';

  @override
  String get deleteEverything => 'すべて削除';

  @override
  String get allDataDeleted => 'すべてのデータが削除されました。';

  @override
  String get newerExportFound => '新しいエクスポートが見つかりました';

  @override
  String newerExportFoundMessage(String filename) {
    return '同じフォルダーに新しいファイルが見つかりました：\n$filename\n\nプレビュー曲を置き換えますか？';
  }

  @override
  String get replaceAndPlay => '置き換えて再生';

  @override
  String get keepCurrent => '現在のを保持';

  @override
  String get autoBackup => '自動バックアップ';

  @override
  String get autoBackupDescription =>
      '選択した間隔で自動的にGoogle Driveにバックアップをアップロードします。';

  @override
  String get autoBackupInterval => 'バックアップ間隔';

  @override
  String get autoBackupOff => 'オフ';

  @override
  String get autoBackupEvery30Min => '30分ごと';

  @override
  String get autoBackupHourly => '1時間ごと';

  @override
  String get autoBackupEvery6Hours => '6時間ごと';

  @override
  String get autoBackupDaily => '毎日';

  @override
  String autoBackupNextBackup(String time) {
    return '次回バックアップ：$time';
  }

  @override
  String get autoBackupNextSoon => 'まもなく';

  @override
  String autoBackupNextInMinutes(int count) {
    return 'あと$count分';
  }

  @override
  String get autoBackupNextInOneHour => 'あと1時間';

  @override
  String autoBackupNextInHours(int count) {
    return 'あと$count時間';
  }

  @override
  String get autoBackupNextInOneDay => 'あと1日';

  @override
  String autoBackupNextInDays(int count) {
    return 'あと$count日';
  }

  @override
  String get playerTitle => 'ミュージックプレイヤー';

  @override
  String get playerToggleQueue => 'キューを切り替え';

  @override
  String get playerSearchHint => 'トラックを検索…';

  @override
  String playerTrackCount(int count) {
    return '$countトラック';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'プレビュー曲が見つかりません。\nプロジェクトを開いてプレビュー曲を設定してください。';

  @override
  String playerNoTracksMatch(String query) {
    return '\"$query\"に一致するトラックがありません';
  }

  @override
  String get playerDoubleClickToPlay => 'トラックをダブルクリックして再生';

  @override
  String get playerSingleClickToPreview => 'シングルクリックで下のバーにプレビュー';

  @override
  String get playerQueueTitle => 'キュー';

  @override
  String get playerClearQueue => 'キューをクリア';

  @override
  String get playerQueueEmptyHint => 'ダブルクリックで開始、\nまたはトラックをここにドラッグ。';

  @override
  String get playerPrev => '前へ';

  @override
  String get playerNext => '次へ';

  @override
  String get playerGoToProject => 'プロジェクトへ移動';

  @override
  String get playerAddToQueue => 'キューに追加';

  @override
  String get playerRemoveFromQueue => 'キューから削除';

  @override
  String get playerDismissDetail => '詳細を閉じる';

  @override
  String get playerNotes => 'メモ';

  @override
  String get playerTasks => 'タスク';

  @override
  String get playerNoTasks => 'タスクはまだありません。';

  @override
  String get playerAddTaskHint => 'タスクを追加…';

  @override
  String playerCompletedTasks(int count) {
    return '$count件完了';
  }

  @override
  String get playerPreviousTrack => '前のトラック';

  @override
  String get playerNextTrack => '次のトラック';

  @override
  String get playerOpenProject => 'プロジェクトを開く';

  @override
  String get playerRepeatAll => 'すべて繰り返す';

  @override
  String get playerShuffle => 'シャッフル';

  @override
  String get volumeMute => 'ミュート';

  @override
  String get volumeUnmute => 'ミュート解除';

  @override
  String totalWorkTime(String time) {
    return '総作業時間: $time';
  }

  @override
  String sessionTime(String time) {
    return 'セッション: $time';
  }

  @override
  String headerAgeOld(String age) {
    return '作成から$age';
  }

  @override
  String headerEdited(String when) {
    return '$whenに編集';
  }

  @override
  String headerWorked(String time) {
    return '作業時間 $time';
  }

  @override
  String get sessionHistory => 'セッション履歴';

  @override
  String get noSessionsYet => 'セッションはまだ記録されていません';

  @override
  String get removeSessionTitle => 'セッションを削除しますか？';

  @override
  String get editSessionTitle => 'セッション時間を編集';

  @override
  String get editSessionHours => '時間';

  @override
  String get editSessionInvalid => '時間は1分以上でなければなりません';

  @override
  String get sessionTableDate => '日付';

  @override
  String get sessionTableTime => '時刻';

  @override
  String get sessionTableDuration => '時間';

  @override
  String get sessionTableTotal => '合計';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countセッション',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'フェーズ別作業';

  @override
  String get tabPosition => 'タブの位置';

  @override
  String get tabPositionTop => '上';

  @override
  String get tabPositionLeft => '左';

  @override
  String updateAvailableMessage(String version) {
    return 'バージョン $version が利用可能です';
  }

  @override
  String get dismiss => '閉じる';

  @override
  String get checkForUpdates => 'アップデートを確認';

  @override
  String get checkForUpdatesDescription => '新しいバージョンが利用可能なときに通知を受け取ります。';

  @override
  String get checkNow => '今すぐ確認';

  @override
  String updateAvailable(String version) {
    return 'アップデートあり: v$version';
  }

  @override
  String get upToDate => 'アプリは最新です';

  @override
  String get updateAvailableTitle => 'アップデートあり';

  @override
  String updateAvailableVersion(String version) {
    return 'バージョン $version が利用可能です。';
  }

  @override
  String updateCurrentVersion(String version) {
    return '現在 v$version を使用中です。';
  }

  @override
  String get viewUpdateDetails => '詳細を見る';

  @override
  String get getOnMicrosoftStore => 'Microsoft Store で入手';

  @override
  String get downloadFromGitHub => 'GitHub からダウンロード';

  @override
  String get updateWindowsInstructions =>
      'Microsoft Store を開いて DAW Project Manager をアップデートするか、下のボタンをクリックしてください。';

  @override
  String get updateMacInstructions =>
      'GitHub から最新バージョンをダウンロードして現在のアプリと置き換えてください。';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions => 'その場で更新して再起動します。';

  @override
  String get updateNowButtonLabel => '今すぐ更新';

  @override
  String get appImageUpdateFetching => '更新を確認しています…';

  @override
  String get appImageUpdateDownloading => '更新をダウンロード中…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return '更新をダウンロード中… $percent%';
  }

  @override
  String get appImageUpdateVerifying => '検証してインストールしています…';

  @override
  String get appImageUpdateReadyTitle => '更新の準備完了';

  @override
  String appImageUpdateReadyMessage(String version) {
    return 'v$version に更新しました。完了するには今すぐ再起動してください。';
  }

  @override
  String get appImageUpdateRestartNow => '今すぐ再起動';

  @override
  String get appImageUpdateFailedTitle => '更新に失敗しました';

  @override
  String get appImageUpdateRetry => '再試行';

  @override
  String get appImageUpdateErrorMessage =>
      '更新中にエラーが発生しました。もう一度お試しいただくか、下のエラー詳細をご確認ください。';

  @override
  String get appImageUpdateErrorDetailsLabel => 'エラーの詳細';

  @override
  String get appImageUpdateCopyErrorDetails => 'エラー詳細をコピー';

  @override
  String get appImageUpdateErrorDetailsCopied => 'エラー詳細をコピーしました';

  @override
  String get resetOnboarding => '初期設定をリセット';

  @override
  String get onboardingWelcomeTitle => 'DAW Project Managerへようこそ';

  @override
  String get onboardingWelcomeBody => 'すべての音楽プロジェクトを一か所で管理できます。';

  @override
  String get onboardingFeatureScanFolders => 'DAWプロジェクトフォルダを自動的にスキャン';

  @override
  String get onboardingFeatureTrackMetadata => 'BPM、キー、ステータス、締切を管理';

  @override
  String get onboardingFeatureSyncDrive => 'メタデータをGoogle Driveと同期';

  @override
  String get onboardingFeatureTrackTime => '各プロジェクトに費やした時間を記録';

  @override
  String get onboardingLanguageTitle => '言語を選択';

  @override
  String get onboardingThemeTitle => 'テーマを選択';

  @override
  String get onboardingFoldersTitle => 'プロジェクトフォルダを追加';

  @override
  String get onboardingFoldersBody => 'DAWプロジェクトが保存されているルートフォルダを追加してください。';

  @override
  String get onboardingDriveTitle => 'Google Driveの同期';

  @override
  String get onboardingDriveBody => 'プロジェクトのメタデータをGoogle Driveにバックアップして同期します。';

  @override
  String get onboardingUpdatesTitle => 'アップデート確認';

  @override
  String get onboardingUpdatesBody => '新しいバージョンが利用可能なときに通知を受け取ります。';

  @override
  String get onboardingDoneTitle => '準備完了！';

  @override
  String get onboardingDoneBody => 'プロジェクトの探索を始めましょう。';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingBack => '戻る';

  @override
  String get onboardingGetStarted => '始める';

  @override
  String get dawSession => 'DAWセッション';

  @override
  String get clearDawSession => 'セッションをクリア';

  @override
  String get stop => '停止';

  @override
  String get pause => '一時停止';

  @override
  String get playPauseTooltip => '再生 / 一時停止';

  @override
  String get resume => '再開';

  @override
  String get workTimerSection => '作業セッションリマインダー';

  @override
  String get workTimerSectionDesc => '作業セッションがアクティブな間、定期的に通知を受け取る';

  @override
  String get workTimerRequiresSessionMode =>
      '作業セッションリマインダーを使用するには、上のセッションモードを有効にしてください';

  @override
  String get workTimerEnabled => '作業セッションリマインダーを有効にする';

  @override
  String get workTimerIntervalLabel => '次の間隔で通知';

  @override
  String get minutes => '分';

  @override
  String workTimerNotifBody(String time) {
    return '$time間作業しています';
  }

  @override
  String get sendTestNotification => 'テスト通知を送信';

  @override
  String get testNotificationTitle => 'テスト通知';

  @override
  String get testNotificationBody => 'これはDAW Project Managerからのテスト通知です。';

  @override
  String get general => '一般';

  @override
  String get expand => '展開';

  @override
  String get collapse => '折りたたむ';

  @override
  String get lastModifiedColors => '最終更新日の色';

  @override
  String get lastModifiedColorsDescription =>
      '最終更新日を経過時間とステータスに基づいて色分けします。緑 = 完成。古い日付は黄色から赤色に変化し、赤が濃いほどプロジェクトが長期間手付かずであることを示します。';

  @override
  String get sessionMode => 'セッションモード';

  @override
  String get sessionModeDescription =>
      'プロジェクトでセッションを開始して、作業時間を記録し、ツールバーから管理します';

  @override
  String get workSessionsTabLabel => '作業セッション';

  @override
  String get normalMode => '通常モード';

  @override
  String get normalModeDescription => '起動時にプロジェクトが直接DAWで開きます。';

  @override
  String get sessionModeCardDescription =>
      'セッションを開始すると、プロジェクトでの作業内容と時間を記録できます。';

  @override
  String get startSession => 'セッション開始';

  @override
  String get endSession => 'セッション終了';

  @override
  String get switchSession => 'セッション切替';

  @override
  String get switchSessionBody => '現在のセッションを終了して新しいセッションを開始しますか？';

  @override
  String switchSessionCurrent(String project) {
    return '現在: $project';
  }

  @override
  String switchSessionNew(String project) {
    return '新規: $project';
  }

  @override
  String get sessionDuration => 'セッション時間';

  @override
  String get scanModeLabel => 'スキャンモード:';

  @override
  String get scanModeSectionTitle => 'スキャンモード';

  @override
  String get scanModeSectionDescription =>
      '各フォルダー内のプロジェクトをテーブルに表示する方法を制御します — 単純なフラットリストまたはサブフォルダーでグループ化。';

  @override
  String get smartFolderOptionsSectionTitle => 'スマートフォルダーのオプション';

  @override
  String get smartFolderOptionsSectionDescription =>
      'プロジェクトテーブルでのスマートフォルダーグループの動作を調整します。';

  @override
  String get excludeSmartFoldersFromSort => 'スマートフォルダを並べ替えの対象外にする';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      'プロジェクト一覧を列で並べ替えても、スマートフォルダのグループは移動せずその位置にとどまります。並べ替えられるのはグループ内のプロジェクト（およびグループ化されていないプロジェクト）のみです。実験的機能のため、初期設定ではオフです。';

  @override
  String get mergeSmartFoldersByName => '同じ名前のスマートフォルダを統合';

  @override
  String get mergeSmartFoldersByNameDescription =>
      '2つのスキャンルート（例えば異なるDAW）に同じ名前のトップレベルフォルダがある場合、プロジェクト一覧では2つの別々のグループではなく、1つに統合されたグループとして扱います。';

  @override
  String get alwaysShowSmartFolders => 'スマートフォルダを常に表示';

  @override
  String get alwaysShowSmartFoldersDescription =>
      '検索やフィルターの結果、フォルダ内のプロジェクトが1件だけ表示されている場合でも、グループ化されていない単純な行にまとめず、スマートフォルダを独立したグループ行として表示します。';

  @override
  String get scanModeFlat => 'フラット';

  @override
  String get scanModeSmartFolder => 'スマートフォルダー';

  @override
  String get scanModeFlatDescription => 'すべてのプロジェクトをフラットリストで表示します。シンプルで高速。';

  @override
  String get scanModeSmartFolderDescription =>
      'フォルダに複数のプロジェクトがある場合、フォルダでグループ化します。';

  @override
  String get skip => 'スキップ';

  @override
  String get suggestionsLabel => 'おすすめ';

  @override
  String get suggestionsRefresh => '更新';

  @override
  String get suggestionsEmptyState =>
      '現在おすすめはありません。更新をタップして非表示アイテムをリセットしてください。';

  @override
  String get suggestionNewProject => '新規';

  @override
  String get showSuggestions => 'おすすめを表示';

  @override
  String get showSuggestionsDescription => 'セッションが実行されていないときにツールバーにスマートな提案を表示';

  @override
  String get onboardingSuggestionsTitle => 'スマートなおすすめ';

  @override
  String get onboardingSuggestionsBody => '作業中にツールバーにパーソナライズされたプロジェクトのおすすめを取得';

  @override
  String get onboardingSessionModeTitle => 'セッションモード';

  @override
  String get onboardingSessionModeBody =>
      '集中した作業セッションを開始し、各プロジェクトの作業時間を自動的に記録します';

  @override
  String get suggestionsFeatureDeadlines => '今後のプロジェクトの締め切りリマインダー';

  @override
  String get suggestionsFeatureResume => '最後に作業したプロジェクトを再開';

  @override
  String get suggestionsFeatureRecentlyModified => '最近変更したトラックを続ける';

  @override
  String get suggestionsEnableToggle => 'スマートなおすすめを有効にする';

  @override
  String get canBeChangedInSettings => '設定で後から変更できます';

  @override
  String get next => '次へ';

  @override
  String get createProject => '作成';

  @override
  String get createProjectTooltip => '新しいプロジェクトフォルダを作成';

  @override
  String get createProjectSelectFolder => '場所を選択';

  @override
  String get createProjectSelectFolderHint => '新しいプロジェクトを作成するフォルダを選択してください';

  @override
  String get createProjectNameTitle => 'プロジェクト名を設定';

  @override
  String get createProjectNameHint => '新しいフォルダの命名規則を選択してください';

  @override
  String get createProjectSchemeArtistTrack => 'アーティスト — トラック';

  @override
  String get createProjectSchemeCollab => 'コラボ';

  @override
  String get createProjectSchemeDate => '日付 — トラック';

  @override
  String get createProjectSchemeCustom => 'カスタム';

  @override
  String get createProjectSchemeRemix => 'リミックス';

  @override
  String get createProjectArtistName => 'アーティスト名';

  @override
  String get createProjectTrackName => 'トラック名';

  @override
  String get createProjectCustomName => 'フォルダ名';

  @override
  String get createProjectAddArtist => 'アーティストを追加';

  @override
  String get createProjectOriginalArtist => 'オリジナルアーティスト';

  @override
  String get createProjectRemixerName => 'リミキサー';

  @override
  String get createProjectAddRemixer => 'リミキサーを追加';

  @override
  String get createProjectSelectDaw => 'DAWで開く';

  @override
  String get createProjectSelectDawHint => 'このプロジェクトで使用するDAWを選択してください';

  @override
  String get createProjectDetectDaws => 'インストール済みDAWを検出';

  @override
  String get createProjectSkipDaw => 'フォルダのみ作成';

  @override
  String get createProjectNoDawsFound => 'DAWが見つかりませんでした。フォルダは作成されます。';

  @override
  String get createProjectCreateOnly => 'フォルダを作成';

  @override
  String get createProjectCreateAndOpen => '作成して開く';

  @override
  String get createProjectFolderExists => '同じ名前のフォルダが既に存在します';

  @override
  String get createProjectInvalidChars => 'フォルダ名に無効な文字が含まれています';

  @override
  String get createProjectError => 'フォルダの作成に失敗しました';

  @override
  String get createProjectIncludeDate => '日付プレフィックスを含める';

  @override
  String get createProjectCreatedTitle => 'フォルダーが作成されました';

  @override
  String get createProjectCreatedMessage => 'プロジェクトフォルダーが作成されました：';

  @override
  String get createProjectCopyName => 'フォルダー名をコピー';

  @override
  String get createProjectNameCopied => 'フォルダー名をコピーしました';

  @override
  String get createProjectTrackSession => '今からセッションを記録する';

  @override
  String get pendingFolderSessionTitle => '作業セッションを検出しました';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return '「$projectName」で$duration作業しました。';
  }

  @override
  String get pendingFolderSessionContinue => 'セッションを続ける';

  @override
  String get pendingFolderSessionEndRecord => '終了して記録';

  @override
  String get activeSessionSwitchTitle => 'セッションが実行中';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return '「$current」のセッションが実行中です。「$next」に切り替えて現在のセッションを保存しますか？';
  }

  @override
  String get activeSessionSwitch => '切り替える';

  @override
  String get pendingProjectWaiting => 'プロジェクトファイルを待っています…';

  @override
  String get pendingProjectDelete => '空のフォルダを削除';

  @override
  String get pendingProjectDeleteTitle => 'フォルダを削除しますか？';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return '「$folderName」とその内容を削除しますか？';
  }

  @override
  String get pendingProjectDismiss => 'このフォルダの追跡を停止';

  @override
  String get pendingProjectDismissTitle => 'トラッキングを停止しますか？';

  @override
  String get pendingProjectDismissKeep => 'フォルダーを保持';

  @override
  String get pendingProjectDismissDelete => '削除して閉じる';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'フォルダが空ではありません';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '「$folderName」にはファイルが含まれています。すべて完全に削除しますか？';
  }

  @override
  String get pendingProjectRefresh => 'プロジェクトファイルを確認';

  @override
  String get pendingProjectNotFound => 'プロジェクトファイルはまだ見つかりません';

  @override
  String get phases => 'フェーズ';

  @override
  String get phasesSubtitle => 'プロジェクトフェーズの追加・削除・並べ替え';

  @override
  String get phasesDescription =>
      'フェーズは、ワークフロー内の各プロジェクトの段階（例：アイデア → ミキシング → マスタリング）を追跡します。ドラッグして並べ替え、カラードットをタップして色を変更し、フェーズを完了としてフラグ付けすると、アプリ全体で完了扱いになります。';

  @override
  String get resetToDefaults => 'デフォルトにリセット';

  @override
  String get addPhase => 'フェーズを追加';

  @override
  String get phaseNameHint => 'フェーズ名';

  @override
  String get phaseDuplicateError => '同じ名前のフェーズが既に存在します';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このフェーズを使用しているプロジェクトが$count件あります',
      one: 'このフェーズを使用しているプロジェクトが1件あります',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => '色を選択';

  @override
  String get markAsFinished => '完了フェーズとしてマーク';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプロジェクトが存在しなくなるフェーズを使用しています。',
      one: '1件のプロジェクトが存在しなくなるフェーズを使用しています。',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'これらのプロジェクトは現在のステータスを保持しますが、フェーズフィルターには表示されません。後でいつでもフェーズを再追加できます。';

  @override
  String get resetPhasesConfirm => 'カスタムフェーズ、色、完了フェーズのフラグをすべてデフォルトにリセットしますか？';

  @override
  String get camelotGenerateButton => 'ミックス生成';

  @override
  String get camelotDialogTitle => 'キャメロットミックス';

  @override
  String get camelotDialogDescription =>
      'キャメロットホイールを使って和声的な互換性順にトラックを並べ替えます。同等の場合はBPMの近さを優先します。';

  @override
  String camelotEligibleTracks(int count) {
    return '$countトラックが対象（キー設定済み）';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$countトラックをスキップ（キー未設定）';
  }

  @override
  String get camelotNoEligibleTracks =>
      '音楽キーが設定されたトラックがありません。プロジェクトを開いてキーを設定してください。';

  @override
  String get camelotGenerate => '生成';

  @override
  String camelotQueueGenerated(int count) {
    return '$countトラックを和声的な順序でキューに追加しました';
  }

  @override
  String get camelotWheelGuideTooltip => 'キャメロットホイールガイド';

  @override
  String get camelotWheelGuideTitle => 'キャメロットホイールガイド';

  @override
  String get camelotGuideRingsTitle => 'リング';

  @override
  String get camelotGuideRingsBody => '内側リング（A）  →  短調のキー\n外側リング（B）  →  長調のキー';

  @override
  String get camelotGuideNumbersTitle => '数字 1–12';

  @override
  String get camelotGuideNumbersBody =>
      '位置は時計回りに配置されています。各番号は和声的な近隣を表し、隆接する番号は強い音調関係を共有します。';

  @override
  String get camelotGuideColoursTitle => 'カラーガイド';

  @override
  String get camelotGuideColoursBody =>
      '● 明るい  →  あなたの曲のキー\n● 淡く光る  →  ミックスに適している\n● 暗い  →  スムーズなミックスには避ける';

  @override
  String get camelotGuideTransitionsTitle => '互換性のある転換';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  （同じ番号、リングを切り替え）\n  平行長調/短調 — ほぼシームレス。\n\n8A → 7A または 9A  （±1、同じリング）\n  隣接キー — スムーズで細腐な変化。\n\n8A → 1A または 3A  （±7、同じリング）\n  エネルギーブーストまたはドロップ — より劧的な変化。';

  @override
  String get playerMixSuggestions => 'ミックス候補';

  @override
  String get nowPlaying => '再生中';

  @override
  String get noPreviewSongsAvailable => '利用可能なプレビュー曲がありません';

  @override
  String get upNext => '次の曲';

  @override
  String get playbackModeNormal => '通常';

  @override
  String get playbackModeRepeat => 'リピート';

  @override
  String get playbackModeShuffle => 'シャッフル';

  @override
  String get hideDatesInNames => 'プロジェクト名の日付を非表示';

  @override
  String get hideDatesInNamesDescription =>
      '一部のDAWはプロジェクトファイル名の先頭に作成日を付けます（例:「2026-08-02 - My Track」）。これを非表示にしてタイトルだけを表示します。ファイル自体の名前は変更されません。';

  @override
  String get findPreviewAutomatically => '自動的に探す';

  @override
  String get noPreviewSongFoundAutomatically =>
      'このプロジェクトのミックスダウンフォルダにプレビュー曲が見つかりませんでした。';

  @override
  String get selectProjects => '選択';

  @override
  String sharePreviewSongText(String name) {
    return 'プレビュー曲: $name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return 'プレビュー曲 (ZIP): $name';
  }

  @override
  String get songParts => '楽器とパート';

  @override
  String partsProgress(int done, int total) {
    return '$total 件中 $done 件が最終テイク';
  }

  @override
  String get noPartsYet => 'パートはまだ登録されていません';

  @override
  String get noPartsYetHint => '曲に必要な楽器、担当者、各テイクの進み具合を記録しましょう。';

  @override
  String get addPart => 'パートを追加';

  @override
  String get addPartHint => '例: ドラム、リードボーカル、ベース';

  @override
  String get partNameLabel => 'パート';

  @override
  String get partNameRequired => 'パート名を入力してください';

  @override
  String get partPerformerLabel => '担当者';

  @override
  String get partPerformerHint => '演奏する人';

  @override
  String get partNotesLabel => 'パートのメモ';

  @override
  String get partStatusLabel => 'テイクの状態';

  @override
  String get partStatusNeeded => '未着手';

  @override
  String get partStatusRecording => '録音中';

  @override
  String get partStatusEarlyTake => '仮テイク';

  @override
  String get partStatusFinalTake => '最終テイク';

  @override
  String get editPart => 'パートを編集';

  @override
  String get deletePart => 'パートを削除';

  @override
  String get partsUnassignedPerformer => '未割り当て';

  @override
  String get partTemplates => 'パートテンプレート';

  @override
  String get importPartsFromTemplate => 'テンプレートからパートを読み込む';

  @override
  String get managePartTemplates => 'パートテンプレートを管理';

  @override
  String get selectPartTemplate => 'パートテンプレートを選択';

  @override
  String get noPartTemplatesAvailable => '利用できるパートテンプレートがありません';

  @override
  String get noPartTemplatesYet => 'パートテンプレートがまだありません';

  @override
  String get createFirstPartTemplate => '同じ編成を曲ごとに使い回すテンプレートを作成しましょう';

  @override
  String get createPartTemplate => 'パートテンプレートを作成';

  @override
  String get editPartTemplate => 'パートテンプレートを編集';

  @override
  String get deletePartTemplate => 'パートテンプレートを削除';

  @override
  String deletePartTemplateConfirm(String name) {
    return 'パートテンプレート「$name」を削除しますか？';
  }

  @override
  String get partTemplateCreated => 'パートテンプレートを作成しました';

  @override
  String get partTemplateUpdated => 'パートテンプレートを更新しました';

  @override
  String get partTemplateDeleted => 'パートテンプレートを削除しました';

  @override
  String get partTemplateItems => 'パート（1行に1つ）';

  @override
  String get partTemplateItemsHint => 'ドラム — Alex\nベース — Sam\nリードボーカル';

  @override
  String get partTemplateItemsHelp => '1行に1パート。ダッシュのあとに担当者を書けます: ドラム — Alex';

  @override
  String get partTemplateItemsRequired => 'パートを1つ以上追加してください';

  @override
  String get partTemplateNameAndItemsRequired => '名前とパートが1つ以上必要です';

  @override
  String partTemplateItemCount(int count) {
    return '$count パート';
  }

  @override
  String partTemplateImported(String name, int count) {
    return 'パートテンプレート「$name」を読み込みました（$count パート）';
  }

  @override
  String get errorLoadingPartTemplates => 'パートテンプレートの読み込みに失敗しました';

  @override
  String get exportPartsCsv => 'パートをCSVで書き出す';

  @override
  String get exportAllPartsCsv => 'すべての曲のパートをCSVで書き出す';

  @override
  String get exportAllPartsCsvSubtitle =>
      '全プロジェクトのパートを1行ずつ表計算形式で書き出し、進捗を共有できます';

  @override
  String get noPartsToExport => '書き出すパートがありません';

  @override
  String partsCsvExported(int count) {
    return '$count 件のパートを書き出しました';
  }

  @override
  String get projectExportPartsLabel => 'パート:';

  @override
  String get csvHeaderProject => 'プロジェクト';

  @override
  String get csvHeaderPart => 'パート';

  @override
  String get csvHeaderPerformer => '担当者';

  @override
  String get csvHeaderStatus => '状態';

  @override
  String get csvHeaderNotes => 'メモ';

  @override
  String get exportPartsXlsx => 'パートをExcel (.xlsx) で書き出す';

  @override
  String get exportAllPartsXlsx => 'すべての曲のパートをExcel (.xlsx) で書き出す';

  @override
  String get exportAllPartsXlsxSubtitle =>
      'CSVと同じ表に、見出し行の固定・フィルター・テイク状態の色分けを加えたものです';

  @override
  String get importPartsFromSpreadsheet => 'スプレッドシートからパートを読み込む';

  @override
  String get partsImportPickerTitle => 'CSVまたはExcelファイルを選択';

  @override
  String partsImported(int added, int updated) {
    return '$added 件を追加、$updated 件を更新しました';
  }

  @override
  String get partsImportNothingFound => 'そのファイルにパートが見つかりませんでした';

  @override
  String partsImportFailed(String error) {
    return 'そのスプレッドシートを読み込めませんでした: $error';
  }

  @override
  String get partsMoreActions => 'パートのその他の操作';

  @override
  String partsPageTitle(String name) {
    return '$name — パート';
  }

  @override
  String get manageParts => 'パートを管理';

  @override
  String partsMoreCount(int count) {
    return '他 $count 件';
  }

  @override
  String get searchParts => 'パートを検索';

  @override
  String get allStatuses => 'すべての状態';

  @override
  String get allPerformers => 'すべての担当者';

  @override
  String partsSelectedCount(int count) {
    return '$count 件を選択中';
  }

  @override
  String get setPartStatus => '状態を設定';

  @override
  String get assignPartPerformer => '担当者を割り当て';

  @override
  String get deleteSelectedParts => '選択を削除';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return 'この曲から $count 件のパートを削除しますか？';
  }

  @override
  String partsDeleted(int count) {
    return '$count 件のパートを削除しました';
  }

  @override
  String get noPartsMatchFilters => 'この条件に合うパートはありません';

  @override
  String get reorderNeedsUnfilteredList =>
      '検索・絞り込み・並べ替えを解除するとパートをドラッグで並べ替えられます';

  @override
  String get projectMarkers => 'マーカー';

  @override
  String projectMarkerUnnamed(int index) {
    return 'マーカー $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return 'リージョン $index';
  }

  @override
  String get projectMarkerJumpTooltip => 'プレビュー曲のこの位置にジャンプ';

  @override
  String get projectMarkerNoPreviewSong => 'マーカーにジャンプするにはプレビュー曲を追加してください';

  @override
  String get projectDetailLayout => 'プロジェクト詳細のレイアウト';

  @override
  String get projectDetailLayoutSettingDescription => 'プロジェクト詳細ページの構成方法。';

  @override
  String get projectDetailLayoutClassic => 'クラシック';

  @override
  String get projectDetailLayoutClassicDescription => 'すべてを1つのスクロールで表示。';

  @override
  String get projectDetailLayoutSectioned => 'セクション';

  @override
  String get projectDetailLayoutSectionedDescription => '左のバーでセクションを1つずつ選択。';

  @override
  String get stackAsVersions => 'バージョンとしてまとめる';

  @override
  String get stackNeedsTwoVersions =>
      '1つのメインプロジェクトのバージョンとしてまとめるには、プロジェクトを2つ以上選択してください。';

  @override
  String stackCreatedMessage(int count) {
    return '$count 個のバージョンを1つのメインプロジェクトにまとめました。';
  }

  @override
  String get stackVersionsTitle => 'バージョン';

  @override
  String stackVersionCount(int count) {
    return '$count バージョン';
  }

  @override
  String get stackAddVersion => 'バージョンを追加';

  @override
  String get stackAddVersionTitle => 'バージョンを追加';

  @override
  String get stackAddVersionEmpty => '追加できる未スタックのプロジェクトがありません。';

  @override
  String get stackRemoveVersion => 'スタックから削除';

  @override
  String get stackRemoveVersionMessage =>
      'プロジェクトファイルはディスク上に残り、単独のプロジェクトとして一覧に戻ります。';

  @override
  String get stackUnstack => 'スタックを解除';

  @override
  String get stackUnstackTitle => 'このメインプロジェクトのスタックを解除しますか？';

  @override
  String get stackUnstackMessage =>
      '各バージョンはスタック前のメタデータを持つ単独のプロジェクトに戻ります。メインプロジェクトに保存された共有のノート・タスク・期限は削除されます。';

  @override
  String get stackDefaultVersion => 'デフォルトで開く';

  @override
  String get stackSetDefaultVersion => 'このバージョンをデフォルトで開く';

  @override
  String get stackChooseVersionToOpen => 'どのバージョンを開きますか？';

  @override
  String get stackMemberOf => '次のプロジェクトのバージョン';

  @override
  String get stackMemberNotice =>
      'このファイルはスタックされたプロジェクトの1バージョンです。共有のメタデータ・タスク・作業時間はメインプロジェクト側にあり、ここにはありません。';

  @override
  String get stackOpenMainProject => 'メインプロジェクトを開く';

  @override
  String get stackWorkTimeAcrossVersions => '全バージョンの合計';

  @override
  String get scanModeVersionStack => 'バージョンスタック';

  @override
  String get scanModeVersionStackDescription =>
      'フォルダー内のすべてのプロジェクトファイルが1つのメインプロジェクトになり、メタデータ・タスク・作業時間を共有します。新しく見つかったファイルは自動的に追加されます。';

  @override
  String stackTooltipStacked(int count) {
    return '$count 個のバージョンを1つのメインプロジェクトにまとめています';
  }

  @override
  String get stackMetadataSourceTitle => 'どのプロジェクトをメインプロジェクトにしますか？';

  @override
  String get stackMetadataSourceBody =>
      '複数のプロジェクトにすでに独自の詳細があります。選んだものがメインプロジェクトになり、その名前・BPM・キー・ノート・タスク・期限がスタックで使われます。統合も消失もありません。他のプロジェクトは自分の詳細を保持し、スタックを解除すれば元に戻ります。';

  @override
  String get stackMetadataSourceOldestHint => '最も古い — 推奨';

  @override
  String get stackMetadataNoneLabel => '詳細なし';

  @override
  String stackMetadataTodosLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のタスク',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataNotesLabel => 'ノート';

  @override
  String get stackNotStackedYet => 'まだスタックされていません';

  @override
  String get stackStartFromHere =>
      '他のプロジェクトファイルを追加すると、1つのメインプロジェクトのバージョンになり、メタデータ・タスク・作業時間を共有します。';

  @override
  String get stackSearchProjects => 'プロジェクトを検索';

  @override
  String get stackSearchNoMatches => '検索に一致するプロジェクトがありません。';

  @override
  String get stackStartedMessage => '1つのメインプロジェクトにまとめました。';

  @override
  String get stackDefaultVersionTooltip => 'DAW を起動すると、このバージョンがデフォルトで開きます。';

  @override
  String stackAddVersionsConfirm(int count) {
    return '$count 件を追加';
  }

  @override
  String get stackAddVersionMultiTitle => 'バージョンを追加';

  @override
  String get stackSelectAll => 'すべて選択';

  @override
  String get stackClearSelection => 'クリア';

  @override
  String stackMetadataPartsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のパート',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataDeadlineLabel => '期限';

  @override
  String get stackMetadataRenamedLabel => 'カスタム名';

  @override
  String stackMetadataWorkHours(String hours) {
    return '$hours 時間記録';
  }

  @override
  String get stackUnstackReleaseTitle => 'どのバージョンをリリースに残しますか？';

  @override
  String stackUnstackReleaseBody(String releases) {
    return 'このプロジェクトは $releases の収録曲です。スタックを解除すると、まとめられたエントリーがなくなるため、いずれかのバージョンがその位置を引き継ぐ必要があります。リリースが参照するバージョンを選んでください。';
  }

  @override
  String get stackAutoConfirmTitle => 'これらのバージョンをまとめますか？';

  @override
  String stackAutoConfirmBody(int projects, int folders) {
    return 'バージョンスタックは $folders 個のフォルダーにある $projects 件のプロジェクトをまとめます。各フォルダーが1つのメインプロジェクトになり、メタデータ・タスク・作業時間を共有します。削除は行われず、後からスタックを解除できます。';
  }

  @override
  String get stackAutoConfirmApply => 'まとめる';

  @override
  String stackAutoFolderEntry(String folder, int count) {
    return '$folder — $count バージョン';
  }

  @override
  String get stackAutoJoinsExisting => '既存のメインプロジェクトに追加';

  @override
  String get untitledTheme => '名称未設定のテーマ';

  @override
  String switchToTheme(String themeName) {
    return '$themeName に切り替え';
  }

  @override
  String get newTheme => '新しいテーマ';

  @override
  String get editTheme => 'テーマを編集';

  @override
  String get duplicateTheme => '複製';

  @override
  String get deleteThemeTitle => 'テーマを削除しますか？';

  @override
  String deleteThemeMessage(String name) {
    return '「$name」を削除します。元に戻せません。';
  }

  @override
  String get themeNameLabel => 'テーマ名';

  @override
  String get themeNameHint => '例: Studio Amber';

  @override
  String get themeNameRequired => 'テーマ名を入力してください。';

  @override
  String get themeColorAccent => 'アクセント';

  @override
  String get themeColorSecondaryAccent => 'サブアクセント';

  @override
  String get themeColorBackground => '背景';

  @override
  String get themeColorCards => 'カードとパネル';

  @override
  String get themeCardRoundness => 'カードの角丸';

  @override
  String get themeButtonRoundness => 'ボタンの角丸';

  @override
  String themeLowContrastWarning(String ratio) {
    return 'コントラストが低いです（$ratio:1）。文字が読みにくい可能性があります。';
  }

  @override
  String get exportTheme => 'テーマを書き出す';

  @override
  String get importTheme => 'テーマを読み込む';

  @override
  String themeExported(String path) {
    return 'テーマを $path に書き出しました';
  }

  @override
  String themeImported(String name) {
    return '「$name」を読み込みました';
  }

  @override
  String get themeImportFailed => 'このファイルは有効なテーマではありません。';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexInvalid => '#RRGGBB の形式で入力';

  @override
  String get apply => '適用';

  @override
  String themeCopyName(String name) {
    return '$name のコピー';
  }

  @override
  String get suggestedColorsLabel => 'おすすめの色';

  @override
  String get moveProjectButtonLabel => '移動…';

  @override
  String get moveProjectDialogTitle => 'プロジェクトを移動';

  @override
  String get moveProjectDestinationLabel => '移動先';

  @override
  String get moveProjectChooseDestination => '選択…';

  @override
  String get moveProjectNoDestinationChosen => 'フォルダーが未選択です';

  @override
  String moveProjectIncludeFolder(String folder) {
    return '「$folder」フォルダー全体を移動';
  }

  @override
  String get moveProjectIncludeFolderDescription =>
      'このフォルダーにはこのプロジェクトしかないため、サンプルやミックスダウンも一緒に移動します。';

  @override
  String get moveProjectFileOnlyDescription =>
      'プロジェクトファイルのみを移動します。隣にあるサンプルやミックスダウンはそのまま残ります。';

  @override
  String get moveProjectConfirm => '移動';

  @override
  String get moveProjectInProgress => '移動中…';

  @override
  String moveProjectSuccess(String name, String path) {
    return '「$name」を $path に移動しました';
  }

  @override
  String moveProjectFailed(String error) {
    return '移動に失敗しました: $error';
  }

  @override
  String get moveProjectErrorSourceMissing => 'このプロジェクトのファイルはこのマシンにありません。';

  @override
  String moveProjectErrorDestinationOccupied(String name) {
    return '「$name」はそのフォルダーに既に存在します。';
  }

  @override
  String get moveProjectErrorDestinationInsideSource =>
      'フォルダーを自分自身の中へ移動することはできません。';

  @override
  String get moveProjectErrorSameLocation => 'プロジェクトは既にそのフォルダーにあります。';

  @override
  String get moveProjectStackUnsupported =>
      'バージョンスタックには固有のファイルがありません。各バージョンを個別に移動してください。';

  @override
  String get selectMoveDestinationTitle => '移動先フォルダーを選択';

  @override
  String get archiveProjectButtonLabel => 'アーカイブ…';

  @override
  String get archiveProjectDialogTitle => 'プロジェクトをアーカイブ';

  @override
  String get archiveProjectWhatToArchive => 'アーカイブする対象';

  @override
  String archiveProjectScopeFolder(String folder) {
    return '「$folder」フォルダー全体';
  }

  @override
  String get archiveProjectScopeFileOnly => 'プロジェクトファイルのみ';

  @override
  String archiveScopeSummary(String size, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files 個のファイル',
    );
    return '$size · $_temp0';
  }

  @override
  String get archiveProjectDeleteOriginals => 'アーカイブを検証してから元のファイルを削除する';

  @override
  String get archiveProjectDeleteOriginalsDescription =>
      '先にアーカイブを開き直し、項目ごとに確認します。この確認に失敗した場合は何も削除しません。';

  @override
  String get archiveProjectConfirm => 'アーカイブ';

  @override
  String get archiveStageScanning => 'プロジェクトフォルダーを読み込み中…';

  @override
  String get archiveStageCompressing => '圧縮中…';

  @override
  String get archiveStageVerifying => 'アーカイブを検証中…';

  @override
  String get archiveStageDeleting => '元のファイルを削除中…';

  @override
  String archiveProjectSuccess(String name) {
    return '「$name」をアーカイブしました';
  }

  @override
  String archiveProjectFailed(String error) {
    return 'アーカイブに失敗しました: $error';
  }

  @override
  String get archiveErrorSourceMissing => 'このプロジェクトのファイルはこのマシンにありません。';

  @override
  String archiveErrorDestinationInScanRoot(String root) {
    return 'アーカイブはスキャン対象フォルダーの中には置けません。「$root」がすぐに再登録してしまいます。';
  }

  @override
  String archiveErrorDestinationOccupied(String name) {
    return 'そこには既に「$name」というアーカイブがあります。';
  }

  @override
  String archiveErrorVerificationFailed(String entries) {
    return 'アーカイブにファイルが不足しているため、何も削除していません: $entries';
  }

  @override
  String get archiveErrorNotArchived => 'このプロジェクトはアーカイブされていません。';

  @override
  String archiveWarningsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '読み取れないファイル $count 個をスキップしました',
    );
    return '$_temp0';
  }

  @override
  String get archiveLocationTitle => 'アーカイブの保存先';

  @override
  String get archiveLocationSubtitle =>
      '「プロジェクトをアーカイブ」が zip を書き出す場所です。この端末に保存されます。';

  @override
  String get archiveLocationNotSet => '未設定 — 最初のアーカイブ時に確認します';

  @override
  String get selectArchiveLocationTitle => 'アーカイブフォルダーを選択';

  @override
  String get restoreProjectButtonLabel => '復元…';

  @override
  String get restoreProjectDialogTitle => 'プロジェクトを復元';

  @override
  String get restoreProjectDescription =>
      '選択したフォルダーにアーカイブを展開し、プロジェクトを復元後のファイルに向け直します。';

  @override
  String get restoreProjectConfirm => '復元';

  @override
  String get restoreProjectInProgress => '復元中…';

  @override
  String restoreProjectSuccess(String name) {
    return '「$name」を復元しました';
  }

  @override
  String restoreProjectFailed(String error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get selectRestoreDestinationTitle => '復元先のフォルダーを選択';

  @override
  String get archivedLabel => 'アーカイブ済み';

  @override
  String archivedOnLabel(String date) {
    return '$date にアーカイブ';
  }

  @override
  String get showArchivedProjects => 'アーカイブ済みを表示';

  @override
  String get showOnlyArchivedProjects => 'アーカイブ済みのみ';

  @override
  String get hideArchivedProjects => 'アーカイブ済みを非表示';

  @override
  String get archivedFilterLabel => 'アーカイブ';

  @override
  String get archiveProjectStackUnsupported =>
      'バージョンスタックには固有のファイルがありません。各バージョンを個別にアーカイブしてください。';

  @override
  String get archiveBulkButtonLabel => '選択項目をアーカイブ';

  @override
  String archiveBulkConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクトをアーカイブしますか？',
    );
    return '$_temp0';
  }

  @override
  String archiveBulkSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクトをアーカイブしました',
    );
    return '$_temp0';
  }

  @override
  String get openArchiveFolder => 'アーカイブフォルダーを開く';

  @override
  String archiveBulkProgress(int current, int total) {
    return '$total 件中 $current 件';
  }

  @override
  String archiveBulkFailures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクトをアーカイブできませんでした',
    );
    return '$_temp0';
  }

  @override
  String get archiveBulkScopeNote =>
      '各プロジェクトはそれぞれに合った範囲でアーカイブされます。専用のフォルダーがあればフォルダー全体、フォルダーを共有している場合はプロジェクトファイルのみです。';

  @override
  String get archivedWithLocalCopy => 'アーカイブ済み — 元のファイルはまだここにあります';

  @override
  String get archivedAwayTooltip => 'アーカイブ済み — ファイルはアーカイブ内にのみあります';

  @override
  String get archiveUndone => 'アーカイブを取り消しました';

  @override
  String archiveUndoFailed(String error) {
    return 'アーカイブを取り消せませんでした: $error';
  }

  @override
  String get moveUndone => '移動を取り消しました';

  @override
  String moveUndoFailed(String error) {
    return '移動を取り消せませんでした: $error';
  }

  @override
  String get restoreToOriginalLocation => '元の場所に戻す';

  @override
  String get restoreToChosenFolder => '別のフォルダーへ…';

  @override
  String get restoreWhereTo => 'どこに配置しますか？';

  @override
  String get restoreOriginalLocationOccupied => '元の場所には既に何かがあります';

  @override
  String get discardArchiveButtonLabel => 'アーカイブを破棄';

  @override
  String get discardArchiveConfirmTitle => 'アーカイブを破棄しますか？';

  @override
  String get discardArchiveConfirmMessage =>
      'zip を削除し、アーカイブ済みの印を外します。プロジェクト自体のファイルはそのまま残ります。';

  @override
  String get discardArchiveDone => 'アーカイブを破棄しました';
}
