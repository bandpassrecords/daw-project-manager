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
  String get cancel => 'キャンセル';

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
  String get scanning => 'スキャン中…';

  @override
  String get projectName => 'プロジェクト名';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'キー（例：C#m、F major）';

  @override
  String get notes => 'メモ';

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
  String get clearLibrary => 'ライブラリをクリア';

  @override
  String get clearLibraryMessage =>
      'これにより、保存されたすべてのプロジェクトとソースフォルダが削除されます。続行しますか？';

  @override
  String get clear => 'クリア';

  @override
  String get roots => 'ルート';

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
  String get deepScanTooltip =>
      '詳細スキャンは、プロジェクトファイルから完全なメタデータを抽出します：\n• BPM（1分あたりのビート数）\n• 音楽キー\n• DAWバージョン\nこれは遅いですが、完全な情報を提供します。';

  @override
  String get deepScanConfirm =>
      'これにより、すべてのプロジェクトをスキャンし、完全なメタデータ（BPM、キー、DAWバージョン）を抽出します。これには時間がかかる場合があります。続行しますか？';

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
    return '「$profileName」を削除してもよろしいですか？これにより、このプロファイルのすべてのプロジェクト、ルート、リリースが削除されます。';
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
  String created(String date) {
    return '作成日';
  }

  @override
  String get toggleSort => '並び替えを切り替え';

  @override
  String get clearLibraryTooltip => 'ライブラリをクリア（プロジェクトとルート）';

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
  String get allPhases => 'すべてのフェーズ';

  @override
  String get daw => 'DAW';

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
  String get deleteRootPath => 'ルートパスを削除';

  @override
  String deleteRootPathMessage(String path) {
    return '「$path」を削除してもよろしいですか？これにより、リリースに含まれていないこのフォルダ内のすべてのプロジェクトも削除されます。';
  }

  @override
  String rootsCount(int count) {
    return 'ルート: $count';
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
  String get noProjectsFoundInRoots => '選択したルートにプロジェクトが見つかりませんでした。';

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
  String get selectTracks => 'トラックを選択';

  @override
  String get continueButton => '続ける';

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
  String errorLoadingProjects(String error) {
    return 'プロジェクトの読み込みエラー: $error';
  }

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
  String failedToOpenFile(String error) {
    return 'ファイルを開けませんでした: $error';
  }

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
  String get todoList => 'タスクリスト';

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
  String get noFilesAddedYet =>
      'まだファイルが追加されていません。\n「ファイルを追加」をクリックしてリリースファイルをアップロードしてください。';

  @override
  String get noTodosYet => 'まだタスクがありません。上に追加してください。';

  @override
  String get done => '完了';

  @override
  String get backupAndRestore => 'バックアップと復元';

  @override
  String get exportBackup => 'バックアップをエクスポート';

  @override
  String get importBackup => 'バックアップをインポート';

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
    return 'バックアップのインポートに成功しました: $projectsCount プロジェクト、$rootsCount ルート、$releasesCount リリース';
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
    return '新しいプロフィール \"$profileName\" にバックアップをインポートしました: $projectsCount プロジェクト、$rootsCount ルート、$releasesCount リリース';
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
}
