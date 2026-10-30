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
      '詳細スキャンは、プロジェクトファイルから完全なメタデータを抽出します：\n• BPM（1分あたりのビート数）\n• 音楽キー\n• DAWバージョン\n• プロジェクトノート（対応DAWのみ）\n• トラック、プラグイン、MIDIクリップ（対応DAWのみ）\n\n通常のスキャンより時間がかかります。続行しますか？';

  @override
  String get deepScanViewSupportedDaws => '対応DAWとフィールドを見る';

  @override
  String get deepScanOnlyUnscanned => 'まだ完全に読み込まれていないプロジェクトのみスキャン';

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
  String get metadataFieldMidiEvents => 'MIDIコントローラー/ピッチベンド';

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
  String get viewModeTable => 'テーブル表示';

  @override
  String get viewModeCards => 'カード表示';

  @override
  String get selectProject => 'プロジェクトを選択';

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
  String projectsHidden(int count) {
    return '$countプロジェクトを非表示にしました。';
  }

  @override
  String projectsUnhidden(int count) {
    return '$countプロジェクトを表示しました。';
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
  String deleteMissingProjectsConfirm(int count) {
    return 'このマシンでファイルが見つからなかった$count件のプロジェクトは「最近削除した項目」（設定 > プロジェクトフォルダ）に移動し、30日間はメモ、締切、セッション履歴ごと復元できます。';
  }

  @override
  String get deleteMissingProjectsConfirmButton => '削除';

  @override
  String missingProjectsDeleted(int count) {
    return '見つからないプロジェクトを$count件削除しました。';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(int count) {
    return 'リリースの一部である$count件のプロジェクトも削除する（そのリリースからも削除されます）';
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
  String metadataExtractedForProjects(int count, String failures) {
    return '$countプロジェクトのメタデータを抽出しました。$failures';
  }

  @override
  String extractionFailures(int count) {
    return '$count件失敗しました。';
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
  String scanComplete(String type, int count) {
    return '$type完了: $countプロジェクトを追加/更新しました。';
  }

  @override
  String get scanCancelled => 'スキャンをキャンセルしました。';

  @override
  String scanFailuresSnackbar(int count) {
    return '$count件のプロジェクトを読み込めませんでした。';
  }

  @override
  String get scanFailuresSnackbarAction => '詳細';

  @override
  String get scanFailuresDialogTitle => 'スキャンエラー';

  @override
  String get scanFailuresDialogIntro =>
      'スキャン中にこれらのファイルを読み取れませんでした（削除、移動、または他のプログラムによってロックされている可能性があります）：';

  @override
  String projectsSelected(int count) {
    return '$countプロジェクトを選択しました';
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
  String releasesSelected(int count) {
    return '$count件のリリースを選択しました';
  }

  @override
  String get deleteSelectedReleases => '選択項目を削除';

  @override
  String deleteSelectedReleasesConfirm(int count) {
    return '$count件のリリースを削除してもよろしいですか?';
  }

  @override
  String releasesDeleted(int count) {
    return '$count件のリリースを削除しました';
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
  String addedTracksToRelease(int count) {
    return 'リリースに$countトラックを追加しました。';
  }

  @override
  String releaseFilesCount(int count) {
    return 'リリースファイル（$count）';
  }

  @override
  String get addFiles => 'ファイルを追加';

  @override
  String addedFilesToRelease(int count) {
    return 'リリースに$countファイルを追加しました。';
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
  String selectTracksToInclude(int count) {
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
  String templatesSelected(int count) {
    return '$count件のテンプレートを選択しました';
  }

  @override
  String get deleteSelectedTemplates => '選択項目を削除';

  @override
  String deleteSelectedTemplatesConfirm(int count) {
    return '$count件のテンプレートを削除してもよろしいですか?';
  }

  @override
  String templatesDeleted(int count) {
    return '$count件のテンプレートを削除しました';
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
  String statusChangedForProjects(int count, String status) {
    return '$count プロジェクトのフェーズを「$status」に変更しました';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    int failCount,
    String status,
  ) {
    return '$successCount プロジェクトのフェーズを「$status」に変更しましたが、$failCount 件が失敗しました';
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
  String get importLaunchCommandsTitle => '「DAWで起動」のプログラムをインポートしますか？';

  @override
  String get importLaunchCommandsMessage =>
      'このバックアップには、このコンピューターで「DAWで起動」が実行するプログラムが含まれています。自分で作成したバックアップの場合にのみインポートしてください。';

  @override
  String get importLaunchCommandsSkip => 'インポートしない';

  @override
  String get importLaunchCommandsImport => 'インポートする';

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
  String dateYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count年前',
    );
    return '$_temp0';
  }

  @override
  String ageYearsMonths(int years, int months) {
    return '$years年$monthsヶ月';
  }

  @override
  String ageYears(int years) {
    return '$years年';
  }

  @override
  String ageMonthsDays(int months, int days) {
    return '$monthsヶ月$days日';
  }

  @override
  String ageMonths(int months) {
    return '$monthsヶ月';
  }

  @override
  String ageDays(int days) {
    return '$days日';
  }

  @override
  String ageHours(int hours) {
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
  String get pressKitFile => 'プレスキットのファイル';

  @override
  String get saveFileDialogTitle => 'ファイルを保存';

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
  String downloadNFiles(int count) {
    return '$count個のファイルをダウンロード';
  }

  @override
  String nFilesSavedTo(int count, String filename) {
    return '$count個のファイルを $filename に保存しました';
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
  String get trayBackupNow => '今すぐ同期';

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
  String get sortByDeadline => '締め切り';

  @override
  String get sortByLabel => '並び替え';

  @override
  String get cardInitialsTitle => 'カードの文字';

  @override
  String get cardInitialsDescription => 'カバーアートがないときにカードに表示される文字です。';

  @override
  String get cardInitialsEmptyHint => '空欄にすると名前の頭文字を使います。';

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
  String byLabel(String label) {
    return '$label 制作';
  }

  @override
  String get latestCaptureTitle => '最新のキャプチャ';

  @override
  String get latestCaptureExplanation => 'DAWプラグインが最後に録音した再生';

  @override
  String latestCaptureDetails(String when, String length) {
    return '$when · $length';
  }

  @override
  String get latestCaptureUseAsPreview => 'プレビュー曲として使う';

  @override
  String get latestCaptureNotOnThisDevice => 'まだこのデバイスにありません';

  @override
  String get latestCapturePlay => '最新のキャプチャを再生';

  @override
  String get latestCaptureMenuHint => '右クリックで最新のキャプチャを再生';

  @override
  String get latestCaptureNowPreview => '最新のキャプチャをプレビュー曲にしました';

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
  String get relocateFolderAction => '移動';

  @override
  String get relocateFolderConfirmBody =>
      'このフォルダのプロジェクトを新しいフォルダで探し、メモ、TODO、作業時間などはすべてそのまま残ります。ディスク上では何もコピー・移動されません。';

  @override
  String get relocateFolderFrom => '移動元';

  @override
  String get relocateFolderTo => '移動先';

  @override
  String relocateFolderFound(int found, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total件中$found件のプロジェクトが新しいフォルダにあります。',
    );
    return '$_temp0';
  }

  @override
  String get relocateFolderSomeMissing =>
      '残りはファイルが揃うまで「見つからない」と表示されます。それまで「見つからない項目を削除」は使わないでください。';

  @override
  String get relocateFolderNoneFound =>
      'まだ1件もありません。ファイルをダウンロード中なら問題ありません。そうでなければ、上や下の階層ではなくそのフォルダ自体を選んだか確認してください。';

  @override
  String relocateFolderOverlapsOwn(String path) {
    return '$path はすでにこのプロフィールのプロジェクトフォルダか、それと重なっています。別のフォルダを選ぶか、先にそちらを削除してください。';
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
  String get updateWindowsInstallerSourceLabel => 'Windows インストーラー';

  @override
  String get updateWindowsInstallerInstructions =>
      '新しいインストーラーをダウンロードして実行してください。このインストールをそのまま更新し、ライブラリはそのまま残ります。';

  @override
  String get updateDownloadInstaller => 'インストーラーをダウンロード';

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
  String get onboardingWelcomeBody => 'すべてのプロジェクト、すべてのDAWを、ひとつの場所に。';

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
  String get onboardingDetailLayoutTitle => 'プロジェクトページ';

  @override
  String get onboardingDetailLayoutBody =>
      'プロジェクトのページの構成方法です。ページ上部のボタンでいつでも切り替えられます。';

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
  String get todoDueDate => '期限';

  @override
  String get todoSetDueDate => '期限を設定';

  @override
  String get todoClearDueDate => '期限を削除';

  @override
  String get todoNoDueDate => '期限なし';

  @override
  String get todoDueToday => '今日が期限';

  @override
  String get todoDueTomorrow => '明日が期限';

  @override
  String todoDueOn(String date) {
    return '期限 $date';
  }

  @override
  String todoOverdueByDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days日超過',
    );
    return '$_temp0';
  }

  @override
  String get queueDueFilterLabel => '期限';

  @override
  String get queueDueFilterAll => 'すべてのタスク';

  @override
  String get queueDueFilterOverdue => '期限切れ';

  @override
  String get queueDueFilterToday => '今日が期限';

  @override
  String get queueDueFilterThisWeek => '今週が期限';

  @override
  String get queueDueFilterNoDate => '期限なし';

  @override
  String get queueNoTasksForDueFilter => 'この期限フィルターに一致するタスクはありません';

  @override
  String get projectAttachments => '添付';

  @override
  String get attachmentAddFile => 'ファイルを追加';

  @override
  String get attachmentAddLink => 'リンクを追加';

  @override
  String get attachmentsEmptyTitle => 'まだ何も添付されていません';

  @override
  String get attachmentsEmptyDescription =>
      'リファレンス曲、ステム納品リンク、歌詞、契約書をチャットではなく曲と一緒に保管できます。';

  @override
  String get attachmentEditDialogTitle => '添付を編集';

  @override
  String get attachmentUrlLabel => 'URL';

  @override
  String get attachmentPathLabel => 'ファイルパス';

  @override
  String get attachmentLabelLabel => 'ラベル（任意）';

  @override
  String get attachmentNoteLabel => 'メモ（任意）';

  @override
  String get attachmentUrlInvalid => '有効なリンクを入力してください（例: https://example.com）';

  @override
  String get attachmentPathRequired => 'ファイルパスを入力してください';

  @override
  String get attachmentOpenTooltip => '開く';

  @override
  String get attachmentRemoveTitle => '添付を削除';

  @override
  String attachmentRemoveMessage(String label) {
    return 'このプロジェクトから「$label」を削除しますか？ファイル自体は削除されません。';
  }

  @override
  String get attachmentRemoved => '添付を削除しました';

  @override
  String get attachmentAdded => '添付を追加しました';

  @override
  String get attachmentOpenFailed => 'この添付を開けませんでした';

  @override
  String get attachmentPickFileTitle => '添付するファイルを選択';

  @override
  String get attachmentAlreadyAdded => 'すでにこのプロジェクトに添付されています';

  @override
  String get attachmentExport => '書き出し';

  @override
  String get attachmentExportTooltip => '添付ファイルとリンクを保存';

  @override
  String get attachmentExportNothing => '書き出すものがありません';

  @override
  String get attachmentExporting => '添付を書き出しています...';

  @override
  String attachmentExportSaved(String path) {
    return '保存先: $path';
  }

  @override
  String attachmentExportSkippedMissing(int count) {
    return '見つからないファイル $count 件をスキップしました';
  }

  @override
  String attachmentExportFailed(String error) {
    return '添付の書き出しに失敗しました: $error';
  }

  @override
  String get projectAppearance => '外観';

  @override
  String get projectAppearanceTooltip => 'カバーアート・色・アイコンを変更';

  @override
  String get projectCoverArt => 'カバーアート';

  @override
  String get chooseCoverArt => '画像を選択…';

  @override
  String get replaceCoverArt => '画像を変更…';

  @override
  String get removeCoverArt => 'カバーアートを削除';

  @override
  String get removeCoverArtConfirm => 'このプロジェクトのカバーアートを削除しますか？保存された画像は削除されます。';

  @override
  String get coverArtRemoved => 'カバーアートを削除しました';

  @override
  String failedToRemoveCoverArt(String error) {
    return 'カバーアートの削除に失敗しました: $error';
  }

  @override
  String get projectAccentColor => 'アクセントカラー';

  @override
  String get projectIcon => 'アイコン';

  @override
  String get appearanceNone => 'なし';

  @override
  String get appearanceNoneHint =>
      '色とアイコンは選ぶまで表示されません。選択中のアイコンをもう一度タップすると解除できます。';

  @override
  String get clearColorAndIcon => '色とアイコンを解除';

  @override
  String get dropCoverArtHere => '画像をドロップしてカバーアートに設定';

  @override
  String get uploadingProjectCoverArt => 'プロジェクトのカバーアートをアップロード中...';

  @override
  String get downloadingProjectCoverArt => 'プロジェクトのカバーアートをダウンロード中...';

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

  @override
  String get whatsNewTitle => '新着情報';

  @override
  String whatsNewTitleWithVersion(String version) {
    return 'バージョン $version の新着情報';
  }

  @override
  String get whatsNewIntro => '前のバージョンからの変更点です。';

  @override
  String get whatsNewGotIt => 'OK';

  @override
  String get changelogFullButton => '全変更履歴';

  @override
  String get changelogPageTitle => '変更履歴';

  @override
  String get changelogEmpty => 'このビルドの変更履歴はありません。';

  @override
  String get changelogCurrentVersionBadge => 'インストール済み';

  @override
  String get disableProjectFolderTooltip => 'このフォルダーを無効にする（プロジェクトは保持）';

  @override
  String get enableProjectFolderTooltip => 'このフォルダーを有効にする';

  @override
  String get projectFolderDisabledBadge => '無効';

  @override
  String get projectFolderDisabledExplanation =>
      'スキャンされず、プロジェクトは非表示になります。削除はされていません。有効にすると元に戻ります。';

  @override
  String projectFolderEnabled(String name) {
    return '「$name」のスキャンを再開しました';
  }

  @override
  String projectFolderDisabled(String name) {
    return '「$name」を無効にしました。プロジェクトは非表示になるだけで削除されません';
  }

  @override
  String get releaseArtworkCarryOverTitle => 'トラックのカバーアートを使いますか？';

  @override
  String releaseArtworkCarryOverBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '選択したトラックのうち $count 件にカバーアートがあります。このリリースのアートワークに使うものを選んでください。',
    );
    return '$_temp0';
  }

  @override
  String get releaseArtworkCarryOverUse => 'アートワークに使う';

  @override
  String get releaseArtworkCarryOverSkip => 'アートワークなし';

  @override
  String get tracksViewList => 'リスト表示';

  @override
  String get tracksViewTable => 'テーブル表示';

  @override
  String get partsColumn => 'パート';

  @override
  String partsNeededCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未録音のパートが $count 件',
    );
    return '$_temp0';
  }

  @override
  String get songLength => '長さ';

  @override
  String get songLengthColumn => '長さ';

  @override
  String get songLengthHint => '3:45';

  @override
  String get songLengthManual => '手入力です。空にするとプレビュー曲の長さを使います';

  @override
  String get songLengthFromPreview => 'プレビュー曲から計測しました';

  @override
  String releaseLengthAtLeast(String total) {
    return '$total+';
  }

  @override
  String get releaseLengthComplete => '合計時間';

  @override
  String releaseLengthPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '暫定の合計 — 長さ未設定のトラックが $count 件',
    );
    return '$_temp0';
  }

  @override
  String get breadcrumbHome => 'ホーム';

  @override
  String breadcrumbGoTo(String label) {
    return '$label へ移動';
  }

  @override
  String get scrollForMore => 'スクロールするとさらに表示';

  @override
  String get shortcutPlayerMono => 'モノラル再生の切り替え';

  @override
  String get shortcutPlayerVolume => '音量を調整';

  @override
  String get shortcutMouseWheel => 'ホイール';

  @override
  String get releaseTotalLengthLabel => '合計の長さ';

  @override
  String get releaseLengthNone =>
      '長さが設定されたトラックはまだありません。トラックを再生するか、プロジェクトページで長さを入力してください';

  @override
  String get songLengthHowItWorks =>
      'プレビュー曲から自動で入力されます（再生したとき、またはこのトラックを含むリリースを開いたとき）。手入力も可能です：3:45、1:02:03、または秒数。';

  @override
  String get changelogSectionSubtitle => '各バージョンの変更点（新しい順）。';

  @override
  String get changelogSearchHint => '変更履歴を検索';

  @override
  String changelogNoMatches(String query) {
    return '「$query」に一致する変更はありません';
  }

  @override
  String get projectFileMenu => 'ファイル';

  @override
  String get moreActions => 'その他の操作';

  @override
  String get sectionRailResizeHint => 'ドラッグで幅を変更 · ダブルクリックで元に戻す';

  @override
  String get stackMetadataCoverArtLabel => 'カバーアート';

  @override
  String get stackMetadataColorLabel => 'アクセントカラー';

  @override
  String get stackMetadataIconLabel => 'アイコン';

  @override
  String get projectTags => 'タグ';

  @override
  String get filterByTag => 'タグで絞り込み';

  @override
  String get allTags => 'すべてのタグ';

  @override
  String get addTagHint => 'タグを追加…';

  @override
  String get tagsHelper =>
      'Enter キーで追加します。ジャンル、ムード、クライアント、絵文字など、絞り込みに使いたいものを自由に。';

  @override
  String removeTagTooltip(String tag) {
    return 'タグ「$tag」を削除';
  }

  @override
  String filterByThisTagTooltip(String tag) {
    return 'タグ「$tag」のプロジェクトだけを表示';
  }

  @override
  String get sortByTags => 'タグ';

  @override
  String get bulkTagsButton => 'タグ';

  @override
  String bulkTagsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクトにタグ付け',
    );
    return '$_temp0';
  }

  @override
  String get bulkTagsAddLabel => '選択したすべてのプロジェクトにタグを追加';

  @override
  String get bulkTagsRemoveLabel => '選択からタグを削除';

  @override
  String get bulkTagsNoneToRemove => '選択したプロジェクトにはまだタグがありません。';

  @override
  String bulkTagsUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクトを更新しました',
      zero: '変更はありません',
    );
    return '$_temp0';
  }

  @override
  String stackMetadataTagsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'タグ $count 個',
    );
    return '$_temp0';
  }

  @override
  String projectExportTagsLabel(String tags) {
    return 'タグ: $tags';
  }

  @override
  String get enableTags => 'タグを有効にする';

  @override
  String get tagsSettingDescription =>
      'プロジェクトに独自のタグを付けて、絞り込み・検索・並べ替えに使えます。オフにしても非表示になるだけで、追加済みのタグは保持されます。';

  @override
  String get projectContentsTitle => 'プロジェクトの内容';

  @override
  String get projectStatsTracks => 'トラック';

  @override
  String get projectStatsAudio => 'オーディオ';

  @override
  String get projectStatsMidi => 'MIDI';

  @override
  String get projectStatsInstrument => 'インストゥルメント';

  @override
  String get projectStatsSampler => 'サンプラー';

  @override
  String get projectStatsBus => 'グループ & FX';

  @override
  String get projectStatsFolder => 'フォルダ';

  @override
  String get projectStatsPlugins => 'プラグイン';

  @override
  String get midiClipsTitle => 'MIDIクリップ';

  @override
  String get midiClipsLoad => 'MIDIクリップを読み込む';

  @override
  String get midiClipsLoadHint =>
      'プロジェクトファイルから読み込んでプロジェクトと一緒に保存し、他のデバイスにも同期します。';

  @override
  String get midiClipsLoading => 'プロジェクトファイルを読み込み中…';

  @override
  String get midiClipsNone => 'このプロジェクトにはノートを含むMIDIクリップがありません。';

  @override
  String midiClipsError(String error) {
    return 'MIDIクリップを読み込めませんでした: $error';
  }

  @override
  String get midiClipPlay => 'シンプルなシンセでプレビュー';

  @override
  String get midiClipStop => 'プレビューを停止';

  @override
  String get midiClipSave => 'MIDIファイルとして保存';

  @override
  String get midiClipsExportAll => 'すべてMIDIとして書き出す…';

  @override
  String midiClipsExported(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のMIDIファイルを$folderに保存しました',
    );
    return '$_temp0';
  }

  @override
  String midiClipSaved(String fileName) {
    return '$fileName を保存しました';
  }

  @override
  String get midiClipDragTooltip => 'DAWやフォルダにドラッグ';

  @override
  String midiClipBars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count小節',
    );
    return '$_temp0';
  }

  @override
  String midiClipNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countノート',
    );
    return '$_temp0';
  }

  @override
  String midiClipUsedTimes(int count) {
    return '$count回使用';
  }

  @override
  String midiClipPreviewFailed(String error) {
    return 'プレビューを再生できませんでした: $error';
  }

  @override
  String midiClipSaveFailed(String error) {
    return 'MIDIファイルを保存できませんでした: $error';
  }

  @override
  String get midiClipsExportFolderTitle => 'MIDIファイルの保存先フォルダを選択';

  @override
  String midiClipAlsoAs(String names) {
    return '同じ内容: $names';
  }

  @override
  String get midiClipsNoTrack => 'その他のクリップ';

  @override
  String get midiClipsExpandTrack => 'このトラックのクリップを表示';

  @override
  String get midiClipsCollapseTrack => 'このトラックのクリップを隠す';

  @override
  String get midiTempoTooltip => 'プレビューと保存するMIDIファイルのテンポ';

  @override
  String get midiTempoSlower => '遅く';

  @override
  String get midiTempoFaster => '速く';

  @override
  String midiTempoReset(String bpm) {
    return 'プロジェクトのテンポに戻す ($bpm BPM)';
  }

  @override
  String get midiClipShare => '共有';

  @override
  String get midiClipsShareAll => 'すべて共有';

  @override
  String midiClipShareText(String clip, String project) {
    return '$project のMIDIクリップ「$clip」';
  }

  @override
  String midiClipsShareAllText(String project) {
    return '$project のMIDIクリップ';
  }

  @override
  String get midiClipsShareFallback =>
      'ここでは共有を利用できないため、ファイルを開いたフォルダに置きました。チャットアプリにドラッグしてください。';

  @override
  String midiClipShareFailed(String error) {
    return '共有できませんでした: $error';
  }

  @override
  String get midiClipsRefresh => 'プロジェクトファイルから再読み込み';

  @override
  String get midiClipsStale => 'これらのクリップを読み込んだ後にプロジェクトファイルが変更されました。';

  @override
  String get midiClipsNoneStored =>
      'このプロジェクトのMIDIクリップはまだ保存されていません。プロジェクトファイルのあるコンピューターでメタデータを抽出してください。';

  @override
  String midiClipInstrumentTooltip(String name) {
    return '楽器: $name';
  }

  @override
  String get synthVoiceLead => 'リード';

  @override
  String get synthVoiceBass => 'ベース';

  @override
  String get synthVoicePad => 'パッド';

  @override
  String get synthVoicePluck => 'プラック';

  @override
  String get synthVoiceKeys => 'キーボード';

  @override
  String get synthVoiceOrgan => 'オルガン';

  @override
  String get synthVoiceStrings => 'ストリングス';

  @override
  String get synthVoiceBrass => 'ブラス';

  @override
  String get synthVoiceBell => 'ベル';

  @override
  String get synthVoiceDrumKit => 'ドラムキット';

  @override
  String get synthVoiceKick => 'キック';

  @override
  String get synthVoiceSnare => 'スネア';

  @override
  String get synthVoiceClap => 'クラップ';

  @override
  String get synthVoiceHiHat => 'ハイハット';

  @override
  String get synthVoicePercussion => 'パーカッション';

  @override
  String get midiLibraryTab => 'MIDI';

  @override
  String get midiLibrarySearchHint => 'MIDIクリップを検索';

  @override
  String get midiLibraryAllClips => 'すべてのクリップ';

  @override
  String get midiCollectionsTitle => 'コレクション';

  @override
  String get midiCollectionNew => '新しいコレクション';

  @override
  String get midiCollectionNameHint => 'コレクション名';

  @override
  String get midiCollectionCreate => '作成';

  @override
  String get midiCollectionRename => '名前を変更';

  @override
  String get midiCollectionDelete => 'コレクションを削除';

  @override
  String midiCollectionDeleteConfirm(String name) {
    return '「$name」を削除しますか？クリップはコピーなので、元のプロジェクトには影響しません。';
  }

  @override
  String get midiCollectionAddTo => 'コレクションに追加';

  @override
  String get midiCollectionRemoveFrom => 'コレクションから削除';

  @override
  String midiCollectionAdded(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name に追加しました',
    );
    return '$_temp0';
  }

  @override
  String midiCollectionAlreadyIn(String name) {
    return 'すでに $name にあります';
  }

  @override
  String midiCollectionRemoved(String clip, String name) {
    return '$clip を $name から削除しました';
  }

  @override
  String get midiCollectionEmpty =>
      'このコレクションは空です。「すべてのクリップ」やプロジェクトのページからクリップを追加してください。';

  @override
  String midiCollectionShareText(String name) {
    return 'MIDIコレクション「$name」';
  }

  @override
  String get midiLibraryEmpty =>
      'MIDIクリップはまだありません。プロジェクトのメタデータを抽出するとクリップを読み込みます。';

  @override
  String get midiLibraryNoMatches => '一致するクリップはありません。';

  @override
  String get midiLibraryAllInstruments => 'すべての楽器';

  @override
  String get midiClipMoreActions => 'その他';

  @override
  String get midiTempoAuto => '自動';

  @override
  String get midiTempoResetAuto => '各クリップ本来のテンポに戻す';

  @override
  String get releaseTracksResizeHint => 'ドラッグでサイズ変更 · ダブルクリックでリセット';

  @override
  String get releaseTracksMaximize => 'トラックリスト全体を表示';

  @override
  String get releaseTracksRestoreFiles => 'ファイルパネルを再表示';

  @override
  String get columnsAndFieldsTabLabel => '列とフィールド';

  @override
  String get projectsTableColumnsTitle => '表の列';

  @override
  String get projectsTableColumnsDescription =>
      'プロジェクト表とリリースのトラックリストに表示する列を選び、ドラッグして並べ替えます（並び順は両方に適用されます）。名前と操作は常に表示されます。このデバイスのみに適用されます。';

  @override
  String get customFieldsTitle => 'カスタムフィールド';

  @override
  String get customFieldsDescription =>
      'すべてのプロジェクトに独自のフィールドを追加できます（ラウドネス（LUFS）、マスタリングエンジニア、ISRC など）。フィールドは常にプロジェクトページで入力でき、プロジェクト表やリリースのトラックリストに列として表示するかも選べます。';

  @override
  String get addCustomField => 'フィールドを追加';

  @override
  String get editCustomField => 'フィールドを編集';

  @override
  String get customFieldName => 'フィールド名';

  @override
  String get customFieldNameHint => '例: LUFS';

  @override
  String get customFieldNameRequired => '名前を入力してください';

  @override
  String get customFieldNameDuplicate => 'この名前のフィールドは既に存在します';

  @override
  String get customFieldType => '種類';

  @override
  String get customFieldTypeText => 'テキスト';

  @override
  String get customFieldTypeNumber => '数値';

  @override
  String get customFieldTypeNumberHelp => '数値は値で並べ替えられます（-9.8 は -14.2 の後）。';

  @override
  String get customFieldShowInProjectsTable => 'プロジェクト表に列を表示';

  @override
  String get customFieldShowInReleaseTracks => 'リリースのトラックリストに列を表示';

  @override
  String get customFieldProjectPageOnly => 'プロジェクトページのみ';

  @override
  String get noCustomFieldsYet => 'カスタムフィールドはまだありません。';

  @override
  String get deleteCustomFieldTitle => 'フィールドを削除しますか？';

  @override
  String deleteCustomFieldMessage(String name) {
    return '「$name」と入力済みの値は、プロジェクト・表・検索に表示されなくなります。';
  }

  @override
  String get customFieldInvalidNumber => '数値を入力してください';

  @override
  String get customFieldsProjectPageHint =>
      '独自のフィールドです。設定 > 列とフィールド で追加・変更できます。';

  @override
  String get midiPianoRollOpen => 'ピアノロールを開く';

  @override
  String get midiPianoRollZoomIn => 'ズームイン';

  @override
  String get midiPianoRollZoomOut => 'ズームアウト';

  @override
  String get midiPianoRollFit => 'ウィンドウに合わせる';

  @override
  String get midiPianoRollFollow => '再生位置を追従';

  @override
  String get midiClipsShareOfferFolder =>
      '共有ウィンドウが表示されなかった場合、ファイルはフォルダに用意されています。';

  @override
  String get midiClipsShowInFolder => 'フォルダで表示';

  @override
  String get midiPianoRollPause => '一時停止';

  @override
  String get midiProjectDetails => 'プロジェクトの詳細';

  @override
  String get midiSourceProjectGone => 'このクリップの元のプロジェクトはライブラリにありません。';

  @override
  String get midiCollectionShareZip => 'ZIPで共有';

  @override
  String get midiCollectionOpen => '開く';

  @override
  String get midiPreviewVolume => 'プレビュー音量';

  @override
  String get midiLanePicker => 'ノートの下に表示するパラメーター';

  @override
  String get midiLaneNone => 'なし';

  @override
  String get midiLaneVelocity => 'ベロシティ';

  @override
  String get midiLanePitchBend => 'ピッチベンド';

  @override
  String get midiLaneChannelPressure => 'アフタータッチ';

  @override
  String get midiLanePolyPressure => 'ポリ・アフタータッチ';

  @override
  String get midiLaneProgram => 'プログラムチェンジ';

  @override
  String midiLaneController(int number) {
    return 'CC $number';
  }

  @override
  String midiLaneControllerNamed(int number, String name) {
    return 'CC $number · $name';
  }

  @override
  String get midiCcModulation => 'モジュレーション';

  @override
  String get midiCcBreath => 'ブレス';

  @override
  String get midiCcFoot => 'フットペダル';

  @override
  String get midiCcPortamentoTime => 'ポルタメントタイム';

  @override
  String get midiCcVolume => 'ボリューム';

  @override
  String get midiCcBalance => 'バランス';

  @override
  String get midiCcPan => 'パン';

  @override
  String get midiCcExpression => 'エクスプレッション';

  @override
  String get midiCcSustain => 'サステインペダル';

  @override
  String get midiCcPortamento => 'ポルタメント';

  @override
  String get midiCcSostenuto => 'ソステヌート';

  @override
  String get midiCcSoftPedal => 'ソフトペダル';

  @override
  String get midiCcResonance => 'レゾナンス';

  @override
  String get midiCcRelease => 'リリース';

  @override
  String get midiCcAttack => 'アタック';

  @override
  String get midiCcCutoff => 'カットオフ';

  @override
  String get midiCcReverb => 'リバーブ';

  @override
  String get midiCcChorus => 'コーラス';

  @override
  String get filterHasMidi => 'MIDIを含むプロジェクトのみ';

  @override
  String midiClipsMissingFiles(int count, String files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '参照されている MIDI ファイル $count 個が見つからないか読み込めません: $files',
    );
    return '$_temp0';
  }

  @override
  String get midiLibraryArrangeProject => 'プロジェクト別';

  @override
  String get midiLibraryArrangeAdded => '追加順';

  @override
  String get midiLibraryArrangeTempo => 'テンポ (BPM) 別';

  @override
  String midiLibraryTempoGroup(String bpm) {
    return '$bpm BPM';
  }

  @override
  String get midiLibraryTempoUnknown => 'テンポ不明';

  @override
  String get midiImportFiles => 'MIDI ファイルを読み込む';

  @override
  String get midiImportDialogTitle => '読み込む MIDI ファイルを選択';

  @override
  String midiImportSkipped(String files) {
    return '読み込めませんでした (MIDI ファイルではないか、ノートがありません): $files';
  }

  @override
  String get midiPreviewLoop => 'ループ再生';

  @override
  String get columnsInProjectsTable => 'プロジェクト';

  @override
  String get columnsInReleaseTracks => 'リリースのトラック';

  @override
  String get projectContentsRead => 'プロジェクトの内容を読み込む';

  @override
  String get projectContentsReadHint =>
      'プロジェクトファイルからトラック、プラグイン、MIDIクリップを読み込みます。プロジェクトと一緒に保存され、他のデバイスにも同期されます。';

  @override
  String get projectContentsNoneRead =>
      'このプロジェクトからはまだ何も読み込まれていません。プロジェクトファイルのあるコンピューターで詳細スキャンを実行するか、メタデータを抽出してください。';

  @override
  String get midiScale => 'スケール';

  @override
  String get midiScaleNone => 'スケールなし';

  @override
  String get midiScaleRoot => 'ルート';

  @override
  String get midiScaleType => 'スケールの種類';

  @override
  String get scaleMajor => 'メジャー';

  @override
  String get scaleMinor => 'マイナー';

  @override
  String get scaleHarmonicMinor => 'ハーモニック・マイナー';

  @override
  String get scaleMelodicMinor => 'メロディック・マイナー';

  @override
  String get scaleDorian => 'ドリアン';

  @override
  String get scalePhrygian => 'フリジアン';

  @override
  String get scaleLydian => 'リディアン';

  @override
  String get scaleMixolydian => 'ミクソリディアン';

  @override
  String get scaleLocrian => 'ロクリアン';

  @override
  String get scaleMajorPentatonic => 'メジャー・ペンタトニック';

  @override
  String get scaleMinorPentatonic => 'マイナー・ペンタトニック';

  @override
  String get scaleBlues => 'ブルース';

  @override
  String get midiEditNotes => 'ノートを編集';

  @override
  String get midiUndo => '元に戻す';

  @override
  String get midiRedo => 'やり直す';

  @override
  String get midiSnap => 'グリッドにスナップ';

  @override
  String get midiSnapOff => 'オフ';

  @override
  String get midiSaveAsNewClip => '新しいクリップとして保存';

  @override
  String midiClipEditedName(String name) {
    return '$name（編集済み）';
  }

  @override
  String get midiDiscardEditsTitle => '変更を破棄しますか？';

  @override
  String get midiDiscardEditsBody =>
      '編集したクリップは保存されていません。残すには新しいクリップとして保存してください。';

  @override
  String get midiKeepEditing => '編集を続ける';

  @override
  String get midiDiscardEdits => '破棄';

  @override
  String get midiToolSelect => '選択 (1)';

  @override
  String get midiToolPencil => '鉛筆 (8)';

  @override
  String get midiAcousticFeedback => '編集中のノートを鳴らす';

  @override
  String get midiShortcuts => 'キーボードショートカット (?)';

  @override
  String get midiShortcutsTitle => 'ピアノロールのショートカット';

  @override
  String get midiShortcutsTools => 'ツール';

  @override
  String get midiShortcutsNotes => 'ノート';

  @override
  String get midiShortcutsSelecting => '選択';

  @override
  String get midiShortcutsLanes => 'ベロシティとコントローラーのレーン';

  @override
  String get midiShortcutsEditing => '編集';

  @override
  String get midiShortcutsPlayback => '再生と表示';

  @override
  String get midiKeyCtrl => 'Ctrl';

  @override
  String get midiKeyShift => 'Shift';

  @override
  String get midiKeyAlt => 'Alt';

  @override
  String get midiKeyDelete => 'Delete';

  @override
  String get midiKeySpace => 'スペース';

  @override
  String get midiKeyEsc => 'Esc';

  @override
  String get midiGestureClick => 'クリック';

  @override
  String get midiGestureDoubleClick => 'ダブルクリック';

  @override
  String get midiGestureDrag => 'ドラッグ';

  @override
  String get midiGesturePen => 'ペン';

  @override
  String get midiGestureWheel => 'ホイール';

  @override
  String get midiShortcutSelectTool => '選択ツール';

  @override
  String get midiShortcutPencilTool =>
      '鉛筆：クリックでノートを追加。横にドラッグで長く、上下でベロシティ。ノートをクリックすると選択';

  @override
  String get midiShortcutPenPressure => 'ペンで描く：強く押すほどベロシティが上がります';

  @override
  String get midiShortcutDoubleClick =>
      '空いている所：ノートを追加（押したままドラッグ：横で長さ、上下でベロシティ、Ctrl でグリッド無視）。ノートの上：削除';

  @override
  String get midiShortcutMove => 'ノート：選択中のノートごと移動';

  @override
  String get midiShortcutResize => 'ノートの端：短く・長くする';

  @override
  String get midiShortcutCopy => 'ノート：選択中のノートをコピー';

  @override
  String get midiShortcutOffGrid => 'グリッドに合わせずに移動・長さ変更';

  @override
  String get midiShortcutSemitone => '選択中のノートを半音移動';

  @override
  String get midiShortcutOctave => '選択中のノートを1オクターブ移動';

  @override
  String get midiShortcutDelete => '選択中のノートを削除';

  @override
  String get midiShortcutBox => '空いている所：枠内のノートを選択';

  @override
  String get midiShortcutToggle => 'ノートを選択に追加、または選択から外す';

  @override
  String get midiShortcutSelectAll => 'すべてのノートを選択';

  @override
  String get midiShortcutVelocity => 'ベロシティのバーの上：通ったノートすべてのベロシティを設定';

  @override
  String get midiShortcutLane => 'コントローラーやピッチベンドのレーン：カーブを描く（ベンドは中央に吸着）';

  @override
  String get midiShortcutPlay => '再生・一時停止';

  @override
  String get midiShortcutStop => '停止。停止中ならウィンドウを閉じる';

  @override
  String get midiShortcutKeyboard => '鍵盤の上：その鍵盤を鳴らす（ドラッグで通った鍵盤を鳴らす）';

  @override
  String get midiShortcutRuler => 'ルーラーの上：その位置へ移動';

  @override
  String get midiShortcutZoom => 'マウスの位置を中心に拡大・縮小';

  @override
  String get midiShortcutScroll => '横にスクロール';

  @override
  String get midiShortcutShowSheet => 'このショートカット一覧を表示';

  @override
  String get midiFullScreen => '全画面';

  @override
  String get midiExitFullScreen => '全画面を終了';

  @override
  String get midiToolRange => '範囲 (2)';

  @override
  String get midiToolEraser => '消しゴム (5)';

  @override
  String get midiDuplicate => '複製';

  @override
  String get midiTranspose => 'トランスポーズ';

  @override
  String get midiTransposeUpSemitone => '半音上げる';

  @override
  String get midiTransposeDownSemitone => '半音下げる';

  @override
  String get midiTransposeUpOctave => '1オクターブ上げる';

  @override
  String get midiTransposeDownOctave => '1オクターブ下げる';

  @override
  String get midiShortcutRangeTool => '範囲：ドラッグして時間の区間とその中のノートをすべて選択';

  @override
  String get midiShortcutEraserTool => '消しゴム：ノートをクリックまたはドラッグでなぞって削除';

  @override
  String get midiShortcutDuplicate => '複製：範囲はその直後に、選択したノートは最後のノートの直後に';

  @override
  String get midiNewClip => '新しいクリップ';

  @override
  String midiNewClipName(int number) {
    return 'アイデア $number';
  }

  @override
  String get midiQuantize => 'クオンタイズ (Q)';

  @override
  String get midiShortcutQuantize => 'クオンタイズ：選択したノート（なければ全ノート）をグリッドに合わせる';

  @override
  String get midiTimeSignature => '拍子';

  @override
  String get midiShortcutLoopStart => 'ルーラーの上：ループの開始位置を設定';

  @override
  String get midiShortcutLoopEnd => 'ルーラーの上：ループの終了位置を設定';

  @override
  String get midiShortcutLoopDrag =>
      'ループの紫のバー：端をドラッグで長さを変更、中央をドラッグで移動（ループ再生中はその範囲だけ再生）';

  @override
  String get midiShortcutLoopToggle => 'ループのバーの上半分：ループのオン・オフ（オフの間はグレー）';

  @override
  String get midiRoleMelody => 'メロディ';

  @override
  String get midiRoleBass => 'ベース';

  @override
  String get midiRoleChords => 'コード';

  @override
  String get midiRoleArp => 'アルペジオ';

  @override
  String get midiRoleLead => 'リード';

  @override
  String get midiRolePad => 'パッド';

  @override
  String get midiRoleDrums => 'ドラム';

  @override
  String get midiRoleFx => 'FX';

  @override
  String get midiRoleOther => 'その他';

  @override
  String get midiRoleLabel => '役割';

  @override
  String midiRoleAutomatic(String role) {
    return '自動（$role）';
  }

  @override
  String midiItemRoleMenu(String role) {
    return '役割: $role';
  }

  @override
  String get midiNameFree => 'フリー';

  @override
  String get midiNamingTitle => 'ファイル名の付け方';

  @override
  String get midiNamingNumbered => 'ファイルに番号を付ける';

  @override
  String get midiNamingNumberedHint =>
      '各フォルダーの並び順で 01, 02… と付け、ファイルブラウザーでもその順に並ぶようにします';

  @override
  String get midiNamingSeparator => '区切り文字';

  @override
  String get midiNamingFields => '名前に含める項目';

  @override
  String get midiNamingFieldsHint => 'ドラッグで順序を変更';

  @override
  String get midiNameFieldName => '名前';

  @override
  String get midiNameFieldBpm => 'テンポ (BPM)';

  @override
  String get midiNameFieldKey => 'キー';

  @override
  String get midiNameFieldBars => '小節数';

  @override
  String get midiNameFieldTimeSignature => '拍子（4/4 以外のとき）';

  @override
  String get midiNameFieldGrid => 'クオンタイズ（1-16、フリー…）';

  @override
  String get midiNameFieldInstrument => '楽器';

  @override
  String get midiNamingPreview => '例';

  @override
  String get midiNamingReset => 'デフォルト';

  @override
  String get midiFolderNew => '新しいフォルダー';

  @override
  String get midiFolderRename => 'フォルダー名を変更';

  @override
  String get midiFolderDelete => 'フォルダーを削除';

  @override
  String midiFolderDeleteConfirm(String name) {
    return 'フォルダー「$name」を削除しますか？中のクリップとフォルダーは1つ上の階層に移動します。';
  }

  @override
  String get midiFolderName => 'フォルダー名';

  @override
  String get midiFolderLabel => 'フォルダー';

  @override
  String get midiFolderTopLevel => '最上位';

  @override
  String get midiMoveTo => '移動…';

  @override
  String get midiMoveUp => '上へ移動';

  @override
  String get midiMoveDown => '下へ移動';

  @override
  String get midiItemRename => '名前を変更';

  @override
  String get midiItemNameHint => '空欄: クリップ本来の名前';

  @override
  String get midiSaveClipTitle => 'クリップを保存';

  @override
  String get midiSaveFileName => 'ファイル名';

  @override
  String get midiBulkRenameMenu => 'スキームで名前を変更…';

  @override
  String get midiBulkRenameTitle => '命名スキームで名前を変更';

  @override
  String get midiBulkRenameHint =>
      '各名前はコレクションの命名スキームから提案されます。先に自由に編集でき、そのままにしたいクリップはチェックを外してください。';

  @override
  String midiBulkRenameApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のクリップの名前を変更',
    );
    return '$_temp0';
  }

  @override
  String midiBulkRenameDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のクリップの名前を変更しました',
    );
    return '$_temp0';
  }

  @override
  String get midiBulkRenameSelectAll => 'すべて';

  @override
  String get midiNameFromScheme => '命名スキームから';

  @override
  String midiCollectionMoved(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個を $name に移動しました',
    );
    return '$_temp0';
  }

  @override
  String get midiExpandAll => 'すべて展開';

  @override
  String get midiCollapseAll => 'すべて折りたたむ';

  @override
  String get templateExportTitle => 'Cubaseテンプレート用データを書き出す';

  @override
  String get templateExportSubtitle =>
      'Cubaseプロジェクトのトラック構成を読み取り、Claudeがテンプレートを作るためのtemplate.md, template-spec.md、patterns.json、corpus.jsonを生成します';

  @override
  String get templateExportAnonymize => 'corpus.jsonでプロジェクト名を隠す';

  @override
  String get templateExportButton => '書き出す';

  @override
  String get templateExportDialogTitle => 'テンプレート書き出し先のフォルダを選択';

  @override
  String templateExportDone(int analysed, int skipped) {
    return '$analysed件のプロジェクトを書き出しました（$skipped件は読み取れませんでした）';
  }

  @override
  String get templateExportNothing => '読み取れるCubaseプロジェクトが見つかりません';

  @override
  String get melodicExportTitle => 'メロディMIDIカタログを書き出す';

  @override
  String get melodicExportSubtitle =>
      'プロジェクトのリード、アルペジオ、メロディを、プロジェクトごとのフォルダに.midファイルとして保存し、テンポ、キー、音域などのカタログ（CSV、JSON、Markdown）を付けます。ドラムと短い断片は除外されます。';

  @override
  String get melodicExportIncludeChords => 'コードとパッドを含める';

  @override
  String get melodicExportIncludeBass => 'ベースラインを含める';

  @override
  String get melodicExportDialogTitle => 'MIDI書き出し先のフォルダを選択';

  @override
  String melodicExportDone(int clips, int projects) {
    return '$projects件のプロジェクトから$clips個のクリップを書き出しました';
  }

  @override
  String melodicExportDoneUnread(int clips, int projects, int unread) {
    return '$projects件のプロジェクトから$clips個のクリップを書き出しました。$unread件のプロジェクトはMIDIが未読み込みです。先にフルスキャンしてください。';
  }

  @override
  String get melodicExportNothing =>
      'メロディMIDIが見つかりません。先にプロジェクトのメタデータをフルスキャンしてください。';

  @override
  String get melodicReadConfirmTitle => '先にMIDIを読み込みますか？';

  @override
  String melodicReadConfirmBody(int count, String size) {
    return '$count件のプロジェクト（$size）はMIDIが未読み込みです。読み込みは各プロジェクトファイルを開きます。クラウド上のファイルは先にダウンロードされます。';
  }

  @override
  String get melodicReadAndExport => '読み込んで書き出す';

  @override
  String get melodicExportReadOnly => '読み込み済みのものを書き出す';

  @override
  String get melodicReadingTitle => 'MIDIを読み込み中';

  @override
  String melodicReadingProgress(int done, int total, String name) {
    return '$done / $total: $name';
  }

  @override
  String get melodicReadStop => '停止して読み込み済みを書き出す';

  @override
  String get referenceTitle => 'インサート参照ページ';

  @override
  String get referenceSubtitle =>
      'Cubaseプロジェクトからウェブページを生成します。トラックの役割ごとのプラグインチェーン、マスターのチェーン、これまで使ったすべてのインサートを確認できます。ブラウザで開きます。';

  @override
  String get referenceButton => '生成';

  @override
  String get referenceDialogTitle => 'ページの保存先フォルダを選択';

  @override
  String get referenceReadTitle => 'Cubaseプロジェクトを読み込みますか？';

  @override
  String referenceReadBody(int count, String size) {
    return '$count件のCubaseプロジェクト（$size）は前回のページ以降に新規または変更されています。読み込みは各ファイルを開きます。クラウド上のファイルは先にダウンロードされます。';
  }

  @override
  String get referenceReadAndGenerate => '読み込んで生成';

  @override
  String get referenceUseRead => '読み込み済みを使う';

  @override
  String get referenceReadingTitle => 'Cubaseプロジェクトを読み込み中';

  @override
  String get referenceReadStop => '停止して読み込み済みで生成';

  @override
  String referenceDone(int count) {
    return '$count件のプロジェクトからページを生成しました';
  }

  @override
  String get referenceNothing => '読み取れるCubaseプロジェクトが見つかりません';

  @override
  String get experimentalTabLabel => '試験的機能';

  @override
  String get experimentalSectionIntro =>
      '動作はしますが、まだ試用段階の新しいツールです。今後のバージョンで変更または削除される場合があります。';

  @override
  String get samplePackTitle => 'プロジェクトからサンプルパックを作成';

  @override
  String get samplePackSubtitle =>
      'プロジェクトで使われているサンプルを種類別（Kick、Snare、Bass、FX…）に1つのフォルダへコピーし、各サンプルを使っている曲数のレポートを作成します。同じフォルダへもう一度書き出すと、新しいものだけが追加されます。';

  @override
  String get samplePackDialogTitle => 'サンプルパックを書き出す';

  @override
  String get samplePackProfiles => 'プロファイル';

  @override
  String get samplePackSelectAll => 'すべて選択';

  @override
  String get samplePackSelectNone => 'すべて解除';

  @override
  String samplePackProjectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクト',
    );
    return '$_temp0';
  }

  @override
  String get samplePackLibraryFolders => 'サンプルライブラリのフォルダ';

  @override
  String get samplePackLibraryFoldersHelp =>
      'プロジェクトが保存時の場所で見つけられなくなったサンプルを探す場所です（ライブラリを移動したり、ドライブ文字が変わったりした場合）。プロジェクト自身のフォルダは常に検索されます。';

  @override
  String get samplePackNoLibraryFolders => 'フォルダは追加されていません。';

  @override
  String get samplePackIncludeOwnAudio => '自分の録音、バウンス、ステムも含める';

  @override
  String samplePackIncludeOwnAudioHelp(String folder) {
    return '専用のフォルダ「$folder」に入れます。';
  }

  @override
  String get samplePackIncludeMidi => 'MIDIコレクションも追加する';

  @override
  String get samplePackChooseDestination => 'フォルダを選んで書き出す';

  @override
  String get samplePackDestinationTitle => 'サンプルパックの書き出し先';

  @override
  String get samplePackProgressTitle => 'サンプルパックを作成中';

  @override
  String samplePackReading(int current, int total, String name) {
    return 'プロジェクトを読み込み中 $current/$total：$name';
  }

  @override
  String samplePackLocating(int current, int total, String name) {
    return 'サンプルを検索中 $current/$total：$name';
  }

  @override
  String samplePackMeasuring(int current, int total, String name) {
    return 'サンプルを確認中 $current/$total：$name';
  }

  @override
  String samplePackCopying(int current, int total, String name) {
    return 'コピー中 $current/$total：$name';
  }

  @override
  String samplePackWritingMidi(int current, int total, String name) {
    return 'MIDIコレクションを書き出し中 $current/$total：$name';
  }

  @override
  String get samplePackFinishing => 'レポートを書き出し中…';

  @override
  String get samplePackDoneTitle => 'サンプルパックが完成しました';

  @override
  String get samplePackStoppedTitle => 'サンプルパックの作成を中止しました';

  @override
  String samplePackAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の新しいサンプルを追加しました',
      zero: '新しいサンプルは追加されませんでした',
    );
    return '$_temp0';
  }

  @override
  String samplePackAlreadyThere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件はすでにフォルダにありました',
    );
    return '$_temp0';
  }

  @override
  String samplePackLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の録音・バウンス・ステムを除外しました',
    );
    return '$_temp0';
  }

  @override
  String samplePackMidiWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のMIDIファイルを書き出しました',
    );
    return '$_temp0';
  }

  @override
  String samplePackMissing(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のサンプルが見つかりませんでした — $file を参照',
    );
    return '$_temp0';
  }

  @override
  String samplePackNotRead(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクトを読み込めませんでした — $file を参照',
    );
    return '$_temp0';
  }

  @override
  String samplePackReportHint(String file) {
    return '各サンプルを使っている曲数と入手元は $file にあります。';
  }

  @override
  String get samplePackExcludeMasters => 'マスタープロジェクトを除外する';

  @override
  String get samplePackExcludeMastersHelp =>
      '名前に「(Master)」や「(M)」が付いたプロジェクト、または「Master Project」フォルダ内のプロジェクトです。曲のステムやミックスダウンが入っていて、サンプルではありません。';

  @override
  String samplePackMastersLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のマスタープロジェクトを除外しました',
    );
    return '$_temp0';
  }

  @override
  String get samplePackProjects => 'プロジェクト';

  @override
  String get samplePackAllProjects => 'すべてのプロジェクト';

  @override
  String get samplePackPickedProjects => 'プロジェクトを選ぶ';

  @override
  String get samplePackSearchProjects => 'プロジェクトを検索';

  @override
  String samplePackPickedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクトを選択中',
      zero: 'プロジェクトが選ばれていません',
    );
    return '$_temp0';
  }

  @override
  String get samplePackNoProjectsMatch => '一致するプロジェクトはありません。';

  @override
  String get samplePackRename => 'サンプルの名前を変更する';

  @override
  String get samplePackRenameHelp =>
      'カテゴリと番号の後に、選んだ項目が続きます。名前が変わるのはこの書き出しで追加されたサンプルだけで、元の名前はレポートに残ります。';

  @override
  String get samplePackRenameName => '元の名前';

  @override
  String get samplePackRenameBpm => 'テンポ (BPM)';

  @override
  String get samplePackRenameKey => 'キー';

  @override
  String get samplePackRenamePrefix => '接頭辞';

  @override
  String get samplePackRenamePrefixHint => '例: AC';

  @override
  String samplePackRenameExample(String name) {
    return '例: $name';
  }

  @override
  String get driveAgoJustNow => 'たった今';

  @override
  String driveAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分前',
    );
    return '$_temp0';
  }

  @override
  String driveAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間前',
    );
    return '$_temp0';
  }

  @override
  String get driveSyncIntro =>
      'プロジェクト、メモ、リリースをすべてのデバイスで同じ状態に保ちます。データはあなた自身のGoogleドライブ内のフォルダに保存されます。';

  @override
  String get driveWaitingForBrowser => 'ブラウザでサインインを完了してください…';

  @override
  String get driveThisDevice => 'このデバイス';

  @override
  String driveThisDeviceSynced(String when) {
    return 'このデバイスの同期: $when';
  }

  @override
  String get driveThisDeviceNeverSynced => 'このデバイスはまだ同期されていません';

  @override
  String driveUpdatedFrom(String when, String device) {
    return 'ドライブの更新: $when（$device）';
  }

  @override
  String driveUpdatedAt(String when) {
    return 'ドライブの更新: $when';
  }

  @override
  String get driveNoBackupYet => 'Googleドライブにはまだ何もありません';

  @override
  String driveNewerBanner(String device) {
    return '$device にはこのデバイスにまだない変更がドライブにあります。同期して取り込みましょう。';
  }

  @override
  String get driveNewerBannerNoDevice =>
      'ドライブにこのデバイスにまだない変更があります。同期して取り込みましょう。';

  @override
  String get driveSyncNow => '今すぐ同期';

  @override
  String get driveSyncNowHint =>
      '同期すると、ドライブの内容を取り込んでから、このデバイスの変更をアップロードします。いずれかのデバイスで意図的に削除したもの以外は削除されません。';

  @override
  String get driveSyncing => '同期中…';

  @override
  String get driveSyncingTitle => 'Googleドライブと同期中';

  @override
  String driveSyncedSummary(int added, int updated, int removed) {
    return '同期しました: 新規 $added、更新 $updated、削除 $removed。';
  }

  @override
  String get driveSyncedNothingNew => '同期しました。すべて最新の状態でした。';

  @override
  String get driveOperationCancelled => 'キャンセルしました。';

  @override
  String driveFilesFailedToUpload(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のファイルをアップロードできませんでした:',
    );
    return '$_temp0';
  }

  @override
  String driveLastSyncFailed(String when) {
    return '前回の同期に失敗しました（$when）';
  }

  @override
  String get driveErrorOffline =>
      'Googleドライブに接続できませんでした。インターネット接続を確認して、もう一度お試しください。';

  @override
  String get driveErrorSignInExpired => 'Googleドライブに再度サインインする必要があります。';

  @override
  String get driveErrorDriveFull =>
      'Googleドライブの容量がいっぱいです。同期を続けるには空き容量を確保してください。';

  @override
  String get driveErrorNoBackup => 'Googleドライブにはまだバックアップがありません。';

  @override
  String get driveErrorOther => '同期が完了しませんでした。';

  @override
  String driveSignInPortInUse(String port) {
    return 'サインインを開始できません: 別のプログラムがポート $port を使用しています。他の DAW Project Manager を閉じてから、もう一度お試しください。';
  }

  @override
  String get driveSignInTimedOut => 'サインインに時間がかかりすぎました。もう一度お試しください。';

  @override
  String get driveSignInNoBrowser => 'サインイン用のブラウザを開けませんでした。';

  @override
  String get driveBrowserSignedInTitle => 'サインインしました';

  @override
  String get driveBrowserSignedInBody =>
      'このタブを閉じて DAW Project Manager に戻ってください。';

  @override
  String get driveBrowserCancelledTitle => 'サインインがキャンセルされました';

  @override
  String get driveBrowserCancelledBody =>
      'このタブを閉じて、DAW Project Manager からもう一度お試しください。';

  @override
  String get driveBrowserErrorTitle => '問題が発生しました';

  @override
  String get driveBrowserErrorBody =>
      'このタブを閉じて、DAW Project Manager から再度サインインしてください。';

  @override
  String get driveAutoSyncTitle => '自動同期';

  @override
  String get driveAutoSyncDescription => 'アプリを開いている間、選んだ間隔でGoogleドライブと同期します。';

  @override
  String get driveAutoSyncIntervalLabel => '自動同期';

  @override
  String driveNextSync(String when) {
    return '次回の同期: $when';
  }

  @override
  String get driveMoreOptions => '復元とその他のオプション';

  @override
  String get driveRestoreFromDrive => 'ドライブの変更だけを取り込む';

  @override
  String get driveRestoreFromDriveHint => '何もアップロードせずに、このデバイスを最新の状態にします。';

  @override
  String get driveRecoverEarlier => '以前のバックアップから復元';

  @override
  String driveRecoverEarlierHint(int count) {
    return 'ドライブには直近 $count 件のバックアップが保存されます。復元すると不足分が追加されますが、その後の編集は元に戻りません。';
  }

  @override
  String get driveOverwrite => 'ドライブのコピーをこのデバイスの内容で置き換える';

  @override
  String get driveOverwriteHint =>
      'ドライブはこのデバイスとまったく同じ内容になります。置き換えられたコピーは以前のバックアップとして保存されます。';

  @override
  String get driveDeleteData => 'Googleドライブからデータを削除';

  @override
  String get driveDeleteDataHint =>
      'ドライブからバックアップ、プレビュー曲、画像、以前のバックアップを削除します。このデバイスのデータはすべて残ります。';

  @override
  String get driveMergeTitle => 'ドライブの変更を取り込みますか？';

  @override
  String get driveMergeConfirm => '取り込む';

  @override
  String get driveMergeNothing => 'このデバイスにとって新しい内容はドライブにありません。';

  @override
  String get driveMergeKeepsLocal => 'このデバイスのそれ以外の内容は変わらず、ドライブより新しい編集は保持されます。';

  @override
  String driveMergeAdds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいプロジェクト $count 件',
    );
    return '$_temp0';
  }

  @override
  String driveMergeUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '更新されるプロジェクト $count 件',
    );
    return '$_temp0';
  }

  @override
  String driveMergeRemoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '削除されるプロジェクト $count 件（別のデバイスで削除済み）',
    );
    return '$_temp0';
  }

  @override
  String driveMergeReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいリリース $count 件',
    );
    return '$_temp0';
  }

  @override
  String driveMergeReleasesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '削除されるリリース $count 件（別のデバイスで削除済み）',
    );
    return '$_temp0';
  }

  @override
  String get driveRecoverTitle => '以前のバックアップ';

  @override
  String get driveNoSnapshots =>
      '以前のバックアップはまだありません。同期でドライブのバックアップが置き換えられるたびに1つ保存されます。';

  @override
  String driveSnapshotItem(String when, String device) {
    return '$when · $device';
  }

  @override
  String get driveRecoverConfirmTitle => 'このバックアップを復元しますか？';

  @override
  String get driveRecoverConfirm => '復元';

  @override
  String get driveOverwriteTitle => 'ドライブのコピーを置き換えますか？';

  @override
  String get driveOverwriteBody =>
      '別のデバイスで追加したプロジェクトなど、このデバイスにないドライブ上の内容はドライブから消えます。現在のコピーは以前のバックアップとして保存されるので、後から復元できます。';

  @override
  String get driveOverwriteConfirm => '置き換える';

  @override
  String get driveDeleteTitle => 'Googleドライブからデータを削除しますか？';

  @override
  String get driveDeleteBody =>
      'GoogleドライブからDAW Project Managerのフォルダを完全に削除します（バックアップ、プレビュー曲、画像、以前のバックアップを含む）。このデバイスのデータは残ります。自動同期はオフになります。';

  @override
  String get driveDeleteConfirm => 'ドライブから削除';

  @override
  String get driveDeleted => 'Googleドライブからデータを削除しました。自動同期はオフになっています。';

  @override
  String get driveSignOutTitle => 'Googleドライブからサインアウトしますか？';

  @override
  String get driveSignOutBody =>
      'データはGoogleドライブとこのデバイスに残ります。再度サインインするまで自動同期は停止します。';

  @override
  String get driveFoundBackupTitle => 'Googleドライブにバックアップが見つかりました';

  @override
  String get driveFoundBackupBody => '今すぐ同期すると、このデバイスに取り込み、ここにある内容も追加します。';

  @override
  String get driveFirstUploadTitle => 'Googleドライブにはまだ何もありません';

  @override
  String get driveFirstUploadBody =>
      '今すぐ同期すると、このデバイスのライブラリをアップロードし、デバイス間で揃えられるようになります。';

  @override
  String driveUploadEstimate(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '約 $count 件のファイル（$size）がアップロードされます。',
    );
    return '$_temp0';
  }

  @override
  String get driveKeepInSyncAutomatically => 'このデバイスを自動的に同期する（1時間ごと）';

  @override
  String get driveLater => '後で';

  @override
  String get driveStatusSyncing => 'Googleドライブと同期中…';

  @override
  String get driveStatusFailed => '前回のGoogleドライブ同期に失敗しました';

  @override
  String get driveStatusNewer => 'Googleドライブに新しい変更があります';

  @override
  String get driveStatusUpToDate => 'Googleドライブ: 最新';

  @override
  String trayLastSyncFailed(String when) {
    return '前回の同期に失敗: $when';
  }

  @override
  String get driveSyncOnStartup => 'アプリ起動時に同期';

  @override
  String get driveSyncOnStartupHint => 'アプリを開くたびに、他のデバイスでの変更を取り込みます。';

  @override
  String get driveAlreadyInSync => 'このデバイスとGoogleドライブはすでに一致しています。同期するものはありません。';

  @override
  String get driveFromDrive => 'Googleドライブから';

  @override
  String get driveFromThisDevice => 'このデバイスから';

  @override
  String driveUploadProjects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ここで追加・変更されたプロジェクト $count 件',
    );
    return '$_temp0';
  }

  @override
  String driveUploadReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ここで追加されたリリース $count 件',
    );
    return '$_temp0';
  }

  @override
  String drivePreviewLineWithNames(String line, String names) {
    return '$line：$names';
  }

  @override
  String driveNamesAndMore(String names, int count) {
    return '$names ほか $count 件';
  }

  @override
  String get deleteProjectMenu => '削除…';

  @override
  String deleteProjectTitle(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get deleteProjectBody =>
      '「最近削除した項目」（設定 > プロジェクトフォルダ）に移動し、30日間はメモ、ToDo、作業時間ごと復元できます。ディスク上のファイルには触れません。';

  @override
  String get deleteProjectStillScanned =>
      'このファイルはこのプロファイルのプロジェクトフォルダ内にあるため、次回のスキャンで新しい空のプロジェクトとして再び追加されます。';

  @override
  String get deleteProjectStopScanningFolder => 'このフォルダのスキャンも停止する';

  @override
  String get deleteProjectStopScanningFile => 'このファイルのスキャンも停止する';

  @override
  String projectMovedToRecentlyDeleted(String name) {
    return '「$name」を「最近削除した項目」に移動しました。';
  }

  @override
  String get recentlyDeletedTitle => '最近削除した項目';

  @override
  String get recentlyDeletedSubtitle =>
      'このプロファイルから削除したプロジェクトは、メモ、ToDo、作業時間ごと30日間ここに残ります。ディスク上のファイルには一切触れません。';

  @override
  String get recentlyDeletedNothing => 'ここには何もありません。';

  @override
  String recentlyDeletedWhen(String when) {
    return '削除: $when';
  }

  @override
  String recentlyDeletedExpires(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと$count日で完全に削除',
    );
    return '$_temp0';
  }

  @override
  String get recentlyDeletedRestore => '復元';

  @override
  String get recentlyDeletedDeleteForever => '完全に削除';

  @override
  String get recentlyDeletedEmptyAll => '空にする';

  @override
  String get emptyRecentlyDeletedTitle => '「最近削除した項目」を空にしますか？';

  @override
  String emptyRecentlyDeletedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のプロジェクトが、メモ、ToDo、作業時間ごと完全に削除されます。ディスク上のファイルには触れません。',
    );
    return '$_temp0';
  }

  @override
  String deleteForeverTitle(String name) {
    return '「$name」を完全に削除しますか？';
  }

  @override
  String get deleteForeverBody => 'メモ、ToDo、作業時間は失われます。ディスク上のファイルには触れません。';

  @override
  String projectRestored(String name) {
    return '「$name」を復元しました。';
  }

  @override
  String projectRestoredReplacingRescan(String name) {
    return '「$name」を復元しました（その後スキャンで追加された空のコピーと置き換えました）。';
  }

  @override
  String get scanFolderOverlapTitle => '別のプロファイルがすでにスキャンしています';

  @override
  String scanFolderOverlapSame(String profile) {
    return '$profile がまさにこのフォルダをスキャンしています。';
  }

  @override
  String scanFolderOverlapInside(String profile, String path) {
    return '$profile はこのフォルダを含む $path をスキャンしています。';
  }

  @override
  String scanFolderOverlapContains(String profile, String path) {
    return '$profile はこのフォルダ内の $path をスキャンしています。';
  }

  @override
  String get scanFolderOverlapBody =>
      'プロファイルごとに見つけたプロジェクトのコピーを別々に持つため、これらは両方に表示され、メモ、ToDo、作業時間も別々になります。曲を別のプロファイルに渡すには、代わりに「プロファイルへ移動…」を使ってください。';

  @override
  String get scanFolderOverlapAddAnyway => 'それでも追加';

  @override
  String get moveToProfileMenu => 'プロファイルへ移動…';

  @override
  String get projectMenuFiles => 'ファイル';

  @override
  String get projectMenuUpdate => '情報を更新';

  @override
  String moveToProfileTitle(String name) {
    return '「$name」を別のプロファイルへ移動';
  }

  @override
  String moveToProfileVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のバージョンすべてが1曲としてまとめて移動します。',
    );
    return '$_temp0';
  }

  @override
  String get moveToProfileTarget => 'プロファイル';

  @override
  String get moveToProfileKeepFiles => 'ファイルは今の場所のまま';

  @override
  String moveToProfileKeepFilesHint(String profile, String path) {
    return '$profile は $path のスキャンをやめるので、そちらに戻ってきません。';
  }

  @override
  String get moveToProfileKeepFilesHintUnscanned => 'ディスク上は何も変わりません。';

  @override
  String get moveToProfileMoveFiles => 'ファイルも移動する';

  @override
  String get moveToProfileInto => '移動先:';

  @override
  String get moveToProfileOtherFolder => '別のフォルダ…';

  @override
  String get moveToProfileNoFolder =>
      'このプロファイルにはまだプロジェクトフォルダがありません。フォルダを選んでください。';

  @override
  String moveToProfileSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '約 $count 件のファイル（$size）をコピーして確認してから、元の場所から削除します。',
    );
    return '$_temp0';
  }

  @override
  String get moveToProfileCantMoveFiles =>
      'バージョンが複数のフォルダにあるため、ファイルをまとめて移動できません。';

  @override
  String moveToProfileReleases(String profile, String releases) {
    return '$profile の $releases から外れます。';
  }

  @override
  String get moveToProfileConfirm => '移動';

  @override
  String get moveToProfileNoOtherProfiles => '移動先となる他のプロファイルがありません。';

  @override
  String get moveToProfileInSession => '先にこのプロジェクトの作業セッションを終了してください。';

  @override
  String get moveToProfileMoving => 'ファイルを移動しています…';

  @override
  String moveToProfileDone(String name, String profile) {
    return '「$name」を $profile に移動しました。';
  }

  @override
  String get moveToProfileBlockedArchived => 'アーカイブ済みです。先にアーカイブから復元してください。';

  @override
  String moveToProfileBlockedTargetCopy(String profile) {
    return '$profile にはすでにこの曲があり、独自のメモや ToDo があります。何も移動していません。';
  }

  @override
  String get moveToProfileBlockedSourceMissing => 'ファイルがこのコンピュータにありません。';

  @override
  String moveToProfileBlockedOccupied(String path) {
    return '$path に同じ名前のものがすでにあります。何も移動していません。';
  }

  @override
  String get moveToProfileBlockedInsideSource => 'そのフォルダは曲自身のフォルダの中にあります。';

  @override
  String get moveToProfileBlockedSameLocation => 'ファイルはすでにそこにあります。';

  @override
  String get moveToProfileCopyFailed => 'コピーが元のファイルと一致しなかったため、何も削除・移動していません:';

  @override
  String get foldersProfilePickerLabel => 'プロファイル';

  @override
  String foldersProfileActive(String name) {
    return '$name（使用中）';
  }

  @override
  String foldersEditingOtherProfile(String name) {
    return '有効なプロファイルではなく、$name のフォルダを編集しています。その中の新しいファイルは、次に $name に切り替えたときに表示されます。';
  }

  @override
  String get midiInput => 'MIDI入力';

  @override
  String get midiInputOff => 'MIDI入力なし';

  @override
  String get midiInputAll => 'すべてのMIDI入力';

  @override
  String get midiInputNoDevices => 'MIDI入力が見つかりません';

  @override
  String midiInputListening(String names) {
    return 'MIDI入力：$names';
  }

  @override
  String midiInputBusy(String names) {
    return '$namesを開けませんでした。ほかのアプリが使用している可能性があります。';
  }

  @override
  String get midiShortcutsMidiInput => 'MIDIキーボード';

  @override
  String get midiGesturePlayKey => '鍵盤を弾く';

  @override
  String get midiShortcutPlayKey => 'クリップの楽器でノートを鳴らす';

  @override
  String get midiRecord => 'MIDIキーボードから録音：ループを再生し、弾いた内容を記録します';

  @override
  String get midiStopRecording => '録音を停止';

  @override
  String get midiShortcutRecord => 'MIDIキーボードから録音（ループを再生し、各周回で弾いた内容を残す）';

  @override
  String get midiShortcutRulerDoubleClick => 'ルーラーの上：その位置から再生';

  @override
  String get midiMetronome => 'メトロノーム';

  @override
  String get midiShortcutMetronome => 'メトロノームのオン／オフ';

  @override
  String midiRecordLatency(int ms) {
    return '録音レイテンシー：$ms ms';
  }

  @override
  String get midiRecordLatencyTitle => '録音レイテンシー';

  @override
  String get midiRecordLatencyBody =>
      '録音したノートをこの分だけ早めに入力し、音が届くまでと鍵盤の入力がアプリに届くまでの遅れを補正します。キャリブレーションでこのコンピューターでの値を測定できます。';

  @override
  String get midiCalibrate => 'キャリブレーション';

  @override
  String midiCalibrating(int done, int total) {
    return 'クリックごとに鍵盤を弾いてください（$done／$total）';
  }

  @override
  String midiCalibrated(int ms) {
    return '録音レイテンシーを $ms ms に設定しました';
  }

  @override
  String get dpmPluginSessionsDescription =>
      'プロジェクトに DAW Project Manager プラグインを入れると、DAW がそのプロジェクトを開いたり閉じたりしたことがアプリに伝わります。';

  @override
  String get dpmPluginEndSessionWhenDawCloses => 'DAW がプロジェクトを閉じたらセッションを終了';

  @override
  String get dpmPluginEndSessionWhenDawClosesDescription =>
      'クラッシュ後も同様です。セッションは DAW がプロジェクトを手放した時刻で終了します。';

  @override
  String get dpmPluginStartSessionWhenDawOpens => 'DAW でプロジェクトが開かれたらセッションを開始';

  @override
  String get dpmPluginStartSessionWhenDawOpensDescription =>
      '実行中のセッションがない場合のみ、またアクティブなプロフィールのプロジェクトのみが対象です。';

  @override
  String get dpmPluginSessionEndedTitle => 'セッションが終了しました';

  @override
  String dpmPluginSessionEndedClosed(String daw, String project) {
    return '$daw が $project を閉じたため、作業セッションを終了しました。';
  }

  @override
  String dpmPluginSessionEndedNoResponse(String daw, String project) {
    return '$daw の DAW Project Manager プラグインから応答がなくなったため、$project のセッションを最後に応答があった時刻で終了しました。DAW がクラッシュしたか、強制終了された可能性があります。';
  }

  @override
  String get dpmPluginUnknownDaw => 'DAW';

  @override
  String dpmPluginSessionEndedSummary(
    String start,
    String end,
    String duration,
  ) {
    return '$start–$end · $duration';
  }

  @override
  String get dpmPluginTabLabel => 'DAW プラグイン';

  @override
  String get dpmPluginTitle => 'DAW Project Manager プラグイン';

  @override
  String get dpmPluginDescription =>
      'DAW 用の VST3/AU プラグインです。マスターバスに挿すと、プロジェクトのタスクを表示し、再生のたびにプロジェクトの最新のキャプチャとして録音し、DAW がプロジェクトを閉じたときに作業セッションを終了できます。';

  @override
  String dpmPluginLastSeen(String daw, String version, String date) {
    return '最後に確認: $daw（バージョン $version）、$date。';
  }

  @override
  String get dpmPluginNotSeen =>
      'このコンピューターではまだ確認されていません。インストールして、DAW のマスターバスに挿してください。';

  @override
  String dpmPluginUpdateAvailable(String version) {
    return 'バージョン $version が利用できます。';
  }

  @override
  String get dpmPluginDownload => 'DAW プラグインをダウンロード';

  @override
  String get dpmPluginDownloadUpdate => 'アップデートをダウンロード';

  @override
  String get dpmPluginInstalledTitle => 'インストール済み';

  @override
  String dpmPluginInstalledVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get dpmPluginInstalledNone => '標準のプラグインフォルダーに見つかりません。';

  @override
  String get dpmPluginInstalledDuplicates =>
      '複数のコピーがインストールされているため、DAW がどちらを読み込むかわかりません。1 つだけ残してください。';

  @override
  String get dpmPluginSearchAgain => '再検索';

  @override
  String get dpmPluginSearching => '検索中…';

  @override
  String get dpmPluginCustomFoldersHint =>
      '別の場所にインストールしましたか？ そのフォルダーを追加すると、標準フォルダーにコピーがない場合にアプリがそこを探します。';

  @override
  String get dpmPluginCustomFolderTag => '追加したフォルダー';

  @override
  String get dpmPluginScanUnavailable =>
      'Flatpak 版はプラグインフォルダーを参照できません。DAW がプラグインを読み込むと、ここに表示されます。';

  @override
  String get legacyInstallTitle => '古いインストールを削除しますか？';

  @override
  String get legacyInstallMessage =>
      '以前のインストーラーで入れた DAW Project Manager の古いコピーがまだインストールされています。このコピーがそれに代わり、今後は自動で更新されます。古いコピーを削除してもライブラリには影響しません。';

  @override
  String get legacyInstallRemove => '削除する';

  @override
  String get legacyInstallKeep => '残す';

  @override
  String get legacyInstallRemoveFailed => '古いコピーのアンインストーラーを起動できませんでした。';

  @override
  String get missingPreviewSongsTitle => '見つからないプレビュー曲';

  @override
  String get missingPreviewSongsSubtitle =>
      '現在のプロファイルで、このコンピューターが見つけられないプレビュー曲です。確認してから、それぞれダウンロード・検索・削除を選んでください。選ぶまで何も変わりません。';

  @override
  String get missingPreviewSongsCheck => '確認';

  @override
  String get missingPreviewSongsChecking => '確認中…';

  @override
  String get missingPreviewSongsNone => 'すべてのプレビュー曲が所定の場所にあります。';

  @override
  String get missingPreviewSongsSignInHint => 'Google ドライブにログインすると、そこでも探せます。';

  @override
  String missingPreviewOnDriveTitle(int count) {
    return 'Google ドライブ上 ($count)';
  }

  @override
  String get missingPreviewOnDriveDescription =>
      'バックアップにこれらの曲があります。ダウンロードすると、このコンピューターにコピーが保存されます。';

  @override
  String missingPreviewOtherComputerTitle(int count) {
    return '別のコンピューターから ($count)';
  }

  @override
  String get missingPreviewOtherComputerDescription =>
      'パスは別のコンピューターのもので、そちらでは問題なく再生できるかもしれません。このコンピューターでも再生するには、ここでファイルを選んでください。';

  @override
  String missingPreviewFolderMissingTitle(int count) {
    return 'フォルダーがありません ($count)';
  }

  @override
  String get missingPreviewFolderMissingDescription =>
      'フォルダーも見つかりません。ドライブが接続されていないか、フォルダーが移動または削除されています。何かを削除する前に、ドライブを接続してもう一度確認してください。';

  @override
  String missingPreviewFileMissingTitle(int count) {
    return 'ファイルがありません ($count)';
  }

  @override
  String get missingPreviewFileMissingDescription => 'フォルダーはありますが、ファイルがありません。';

  @override
  String get missingPreviewDownload => 'ダウンロード';

  @override
  String get missingPreviewDownloadAll => 'すべてダウンロード';

  @override
  String get missingPreviewFindAll => 'すべて検索';

  @override
  String get missingPreviewRemoveAll => 'すべて削除';

  @override
  String missingPreviewRemoveAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'プレビュー曲を$count件削除しますか？',
    );
    return '$_temp0';
  }

  @override
  String get missingPreviewRemoveBody =>
      'このコンピューター上でのみ削除され、ファイルは削除されません。別のデバイスにまだこれらの曲がある場合は、次回の同期でここに戻ります。';

  @override
  String missingPreviewDownloadedResult(int done, int total) {
    return '$total件中$done件をダウンロードしました。';
  }

  @override
  String missingPreviewFoundResult(int found, int total) {
    return '$total件中$found件のミックスダウンが見つかりました。';
  }

  @override
  String missingPreviewDownloadFailed(String name) {
    return '$nameの曲をダウンロードできませんでした。';
  }

  @override
  String get missingPreviewAutoDetected => '自動検出';

  @override
  String missingPreviewRemoveEverything(int count) {
    return '見つからないものをすべて削除 ($count)';
  }

  @override
  String missingPreviewRemoveIncludesDrive(int count) {
    return 'このうち$count件は、まだ Google ドライブからダウンロードできます。';
  }

  @override
  String missingPreviewRemoveIncludesOtherComputer(int count) {
    return 'このうち$count件は、別のコンピューターではまだ再生できるかもしれません。';
  }

  @override
  String get inspectorTab => 'インスペクター';

  @override
  String get inspectorSearchHint => 'トラックとプラグインを検索';

  @override
  String get inspectorEmptyTitle => 'DAWを開かずにプロジェクトの中身を確認';

  @override
  String get inspectorEmptyBody =>
      'プロジェクトファイルをここにドロップするか、開くか、プロジェクトのメニューで「調べる」を選びます。プロジェクトは読み取るだけで、変更されません。';

  @override
  String get inspectorOpenProject => 'プロジェクトを開く…';

  @override
  String get inspectorChooseProjectTitle => '調べるプロジェクトを選択';

  @override
  String get inspectorReading => 'プロジェクトを読み込み中…';

  @override
  String get inspectorReadFailed => 'このプロジェクトを読み込めませんでした。';

  @override
  String inspectorUnsupported(String extension) {
    return 'インスペクターは$extensionファイルを読み込めません。';
  }

  @override
  String get inspectorReload => '再読み込み';

  @override
  String get inspectorClose => '閉じる';

  @override
  String inspectorSavedWith(String daw, String version) {
    return '$daw $version で保存';
  }

  @override
  String get inspectorTileTempo => 'テンポ';

  @override
  String get inspectorTileTimeSignature => '拍子';

  @override
  String get inspectorTileSampleRate => 'サンプルレート';

  @override
  String inspectorBitDepth(int bits) {
    return '$bitsビット';
  }

  @override
  String get inspectorNotInFile => 'このプロジェクトにはありません';

  @override
  String inspectorTileTracks(int count) {
    return 'トラック';
  }

  @override
  String inspectorTileEffects(int count) {
    return 'エフェクト';
  }

  @override
  String inspectorTileInstruments(int count) {
    return 'インストゥルメント';
  }

  @override
  String inspectorEffectsBreakdown(int stock, int thirdParty) {
    return '付属 $stock · サードパーティ $thirdParty';
  }

  @override
  String get inspectorFilterAll => 'すべて';

  @override
  String get inspectorKindAudio => 'オーディオ';

  @override
  String get inspectorKindInstrument => 'インストゥルメント';

  @override
  String get inspectorKindMidi => 'MIDI';

  @override
  String get inspectorKindSampler => 'サンプラー';

  @override
  String get inspectorKindGroup => 'グループ';

  @override
  String get inspectorKindFx => 'FX';

  @override
  String get inspectorKindFolder => 'フォルダー';

  @override
  String get inspectorTabTracks => 'トラック';

  @override
  String get inspectorTabPlugins => 'プラグイン';

  @override
  String get inspectorTabRouting => 'ルーティング';

  @override
  String get inspectorTabMedia => 'オーディオファイル';

  @override
  String get inspectorTabStatistics => '統計';

  @override
  String inspectorNotAvailable(String daw) {
    return '$daw のプロジェクトではまだ読み取れません。';
  }

  @override
  String get inspectorOutput => '出力';

  @override
  String get inspectorInserts => 'インサート';

  @override
  String get inspectorSends => 'センド';

  @override
  String get inspectorInstrument => 'インストゥルメント';

  @override
  String get inspectorFader => 'フェーダー';

  @override
  String get inspectorNoInserts => 'インサートなし';

  @override
  String get inspectorNoSends => 'センドなし';

  @override
  String get inspectorNotConnected => '未接続';

  @override
  String get inspectorDeactivated => 'オフ';

  @override
  String get inspectorSoloed => 'ソロ';

  @override
  String get inspectorPreFader => 'プリフェーダー';

  @override
  String get inspectorSendSwitchedOff => 'オフ';

  @override
  String inspectorSideChainInto(String plugin) {
    return '$plugin のサイドチェイン';
  }

  @override
  String inspectorEqBandsOn(int count) {
    return 'EQ: $count バンドがオン';
  }

  @override
  String get inspectorFaderPositionOnly => 'フェーダーの位置（dB値はまだ読み取れません）';

  @override
  String get inspectorSelectChannel => 'チャンネルを選ぶと、ルーティングとプラグインが表示されます。';

  @override
  String get inspectorGroupStock => '付属エフェクト';

  @override
  String get inspectorGroupThirdParty => 'サードパーティのエフェクト';

  @override
  String get inspectorGroupInstruments => 'インストゥルメント';

  @override
  String inspectorPluginSummary(int unique, int instances) {
    return '$unique 種類 · $instances インスタンス';
  }

  @override
  String inspectorPluginsNamesOnly(String daw) {
    return '$daw のプロジェクトでは、各プラグインを使うチャンネルはまだ読み取れません。';
  }

  @override
  String get inspectorSignalFlow => '信号の流れ';

  @override
  String get inspectorByDestination => '送り先ごと';

  @override
  String get inspectorFeedsIn => '入力元';

  @override
  String get inspectorGoesTo => '送り先';

  @override
  String get inspectorSignalPath => '信号経路';

  @override
  String get inspectorViaSend => 'センド';

  @override
  String get inspectorViaSideChain => 'サイドチェイン';

  @override
  String get inspectorNothingFeeds => 'このチャンネルへの入力はありません。';

  @override
  String inspectorHintNowhere(int count) {
    return '出力先のないチャンネル：$count';
  }

  @override
  String inspectorHintSkipBuses(int count) {
    return '出力へ直接送られるトラック：$count';
  }

  @override
  String inspectorSourcesCount(int count) {
    return '入力元 $count';
  }

  @override
  String get inspectorMediaFound => '見つかりました';

  @override
  String get inspectorMediaElsewhere => 'プロジェクトフォルダーで見つかりました';

  @override
  String get inspectorMediaMissing => '見つかりません';

  @override
  String inspectorMediaSummary(int missing, int total) {
    return '$total 件中 $missing 件が見つかりません';
  }

  @override
  String inspectorMediaAllFound(int total) {
    return '$total 件すべて見つかりました';
  }

  @override
  String get inspectorMediaChecking => 'ファイルを探しています…';

  @override
  String get inspectorMediaNone => 'このプロジェクトはオーディオファイルを使っていません。';

  @override
  String inspectorMediaStoredAt(String path) {
    return 'プロジェクト上の場所: $path';
  }

  @override
  String inspectorMediaFoundAt(String path) {
    return '見つかった場所: $path';
  }

  @override
  String get inspectorStatTrackTypes => 'トラックの種類';

  @override
  String get inspectorStatPluginInstances => 'プラグインのインスタンス';

  @override
  String get inspectorStatUnknown => '不明';

  @override
  String get inspectorStatMostUsed => 'よく使われるプラグイン';

  @override
  String get inspectorStatUsualChains => 'よく使うチェーン';

  @override
  String get inspectorStatNoChains => '複数のチャンネルで繰り返されるプラグインチェーンはありません。';

  @override
  String get inspectorStatInsertsPerChannel => 'チャンネルごとのインサート数';

  @override
  String get inspectorStatBusiest => '入力の多い送り先';

  @override
  String inspectorInsertsCount(int count) {
    return 'インサート $count';
  }

  @override
  String inspectorChannelsCount(int count) {
    return 'チャンネル $count';
  }

  @override
  String get projectMenuInspect => '調べる';

  @override
  String get sampleRateColumn => 'サンプルレート';

  @override
  String get inspectorCloudTitle => 'このプロジェクトをダウンロードしますか？';

  @override
  String inspectorCloudBody(String size) {
    return 'このプロジェクトはクラウド上にあり、このコンピューターにはありません。読み込むとファイル全体（$size）がダウンロードされます。';
  }

  @override
  String get inspectorCloudRead => 'ダウンロードして読み込む';

  @override
  String get inspectorTabAudioIo => 'オーディオI/O';

  @override
  String get inspectorAudioDriver => 'オーディオドライバー';

  @override
  String get inspectorUnnamedDriver => 'プロジェクトに名前がありません';

  @override
  String inspectorSavedOn(String platform) {
    return '$platform で保存';
  }

  @override
  String get inspectorInputBuses => '入力バス';

  @override
  String get inspectorOutputBuses => '出力バス';

  @override
  String get inspectorInterfaceInputs => 'インターフェースの入力';

  @override
  String get inspectorInterfaceOutputs => 'インターフェースの出力';

  @override
  String get inspectorMidiInputs => 'MIDI入力';

  @override
  String get inspectorMidiOutputs => 'MIDI出力';

  @override
  String get inspectorNone => 'なし';

  @override
  String get inspectorPan => 'パン';

  @override
  String get inspectorMuted => 'ミュート';

  @override
  String get inspectorChannelStrip => 'チャンネルストリップ';

  @override
  String get inspectorStripBypassed => 'ストリップをバイパス';

  @override
  String get inspectorStripBeforeInserts => 'インサートの前';

  @override
  String get inspectorStripGate => 'ゲート';

  @override
  String get inspectorStripCompressor => 'コンプレッサー';

  @override
  String get inspectorStripEq => 'EQ';

  @override
  String get inspectorStripTools => 'ツール';

  @override
  String get inspectorStripSaturation => 'サチュレーション';

  @override
  String get inspectorStripLimiter => 'リミッター';

  @override
  String get inspectorStripModule => 'モジュール';

  @override
  String get relinkFixButton => '見つからないファイルを修復…';

  @override
  String get relinkTitle => '見つからないファイルを修復';

  @override
  String get relinkIntro =>
      'ファイルの現在の場所を指すプロジェクトのコピーを隣に書き出します。元のプロジェクトは変更されません。';

  @override
  String get relinkSearchFolder => 'フォルダーを検索…';

  @override
  String get relinkSearchFolderTitle => '見つからないファイルはどこにありますか？';

  @override
  String get relinkSearching => 'ファイルを探しています…';

  @override
  String relinkSearchedIn(String folders) {
    return '検索済み: $folders';
  }

  @override
  String relinkWillFix(int count, int total) {
    return '$total 件中 $count 件のファイルを再リンクします';
  }

  @override
  String relinkChooseOne(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件見つかりました — 1 つ選んでください',
    );
    return '$_temp0';
  }

  @override
  String get relinkNotFound => '見つかりません';

  @override
  String get relinkBrowse => '参照…';

  @override
  String relinkBrowseTitle(String name) {
    return '$name はどこにありますか？';
  }

  @override
  String get relinkLeave => 'そのままにする';

  @override
  String get relinkChange => 'リンク先を選択';

  @override
  String relinkRuleOffer(int count, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '同じ移動でさらに $count 件見つかります: $from → $to',
    );
    return '$_temp0';
  }

  @override
  String get relinkApplyRule => '適用';

  @override
  String get relinkWrite => '再リンクしたコピーを書き出す';

  @override
  String get relinkWriting => 'コピーを書き出して確認しています…';

  @override
  String relinkWrote(String name) {
    return '$name を書き出しました';
  }

  @override
  String relinkRelinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のファイルを再リンクしました',
    );
    return '$_temp0';
  }

  @override
  String relinkRefusedTooLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count 件は再リンクされませんでした: 新しいパスがプロジェクトに収まる長さを超えています。短いパスに移すか、Cubase で探してください。',
    );
    return '$_temp0';
  }

  @override
  String relinkRefusedEncoding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件は再リンクされませんでした: この古いプロジェクトは新しいパスの特殊文字を保存できません。',
    );
    return '$_temp0';
  }

  @override
  String relinkRefusedNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件は再リンクされませんでした: コピーで変更できない場所にしか記録されていません。',
    );
    return '$_temp0';
  }

  @override
  String get relinkNothingWritten => '再リンクできるものがなかったため、コピーは書き出されませんでした。';

  @override
  String relinkFailed(String reason) {
    return 'コピーが確認に失敗したため保存しませんでした: $reason';
  }

  @override
  String get relinkInspectCopy => 'コピーを調べる';

  @override
  String get inspectorTileKey => 'キー';

  @override
  String inspectorTileMidiClips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'MIDI クリップ',
    );
    return '$_temp0';
  }

  @override
  String inspectorTileMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'マーカー',
    );
    return '$_temp0';
  }

  @override
  String inspectorMarkerRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'リージョン $count 件',
      zero: 'リージョンなし',
    );
    return '$_temp0';
  }

  @override
  String inspectorTilePlugins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'プラグイン',
    );
    return '$_temp0';
  }

  @override
  String get inspectorPluginNamesOnly => '名前のみ';

  @override
  String inspectorMidiFilesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '.mid ファイル $count 件が見つかりません',
    );
    return '$_temp0';
  }

  @override
  String get inspectorKindBuses => 'グループ / FX';

  @override
  String get inspectorNotesTitle => 'プロジェクト内のメモ';

  @override
  String get inspectorMissingMidiTitle => '見つからない MIDI ファイル';

  @override
  String get safeCopyButton => 'セーフコピー…';

  @override
  String get safeCopyTitle => 'セーフコピー';

  @override
  String get safeCopyIntro =>
      '選んだプラグインをオフにしたプロジェクトのコピーです。どれかが DAW をクラッシュさせたり、インストールされていなかったりしても開けます。コピーではそれらが無効として表示されるので、スロットから再び有効にするか、差し替えてください。元のプロジェクトは変更されません。';

  @override
  String get safeCopyFilter => 'プラグインを絞り込む';

  @override
  String get safeCopyReading => 'プラグインを読み込み中…';

  @override
  String safeCopyReadFailed(String reason) {
    return 'プロジェクトのプラグインを読み込めませんでした: $reason';
  }

  @override
  String safeCopyInstances(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count インスタンス',
    );
    return '$_temp0';
  }

  @override
  String safeCopyAlreadyOff(int count) {
    return '$count 個はすでにオフ';
  }

  @override
  String get safeCopyAllOff => 'すべてオフ済み';

  @override
  String safeCopyWillSwitchOff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count インスタンスがオフになります',
      zero: 'オフにするプラグインを選んでください',
    );
    return '$_temp0';
  }

  @override
  String get safeCopyWrite => 'セーフコピーを書き出す';

  @override
  String safeCopySwitchedOff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count インスタンスをオフにしました',
    );
    return '$_temp0';
  }

  @override
  String get safeCopyNextStep =>
      'コピーを DAW で開いてください。これらのプラグインはスロットで無効として表示され、再び有効にしたり差し替えたりできます。';

  @override
  String get safeCopyNothingWritten => '選んだプラグインはどれもオンではなかったため、何も書き出されませんでした。';
}
