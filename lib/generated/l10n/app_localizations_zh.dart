// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DAW项目管理器';

  @override
  String get projectDetails => '项目详情';

  @override
  String get back => '返回';

  @override
  String get save => '保存';

  @override
  String get enable => '启用';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get undo => '撤销';

  @override
  String get customInterval => '自定义';

  @override
  String get close => '关闭';

  @override
  String get launch => '打开';

  @override
  String get view => '查看';

  @override
  String get openFolder => '打开文件夹';

  @override
  String get openInDaw => '在DAW中启动';

  @override
  String get extract => '提取';

  @override
  String get extracting => '提取中…';

  @override
  String get extractingMetadata => '正在提取元数据...';

  @override
  String get deepScan => '深度扫描';

  @override
  String get rescan => '重新扫描';

  @override
  String get refreshProject => '刷新';

  @override
  String get scanning => '扫描中…';

  @override
  String get newProjectBadge => '新';

  @override
  String get projectName => '项目名称';

  @override
  String get bpm => 'BPM';

  @override
  String get key => '调性（例如：C#m，F大调）';

  @override
  String get notes => '备注';

  @override
  String get expandNotes => '展开';

  @override
  String get collapseNotes => '收起';

  @override
  String get projectNotesFromDaw => '项目备注（来自DAW文件）';

  @override
  String get projectPhase => '项目阶段';

  @override
  String get failedToLoad => '加载失败';

  @override
  String get fileMissing => '文件缺失。';

  @override
  String launchingProject(String projectName) {
    return '正在打开$projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return '无法打开$projectName';
  }

  @override
  String get clearLibrary => '清空库';

  @override
  String get clearLibraryMessage => '这将删除所有保存的项目和源文件夹。继续吗？';

  @override
  String get clear => '清空';

  @override
  String get roots => '项目文件夹';

  @override
  String get pathsSettingsDangerZoneTitle => '库';

  @override
  String get pathsSettingsDangerZoneSubtitle => '清除当前配置文件中的所有项目和项目文件夹。';

  @override
  String get projectFoldersSectionTitle => '项目文件夹';

  @override
  String get projectFoldersSectionSubtitle => '将扫描这些文件夹以查找 DAW 项目。';

  @override
  String get projectFoldersEmptyTitle => '还没有项目文件夹';

  @override
  String get projectFoldersEmptySubtitle => '请至少添加一个文件夹以开始扫描项目。';

  @override
  String get notScannedYet => '尚未扫描';

  @override
  String lastScan(String date) {
    return '上次扫描: $date';
  }

  @override
  String get excludedFoldersSectionTitle => '排除的文件夹';

  @override
  String get excludedFoldersSectionSubtitle => '扫描时将跳过这些文件夹，即使它们位于项目文件夹内。';

  @override
  String get addExcludedFolder => '添加排除';

  @override
  String get selectExcludedFolder => '选择要排除的文件夹';

  @override
  String get excludedFoldersEmptyTitle => '没有排除的文件夹';

  @override
  String get excludedFoldersEmptySubtitle => '可选：添加你永远不想扫描的文件夹。';

  @override
  String get removeExcludedFolderTitle => '移除排除的文件夹？';

  @override
  String removeExcludedFolderMessage(String path) {
    return '该文件夹将不再被排除：\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath => '该文件夹将不再被排除。';

  @override
  String get desktopOnlyPathsSettings => '此页面仅在桌面应用中可用。';

  @override
  String get renameProjectFolderTitle => '显示名称';

  @override
  String get flatpakPortalPathExplanation =>
      '此路径是沙盒隔离位置，不是真实的文件夹位置 — Flatpak不会将其与应用共享。请改用上面的名称来识别它。';

  @override
  String get removeProjectFolderTitle => '移除项目文件夹？';

  @override
  String removeProjectFolderMessage(String path) {
    return '确定要移除「$path」吗？这也会移除该文件夹中未包含在发布中的所有项目。';
  }

  @override
  String get projects => '项目';

  @override
  String get hidden => '隐藏';

  @override
  String get profileManager => '配置文件管理器';

  @override
  String get createNewProfile => '创建新配置文件';

  @override
  String get profileName => '配置文件名称';

  @override
  String get create => '创建';

  @override
  String get profiles => '配置文件';

  @override
  String get active => '活动';

  @override
  String get switchProfile => '切换';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get addFolder => '添加文件夹';

  @override
  String get searchProjects => '搜索项目...';

  @override
  String get searchReleases => '搜索发布...';

  @override
  String get searchPlaylists => '搜索播放列表...';

  @override
  String get noReleasesFound => '未找到发布';

  @override
  String get noPlaylistsFound => '未找到播放列表';

  @override
  String get tryDifferentSearch => '尝试不同的搜索词';

  @override
  String get deepScanConfirm =>
      '深度扫描从项目文件中提取完整的元数据：\n• BPM（每分钟节拍数）\n• 音乐调性\n• DAW版本\n• 项目备注（视DAW支持情况而定）\n\n这比常规扫描慢，可能需要一些时间。继续吗？';

  @override
  String get deepScanViewSupportedDaws => '查看支持的DAW和字段';

  @override
  String get deepScanOnlyUnscanned => '仅扫描没有元数据的项目';

  @override
  String get metadataExtractionTitle => '元数据提取';

  @override
  String get metadataExtractionSubtitle => '查看每种DAW支持哪些数据';

  @override
  String get metadataExtractionIntro =>
      '深度扫描可以自动从项目文件中直接读取部分字段 — 其余字段需要手动输入。此表显示了每个受支持的DAW目前自动支持哪些字段。';

  @override
  String get metadataFieldKey => '调性';

  @override
  String get metadataFieldVersion => 'DAW版本';

  @override
  String get metadataExtractionManualNote =>
      '没有自动支持的字段仍可以在项目详情中手动输入。特别是对于BPM和调性，在项目旁放置bpm.txt或key.txt文件，也会在下次扫描时被读取。';

  @override
  String get metadataExtractedSuccessfully => '元数据提取成功';

  @override
  String failedToExtractMetadata(String error) {
    return '元数据提取失败: $error';
  }

  @override
  String get saved => '已保存';

  @override
  String get failedToLaunchDaw => '无法打开DAW';

  @override
  String get releaseDetails => '发布详情';

  @override
  String get releaseNotFound => '未找到发布';

  @override
  String get error => '错误';

  @override
  String get loading => '加载中...';

  @override
  String get deleteProfile => '删除配置文件';

  @override
  String deleteProfileMessage(String profileName) {
    return '您确定要删除「$profileName」吗？这将删除此配置文件的所有项目、项目文件夹和发布。';
  }

  @override
  String get editProfile => '编辑配置文件';

  @override
  String get changePhoto => '更改照片';

  @override
  String get remove => '删除';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return '您确定要从此发布中删除「$trackName」吗？';
  }

  @override
  String get saveName => '保存名称';

  @override
  String get profilePhotoUpdated => '配置文件照片已更新。';

  @override
  String get profilePhotoRemoved => '配置文件照片已删除。';

  @override
  String profileRenamed(String newName) {
    return '配置文件已重命名为「$newName」';
  }

  @override
  String profileCreated(String name) {
    return '配置文件「$name」创建成功';
  }

  @override
  String profileDeleted(String name) {
    return '配置文件「$name」已删除';
  }

  @override
  String get pleaseEnterProfileName => '请输入配置文件名称';

  @override
  String failedToCreateProfile(String error) {
    return '创建配置文件失败: $error';
  }

  @override
  String get noProfilesFound => '未找到配置文件。请在上面创建一个。';

  @override
  String get clearLibraryTooltip => '清空库（项目和项目文件夹）';

  @override
  String lastModified(String date) {
    return '最后修改: $date';
  }

  @override
  String get name => '名称';

  @override
  String get status => '状态';

  @override
  String get phase => '阶段';

  @override
  String get filterByPhase => '按阶段筛选';

  @override
  String get filters => '筛选器';

  @override
  String get allPhases => '所有阶段';

  @override
  String get filterByDaw => '按DAW筛选';

  @override
  String get allDaws => '所有DAW';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => '清除DAW';

  @override
  String get filterByKey => '按调性筛选';

  @override
  String get allKeys => '所有调性';

  @override
  String get lastModifiedColumn => '最后修改';

  @override
  String get actions => '操作';

  @override
  String get hide => '隐藏';

  @override
  String get unhide => '显示';

  @override
  String get extractMetadata => '提取元数据';

  @override
  String get createRelease => '创建发布';

  @override
  String get clearSelection => '清除选择';

  @override
  String get selectAllProjects => '选择所有项目';

  @override
  String get switchingProfiles => '切换配置文件中...';

  @override
  String get scanningProjects => '扫描项目中...';

  @override
  String scanProgressLabel(int current, int total) {
    return '正在加载第 $current 个项目，共 $total 个…';
  }

  @override
  String get search => '搜索';

  @override
  String get projectsTab => '项目';

  @override
  String get releasesTab => '发布';

  @override
  String get showHidden => '显示隐藏';

  @override
  String get showAll => '显示全部';

  @override
  String get showOnlyHidden => '仅显示隐藏';

  @override
  String get deleteRootPath => '移除项目文件夹';

  @override
  String deleteRootPathMessage(String path) {
    return '您确定要删除「$path」吗？这也会删除此文件夹中不在发布中的所有项目。';
  }

  @override
  String rootsCount(int count) {
    return '项目文件夹: $count';
  }

  @override
  String projectsCount(int count) {
    return '项目: $count';
  }

  @override
  String get hiddenOnly => '（仅隐藏）';

  @override
  String hiddenCount(int count) {
    return '（$count个隐藏）';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count个项目$plural已隐藏。';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count个项目$plural已显示。';
  }

  @override
  String failedToHideProjects(String error) {
    return '隐藏项目失败: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return '显示项目失败: $error';
  }

  @override
  String get deleteMissingProjects => '删除缺失项目';

  @override
  String get deleteMissingProjectsTitle => '删除缺失的项目？';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return '在此设备上找不到文件的$count个项目$plural将被永久删除，包括所有备注、截止日期和会话历史。此操作无法撤销。';
  }

  @override
  String get deleteMissingProjectsConfirmButton => '永久删除';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return '已删除$count个缺失的项目$plural。';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return '同时删除属于发行版的$count个项目$plural（也会将它们从该发行版中移除）';
  }

  @override
  String hideProjectMessage(String projectName) {
    return '您确定要隐藏「$projectName」吗？';
  }

  @override
  String releaseCreated(String title) {
    return '发布「$title」创建成功。';
  }

  @override
  String failedToCreateRelease(String error) {
    return '创建发布失败: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return '添加文件夹错误: $error';
  }

  @override
  String get folderAlreadyAdded => '此文件夹已被添加。';

  @override
  String get noProjectsFoundInRoots => '在选定的项目文件夹中未找到项目。';

  @override
  String get selectProjectsFolder => '选择项目文件夹';

  @override
  String get enterReleaseTitle => '输入发布标题';

  @override
  String get releaseTitle => '发布标题';

  @override
  String get enterReleaseTitleHint => '输入发布标题';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return '已为$count个项目$plural提取元数据。$failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count个失败。';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return '写入BPM文件失败: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return '写入调性文件失败: $error';
  }

  @override
  String failedToLaunch(String error) {
    return '启动失败: $error';
  }

  @override
  String get libraryCleared => '库已清空。';

  @override
  String scanType(String type) {
    return '$type扫描';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type完成: $count个项目$plural已添加/更新。';
  }

  @override
  String get scanCancelled => '扫描已取消。';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count个项目$plural加载失败。';
  }

  @override
  String get scanFailuresSnackbarAction => '详情';

  @override
  String get scanFailuresDialogTitle => '扫描错误';

  @override
  String get scanFailuresDialogIntro => '扫描过程中无法读取以下文件（可能已被删除、移动或被其他程序锁定）：';

  @override
  String projectsSelected(int count, String plural) {
    return '$count个项目$plural已选择';
  }

  @override
  String openingFolder(String projectName) {
    return '正在为$projectName打开文件夹…';
  }

  @override
  String failedToOpenFolder(String error) {
    return '打开文件夹失败: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder => '不支持打开文件夹的操作系统。';

  @override
  String get noProjectsAvailable => '没有可用的项目。请先添加项目。';

  @override
  String get createNewRelease => '创建新发布';

  @override
  String get deleteRelease => '删除发布';

  @override
  String deleteReleaseMessage(String title) {
    return '您确定要删除「$title」吗？';
  }

  @override
  String releaseDeleted(String title) {
    return '发布「$title」已删除。';
  }

  @override
  String releasesSelected(int count, String plural) {
    return '已选择$count个发布$plural';
  }

  @override
  String get deleteSelectedReleases => '删除所选';

  @override
  String deleteSelectedReleasesConfirm(int count, String plural) {
    return '确定要删除$count个发布$plural吗?';
  }

  @override
  String releasesDeleted(int count, String plural) {
    return '已删除$count个发布$plural';
  }

  @override
  String get selectTracks => '选择曲目';

  @override
  String get continueButton => '继续';

  @override
  String get noReleasesYet => '还没有发布';

  @override
  String get createFirstRelease => '通过从项目中选择曲目来创建您的第一个发布';

  @override
  String releasesCount(int count) {
    return '发布（$count）';
  }

  @override
  String errorLoadingReleases(String error) {
    return '加载发布错误: $error';
  }

  @override
  String tracksCount(int count) {
    return '曲目（$count）';
  }

  @override
  String get addTracks => '添加曲目';

  @override
  String get allProjectsAlreadyInRelease => '所有项目已在此发布中。';

  @override
  String addedTracksToRelease(int count, String plural) {
    return '已向发布添加$count首曲目$plural。';
  }

  @override
  String releaseFilesCount(int count) {
    return '发布文件（$count）';
  }

  @override
  String get addFiles => '添加文件';

  @override
  String addedFilesToRelease(int count, String plural) {
    return '已向发布添加$count个文件$plural。';
  }

  @override
  String failedToAddFiles(String error) {
    return '添加文件失败: $error';
  }

  @override
  String get noFilesToDownload => '没有要下载的文件。';

  @override
  String zipFileSaved(String path) {
    return 'ZIP文件已保存到: $path';
  }

  @override
  String get creatingZipFile => '正在创建ZIP文件...';

  @override
  String failedToCreateZip(String error) {
    return '创建ZIP失败: $error';
  }

  @override
  String get selectedFileDoesNotExist => '所选文件不存在。';

  @override
  String get imageSavedSuccessfully => '图像保存成功！';

  @override
  String failedToSaveImage(String error) {
    return '保存图像失败: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return '加载发布错误: $error';
  }

  @override
  String get errorLoadingProjects => '加载项目错误: null';

  @override
  String get releaseSaved => '发布已保存。';

  @override
  String get releaseDate => '发布日期';

  @override
  String failedToSaveReleaseDate(String error) {
    return '保存发布日期失败: $error';
  }

  @override
  String get releaseDateSaved => '发布日期已保存。';

  @override
  String get releaseDateCleared => '发布日期已清除。';

  @override
  String get saveReleaseFilesZip => '保存发布文件ZIP';

  @override
  String get failedToOpenFile => '无法打开文件';

  @override
  String failedToPlayAudio(String error) {
    return '播放音频失败: $error';
  }

  @override
  String get renameFile => '重命名文件';

  @override
  String get selectTracksToAdd => '选择要添加的曲目';

  @override
  String get fileNameUpdated => '文件名已更新。';

  @override
  String errorUpdatingFileName(String error) {
    return '更新文件名错误: $error';
  }

  @override
  String get deleteFile => '删除文件';

  @override
  String deleteFileMessage(String fileName) {
    return '您确定要删除「$fileName」吗？';
  }

  @override
  String fileDeleted(String fileName) {
    return '文件「$fileName」已删除。';
  }

  @override
  String failedToDeleteFile(String error) {
    return '删除文件失败: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return '无法打开文件夹: $error';
  }

  @override
  String get artwork => '封面';

  @override
  String get title => '标题';

  @override
  String get tracks => '曲目';

  @override
  String get description => '描述';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return '选择要包含在发布中的曲目（已选择$count）';
  }

  @override
  String get searchTracks => '搜索曲目';

  @override
  String get searchTracksHint => '按名称或DAW类型搜索';

  @override
  String get noTracksFound => '未找到曲目';

  @override
  String get unknown => '未知';

  @override
  String get fileNotFound => '文件未找到';

  @override
  String get fileName => '文件名';

  @override
  String get editTodo => '编辑待办事项';

  @override
  String get todoText => '待办事项文本';

  @override
  String get enterTodoText => '输入待办事项文本';

  @override
  String get addNewTodo => '添加新待办事项';

  @override
  String get enterTodoItem => '输入待办事项项';

  @override
  String addTodoAtTimestamp(String timestamp) {
    return '在$timestamp添加待办事项';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return '已在$timestamp添加待办事项';
  }

  @override
  String get todoList => '待办事项列表';

  @override
  String get todoTemplates => 'TODO模板';

  @override
  String get createTemplate => '创建模板';

  @override
  String get editTemplate => '编辑模板';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String deleteTemplateConfirm(String name) {
    return '确定要删除模板「$name」吗？';
  }

  @override
  String get templateName => '模板名称';

  @override
  String get templateNameHint => '例如：混音清单';

  @override
  String get templateItems => '模板项目';

  @override
  String get templateItemsHint => '每行一个项目';

  @override
  String get templateNameAndItemsRequired => '模板名称和项目是必需的';

  @override
  String get templateItemsRequired => '至少需要一个项目';

  @override
  String get templateCreated => '模板已创建';

  @override
  String get templateUpdated => '模板已更新';

  @override
  String get templateDeleted => '模板已删除';

  @override
  String get noTemplatesYet => '还没有模板';

  @override
  String get createFirstTemplate => '创建您的第一个TODO模板';

  @override
  String templateItemCount(int count) {
    return '$count个项目';
  }

  @override
  String get selectTemplate => '选择模板';

  @override
  String get importFromTemplate => '从模板导入';

  @override
  String get manageTemplates => '管理模板';

  @override
  String get noTemplatesAvailable => '没有可用的模板。请先创建一个。';

  @override
  String templateImported(String name, int count) {
    return '模板「$name」已导入（$count个项目）';
  }

  @override
  String get errorLoadingTemplates => '加载模板错误';

  @override
  String get createProjectStartFrom => '您想如何开始？';

  @override
  String get createProjectStartFromHint => '从空文件夹开始，或复制已注册的模板。';

  @override
  String get createProjectEmptyFolder => '空文件夹';

  @override
  String get createProjectFromTemplate => '从模板';

  @override
  String get selectTemplateMainFile => '选择模板的主项目文件';

  @override
  String get registerTemplate => '注册模板';

  @override
  String get projectTemplates => '项目模板';

  @override
  String get searchTemplates => '搜索模板...';

  @override
  String get createFirstProjectTemplate => '注册一个模板文件夹以供新项目重复使用';

  @override
  String get noMatchingTemplates => '没有匹配的模板';

  @override
  String get templateSourceMissing => '未找到模板源文件夹';

  @override
  String get useTemplate => '使用';

  @override
  String get selectTemplatesParentFolder => '选择模板的父文件夹';

  @override
  String get templateSourceFolder => '源文件夹';

  @override
  String get dateCreatedColumn => '创建时间';

  @override
  String get dateModifiedColumn => '修改时间';

  @override
  String get manageTemplateFolders => '管理文件夹';

  @override
  String get addTemplateFolder => '添加文件夹';

  @override
  String get removeTemplateFolder => '移除模板文件夹';

  @override
  String removeTemplateFolderConfirm(String path) {
    return '从已注册的模板文件夹中移除“$path”？已导入的模板不会被删除。';
  }

  @override
  String get noTemplateFoldersRegistered => '没有已注册的模板文件夹';

  @override
  String get refreshTemplateFolders => '从已注册的文件夹刷新模板';

  @override
  String lastRefreshed(String date) {
    return '最后刷新时间 $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return '已添加$count个新模板';
  }

  @override
  String templatesSelected(int count, String plural) {
    return '已选择$count个模板$plural';
  }

  @override
  String get deleteSelectedTemplates => '删除所选';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return '确定要删除$count个模板$plural吗?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return '已删除$count个模板$plural';
  }

  @override
  String get templateDetailTitle => 'Template';

  @override
  String get templateNotFound => '未找到模板';

  @override
  String get saveAsTemplate => '另存为模板';

  @override
  String get newTemplateNameLabel => '模板名称';

  @override
  String get savedAsTemplate => '已保存为模板';

  @override
  String get duplicateTemplate => '复制';

  @override
  String get templateDuplicated => '模板已复制';

  @override
  String get fileInfo => '文件信息';

  @override
  String get fileSize => '文件大小';

  @override
  String get filePath => '路径';

  @override
  String get fileModified => '最后修改';

  @override
  String projectsFromThisTemplate(int count) {
    return '从此模板创建的项目（$count个）';
  }

  @override
  String get noProjectsFromThisTemplate => '尚未从此模板创建任何项目';

  @override
  String get importTodos => '从文件导入待办事项';

  @override
  String get noTodosInFile => '文件中未找到待办事项';

  @override
  String todosImported(int count) {
    return '成功导入了$count个待办事项';
  }

  @override
  String errorImportingTodos(String error) {
    return '导入错误: $error';
  }

  @override
  String get addToRelease => '添加到发布';

  @override
  String get createNew => '创建新';

  @override
  String get addToExisting => '添加到现有';

  @override
  String get createAndAdd => '创建并添加';

  @override
  String get selectRelease => '选择发布';

  @override
  String get noExistingReleasesFound => '未找到现有发布。';

  @override
  String get addToSelectedRelease => '添加到选定的发布';

  @override
  String failedToSaveProfilePhoto(String error) {
    return '保存配置文件照片失败: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return '删除配置文件照片失败: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return '重命名配置文件失败: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return '删除配置文件失败: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return '加载配置文件错误: $error';
  }

  @override
  String get projectPhaseIdea => '想法';

  @override
  String get projectPhaseArranging => '编曲';

  @override
  String get projectPhaseMixing => '混音';

  @override
  String get projectPhaseMastering => '母带处理';

  @override
  String get projectPhaseFinished => '完成';

  @override
  String get changeStatus => '更改阶段';

  @override
  String get selectNewStatus => '选择新阶段:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return '$count 个项目$plural的阶段已更改为「$status」';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return '$successCount 个项目$successPlural的阶段已更改为「$status」，$failCount 个失败$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return '更改阶段失败: $error';
  }

  @override
  String get tooltipEditProfileName => '编辑配置文件名称';

  @override
  String get tooltipAddTodo => '添加待办事项';

  @override
  String get tooltipClearDate => '清除日期';

  @override
  String get tooltipPickDate => '选择日期';

  @override
  String get tooltipViewDetails => '查看详情';

  @override
  String get tooltipLaunchInDaw => '在DAW中打开';

  @override
  String get tooltipRemoveFromRelease => '从发布中移除';

  @override
  String get profile => '配置文件';

  @override
  String get noDateSet => '未设置日期';

  @override
  String get imageNotFound => '未找到图像';

  @override
  String get clickToBrowseArtwork => '点击浏览封面';

  @override
  String get dropImageHere => '将图片拖放到此处';

  @override
  String get removeArtwork => '移除封面';

  @override
  String get removeArtworkConfirm => '移除此封面？图片文件将被删除。';

  @override
  String get noFilesAddedYet => '尚未添加文件。\n点击\"添加文件\"上传发布文件。';

  @override
  String get noTodosYet => '还没有待办事项。请在上面添加一个。';

  @override
  String get done => '完成';

  @override
  String get backupAndRestore => '备份和恢复';

  @override
  String get backupTabLabel => '备份';

  @override
  String get aboutTabLabel => '关于';

  @override
  String get localBackup => '本地备份';

  @override
  String get appearanceTabLabel => '外观';

  @override
  String get exportBackup => '导出备份';

  @override
  String get importBackup => '导入备份';

  @override
  String get exportProjectInfo => '导出信息';

  @override
  String get exportProjectInfoTooltip => '将此项目的信息保存为文本文件';

  @override
  String get exportAllProjectsInfo => '将所有项目导出为TXT';

  @override
  String get exportAllProjectsInfoSubtitle => '保存所有项目信息的文本记录，即使以后删除DAW文件也能保留';

  @override
  String get projectInfoExported => '项目信息已导出';

  @override
  String allProjectsInfoExported(int count) {
    return '已导出 $count 个项目的信息';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return '导出项目信息失败：$error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return '导出时间：$dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return '项目总数：$count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return '项目：$name';
  }

  @override
  String projectExportDawLabel(String dawType) {
    return 'DAW：$dawType';
  }

  @override
  String projectExportDawWithVersionLabel(String dawType, String version) {
    return 'DAW：$dawType $version';
  }

  @override
  String projectExportStatusLabel(String status) {
    return '状态：$status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM：$bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return '调性：$key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return '调性：$key（Camelot $code）';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return '文件路径：$path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return '文件大小：$size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return '文件创建日期：$date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return '添加到库的日期：$date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return '最后修改：$date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return '截止日期：$date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return '截止日期：$date（$status）';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return '总工作时长：$duration';
  }

  @override
  String get projectExportNotesLabel => '备注：';

  @override
  String get projectExportTodosLabel => '待办事项：';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return '工作会话（$count）：';
  }

  @override
  String get noProjectsToExport => '没有可导出的项目';

  @override
  String get backupExportedSuccessfully => '备份导出成功';

  @override
  String failedToExportBackup(String error) {
    return '导出备份失败: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return '备份导入成功: $projectsCount 个项目，$rootsCount 个项目文件夹，$releasesCount 个发布';
  }

  @override
  String failedToImportBackup(String error) {
    return '导入备份失败: $error';
  }

  @override
  String get importBackupMessage => '选择如何导入备份:';

  @override
  String get mergeWithCurrentProfile => '与当前活动配置文件合并';

  @override
  String get replaceCurrentProfile => '完全替换当前配置文件（警告：这将删除当前配置文件的所有数据）';

  @override
  String get createNewProfileForImport => '为此数据创建新配置文件';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return '备份已导入到新配置文件 \"$profileName\": $projectsCount 个项目，$rootsCount 个项目文件夹，$releasesCount 个发布';
  }

  @override
  String get noProfileSelected => '未选择配置文件';

  @override
  String get exportBackupDialogTitle => '导出备份';

  @override
  String get importBackupDialogTitle => '导入备份';

  @override
  String get invalidBackupFileFormat => '无效的备份文件格式: 缺少版本';

  @override
  String get profileNameRequiredForNewProfile => '创建新配置文件时需要配置文件名称';

  @override
  String get currentProfileRequired => '合并或替换模式需要当前配置文件';

  @override
  String get previewSong => '预览歌曲';

  @override
  String get noPreviewSongTitle => '无预览歌曲';

  @override
  String get noPreviewSongMessage => '此项目未设置预览歌曲。选择一个音频文件以加载并播放它。';

  @override
  String get noPreviewSongDragHint => '您也可以将音频文件直接拖放到表格中的项目行上。';

  @override
  String get previewSongRemoved => '预览歌曲已删除';

  @override
  String get previewSongAdded => '预览歌曲已添加';

  @override
  String get previewSongFileNotFound => '未找到预览歌曲文件';

  @override
  String get previewSongFileNotFoundMessage => '在磁盘上找不到预览歌曲文件。您想选择新文件还是删除该条目？';

  @override
  String get selectNewFile => '选择新文件';

  @override
  String failedToPlayPreview(String error) {
    return '播放预览失败: $error';
  }

  @override
  String get removePreviewSong => '删除预览歌曲';

  @override
  String get removePreviewSongConfirm => '您确定要删除预览歌曲吗？此操作无法撤销。';

  @override
  String get noPreviewSongSelected => '未选择预览歌曲';

  @override
  String get changePreviewSong => '更改预览歌曲';

  @override
  String get selectPreviewSong => '选择预览歌曲';

  @override
  String get dropAudioFileHere => '将音频文件拖放到此处';

  @override
  String projectAge(String age) {
    return '项目年龄: $age';
  }

  @override
  String createdDate(String date) {
    return '创建于 $date';
  }

  @override
  String completedIn(String duration) {
    return '完成耗时: $duration';
  }

  @override
  String finishedDate(String date) {
    return '完成于 $date';
  }

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count天前',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count周前',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个月前',
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
    return '$years年$months个月';
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
    return '$months个月$days天';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months个月';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days天';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours小时';
  }

  @override
  String get ageJustNow => '刚刚';

  @override
  String get ageLessThanHour => '不到一小时';

  @override
  String get viewProfile => '查看个人资料';

  @override
  String get googleDriveSync => 'Google Drive 同步';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      '将您的数据与 Google Drive 同步，以便在设备之间备份和恢复。';

  @override
  String get manageGoogleDriveSync => '管理 Google Drive 同步';

  @override
  String get signInToGoogleDrive => '登录 Google Drive';

  @override
  String get syncNow => '立即同步';

  @override
  String get uploadBackup => '上传备份';

  @override
  String get downloadBackup => '下载备份';

  @override
  String get newerBackupAvailable => '云端有新备份可用';

  @override
  String get restoreProjectFromDrive => '从Drive恢复';

  @override
  String get restoringProjectFromDrive => '正在从Drive恢复...';

  @override
  String get projectRestoredFromDrive => '项目已从Drive恢复';

  @override
  String get projectNotFoundInBackup => '在Drive备份中未找到此项目';

  @override
  String get signInToGoogleDriveFirst => '请先登录Google Drive（打开Drive同步设置）';

  @override
  String get signOut => '退出';

  @override
  String get downloadPreviewSongs => '下载预览歌曲';

  @override
  String get downloadPreviewSongsExplanation =>
      '如果未选中，将跳过预览歌曲（节省时间和存储空间）。如果需要，您可以稍后下载它们。';

  @override
  String get replaceLocalData => '替换本地数据';

  @override
  String get downloadBackupConfirmation =>
      '这将用 Google Drive 的备份替换您的本地数据。\n\n您确定要继续吗？';

  @override
  String get enterAuthorizationCode => '输入授权代码';

  @override
  String get authorizationCode => '授权代码';

  @override
  String get pasteCodeFromBrowser => '从浏览器粘贴代码';

  @override
  String get sessionActive => '会话活跃';

  @override
  String get signedIn => '已登录';

  @override
  String get creatingInitialBackup => '正在创建初始备份...';

  @override
  String get successfullySignedInAndBackedUp => '成功登录并备份到 Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage => '成功登录并备份到 Google Drive！';

  @override
  String get successfullySignedInToGoogleDrive => '成功登录到 Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage => '成功登录到 Google Drive！';

  @override
  String get signInCancelledOrFailed => '登录已取消或失败。请查看控制台了解详细信息。';

  @override
  String get failedToLaunchBrowser => '无法启动浏览器';

  @override
  String get signInCancelled => '登录已取消';

  @override
  String get failedToExchangeAuthorizationCode => '无法交换授权代码';

  @override
  String errorSigningIn(String error) {
    return '登录错误: $error';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String get googleSignInError => 'Google 登录错误';

  @override
  String get developerConsoleNotSetUp =>
      '开发者控制台未正确设置。请在 Google Cloud Console 中检查您的 OAuth 配置。';

  @override
  String get platformError => '平台错误';

  @override
  String get signedOutFromGoogleDrive => '已退出 Google Drive';

  @override
  String errorSigningOut(String error) {
    return '退出错误: $error';
  }

  @override
  String get syncing => '同步中...';

  @override
  String get errorNoProfileSelected => '错误: 未选择个人资料';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '同步完成！项目: +$projectsAdded ~$projectsUpdated，发布: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return '同步错误: $error';
  }

  @override
  String get uploadingBackup => '正在上传备份...';

  @override
  String get backupUploadedSuccessfully => '备份上传成功！';

  @override
  String get backupUploadedSuccessfullyMessage => '备份已成功上传到 Google Drive！';

  @override
  String errorUploadingBackup(String error) {
    return '上传备份错误: $error';
  }

  @override
  String get downloadingBackup => '正在下载备份...';

  @override
  String get checkingForBackup => '正在检查备份...';

  @override
  String get backupUpToDate => '备份是最新的';

  @override
  String errorCheckingBackup(String error) {
    return '检查备份错误: $error';
  }

  @override
  String get download => '下载';

  @override
  String get remoteBackupIsNewer => '远程备份比本地数据更新。上传将覆盖它。';

  @override
  String get confirmUpload => '确认上传';

  @override
  String get noBackupFileFound => '在 Google Drive 中未找到备份文件。请先通过同步数据创建备份。';

  @override
  String get noBackupFileFoundStatus => '未找到备份文件。请先创建备份。';

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return '备份已下载！项目: +$projectsAdded ~$projectsUpdated，发布: +$releasesAdded ~$releasesUpdated';
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
    return '备份已下载!\n\n项目:\n  • $projectsAdded 已添加\n  • $projectsUpdated 已更新\n\n发布:\n  • $releasesAdded 已添加\n  • $releasesUpdated 已更新\n\n预览歌曲:\n  • $previewSongsDownloaded 已下载\n  • $previewSongsUpdated 已更新';
  }

  @override
  String errorDownloadingBackup(String error) {
    return '下载备份错误: $error';
  }

  @override
  String get notSignedInYet => '未登录';

  @override
  String get never => '从未';

  @override
  String signedInAs(String email) {
    return '登录为: $email';
  }

  @override
  String lastSync(String date) {
    return '最后同步: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return '远程备份: $date';
  }

  @override
  String lastUploadTime(String date) {
    return '上次上传: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return '上次下载: $date';
  }

  @override
  String get checkForBackup => '检查备份';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get notificationsOnlyOnAndroid => '截止日期通知仅在Android设备上可用。';

  @override
  String get notificationPermissionRequired => '需要通知权限';

  @override
  String get notificationPermissionDescription => '请启用通知以接收截止日期提醒。';

  @override
  String get notificationPermissionDenied => '通知权限被拒绝。请在设置中启用。';

  @override
  String get notificationSettingsSaved => '通知设置已成功保存';

  @override
  String get errorSavingSettings => '保存设置时出错';

  @override
  String get enableDeadlineNotifications => '启用截止日期通知';

  @override
  String get receiveRemindersForDeadlines => '接收项目截止日期提醒';

  @override
  String get notificationTime => '通知时间';

  @override
  String get timeToReceiveNotifications => '接收通知的时间';

  @override
  String get reminderDays => '提醒天数';

  @override
  String get selectDaysBeforeDeadline => '选择在截止日期前多少天收到通知';

  @override
  String get notifyOnDeadlineDay => '在截止日期当天通知';

  @override
  String get receiveNotificationOnDeadlineDay => '在截止日期当天也接收通知';

  @override
  String get howItWorks => '工作原理';

  @override
  String get deadlineNotificationsHelp =>
      '您将在每个项目截止日期前的选定天数在指定时间收到通知。点击通知以打开项目详情。';

  @override
  String get oneDay => '1天';

  @override
  String xDays(int count) {
    return '$count天';
  }

  @override
  String get settings => '设置';

  @override
  String get searchSettings => '搜索设置';

  @override
  String noSettingsFoundFor(String query) {
    return '未找到与\"$query\"相关的设置';
  }

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get languageSettingDescription => '整个应用程序中使用的语言。';

  @override
  String get themeSettingDescription => '应用程序的配色主题。';

  @override
  String get waveformStyle => '波形样式';

  @override
  String get waveformStyleSettingDescription => '音频预览波形的绘制方式。';

  @override
  String get waveformStyleDetailed => '精细';

  @override
  String get waveformStyleDetailedDescription => '逐像素条形并带阴影主体，类似 DAW。';

  @override
  String get waveformStyleClassic => '经典';

  @override
  String get waveformStyleClassicDescription => '单一填充轮廓。';

  @override
  String get waveformChannels => '声道';

  @override
  String get waveformChannelsSettingDescription => '波形是否将立体声分为两条轨道。';

  @override
  String get waveformChannelsSingle => '单条';

  @override
  String get waveformChannelsDual => '双条';

  @override
  String get waveformChannelsSingleDescription => '一条轨道显示立体声混音。';

  @override
  String get waveformChannelsDualDescription => '左右声道分为上下两条轨道。';

  @override
  String get waveformChannelsUnavailable => '此文件只有一个声道';

  @override
  String get support => '支持';

  @override
  String get shareDiagnosticLog => '分享诊断日志';

  @override
  String get shareDiagnosticLogEmpty => '暂无诊断日志';

  @override
  String get shareDiagnosticLogFolderOpened =>
      '此环境不支持分享——已改为打开日志文件夹，您可以手动附加该文件。';

  @override
  String get enableDiagnosticLogging => '启用诊断日志';

  @override
  String get enableDiagnosticLoggingDescription =>
      '在此设备上保留崩溃和错误的简要日志，以便在出现问题时分享。默认关闭。';

  @override
  String get clearDiagnosticLog => '清除诊断日志';

  @override
  String get clearDiagnosticLogConfirmTitle => '清除诊断日志？';

  @override
  String get clearDiagnosticLogConfirmMessage => '这将永久删除诊断日志文件，且无法撤销。';

  @override
  String get diagnosticLogCleared => '诊断日志已清除';

  @override
  String get supportTheProject => '支持项目';

  @override
  String couldNotOpenBrowser(String url) {
    return '无法打开浏览器。请访问: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return '打开浏览器时出错: $error';
  }

  @override
  String get generateTestingDatabase => '生成测试数据库';

  @override
  String get generateTestingDatabaseMessage =>
      '这将创建（或刷新）一个专用的“Demo — Screenshots”配置文件，其中包含涵盖所有受支持 DAW 的大量示例项目、发行版和播放列表，并切换到该配置文件。您的其他配置文件不会受到影响。继续吗？';

  @override
  String get testingDatabaseGenerated => '演示配置文件已就绪 — 已切换！';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return '生成测试数据库失败: $error';
  }

  @override
  String get removeTestingDatabase => '删除测试数据库';

  @override
  String get removeTestingDatabaseMessage =>
      '这将永久删除“Demo — Screenshots”配置文件及其所有示例项目、发行版、播放列表和预览音频文件。继续吗？';

  @override
  String get testingDatabaseRemoved => '演示数据已删除。';

  @override
  String get noTestingDatabaseFound => '未找到可删除的演示数据。';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return '删除测试数据库失败: $error';
  }

  @override
  String get playlists => '播放列表';

  @override
  String get playlistsDesktopOnly => '播放列表仅在Android上可用。';

  @override
  String get noPlaylistsYet => '还没有播放列表';

  @override
  String get createFirstPlaylist => '点击+按钮创建您的第一个播放列表';

  @override
  String playlistSongCount(int count) {
    return '$count首歌曲';
  }

  @override
  String get createPlaylist => '创建播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get playlistNameHint => '我的播放列表';

  @override
  String get playlistNameRequired => '需要播放列表名称';

  @override
  String get editPlaylist => '编辑播放列表';

  @override
  String get stopPlaybackBeforeEditing => '请在编辑播放列表之前停止播放';

  @override
  String get selectPreviewSongs => '选择预览歌曲';

  @override
  String get deletePlaylist => '删除播放列表';

  @override
  String deletePlaylistConfirm(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get playlistDeleted => '播放列表已删除';

  @override
  String get errorDeletingPlaylist => '删除播放列表错误';

  @override
  String get playlistUpdated => '播放列表已更新';

  @override
  String get changeSong => '更换歌曲';

  @override
  String get changeSongConfirm => '当前正在播放歌曲。是否要切换到这首歌曲？';

  @override
  String get changeSongButton => '更换';

  @override
  String playlistProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get noPreviewSongsInPlaylist => '此播放列表中没有预览歌曲';

  @override
  String get tapEditToAddSongs => '点击编辑以向此播放列表添加歌曲';

  @override
  String get noProjectsAvailableForPlaylist => '没有可添加的预览歌曲项目';

  @override
  String get noProjectsInDatabase => '数据库中未找到项目。请先同步您的项目。';

  @override
  String get firstTimeSyncTitle => '看起来这是您第一次来这里！';

  @override
  String get firstTimeSyncMessage => '让我们从Google云端硬盘同步您的数据以开始使用';

  @override
  String get syncWithGoogleDrive => '与Google云端硬盘同步';

  @override
  String get errorLoadingPlaylists => '加载播放列表错误';

  @override
  String get playlistItems => '播放列表项目';

  @override
  String get addSongs => '添加歌曲';

  @override
  String get addAudioFiles => '添加音频文件';

  @override
  String get selectAudioFiles => '选择音频文件';

  @override
  String get selectFromProjects => '从项目中选择';

  @override
  String get add => '添加';

  @override
  String get addTaskAtTimestamp => '在当前时间添加任务';

  @override
  String get taskDescriptionHint => '任务描述';

  @override
  String get taskAdded => '已添加任务';

  @override
  String get fromProject => '来自项目';

  @override
  String get projectDeadline => '项目截止日期';

  @override
  String get noDeadlineSet => '未设置截止日期';

  @override
  String get camelotCode => 'Camelot代码';

  @override
  String get deadline => '截止日期';

  @override
  String get dueToday => '今天到期';

  @override
  String daysLate(int days) {
    return '$days天延期';
  }

  @override
  String daysLeft(int days) {
    return '剩余$days天';
  }

  @override
  String get hideFinished => '隐藏已完成';

  @override
  String get showOnlyDeadlines => '显示截止日期';

  @override
  String get filterByDeadline => '按截止日期筛选';

  @override
  String get allDeadlines => '所有截止日期';

  @override
  String get hasDeadline => '有截止日期';

  @override
  String get overdue => '逾期';

  @override
  String get dueSoon => '即将到期 (7天)';

  @override
  String get today => '今天';

  @override
  String get noPreviewSong => '无预览';

  @override
  String get playPreview => '播放预览';

  @override
  String get uploadCancelled => '上传已取消';

  @override
  String get backupUploadCancelledByUser => '用户取消了备份上传';

  @override
  String get collectingData => '正在收集数据...';

  @override
  String get uploadingPreviewSongs => '正在上传预览歌曲...';

  @override
  String get uploadingProfilePhotos => '正在上传个人资料照片...';

  @override
  String get uploadingReleaseArtwork => '正在上传发行封面...';

  @override
  String get uploadingDatabase => '正在上传数据库...';

  @override
  String get completed => '完成！';

  @override
  String get cancelling => '正在取消...';

  @override
  String get uploadingBackupTitle => '正在上传备份';

  @override
  String get cancellingUpload => '正在取消上传...';

  @override
  String get pleaseWaitCancellingUpload => '请稍候，我们正在停止上传...';

  @override
  String get downloadingDatabase => '正在下载数据库...';

  @override
  String get downloadingPreviewSongs => '正在下载预览歌曲...';

  @override
  String get downloadingProfilePhotos => '正在下载个人资料照片...';

  @override
  String get downloadingReleaseArtwork => '正在下载发行封面...';

  @override
  String get mergingData => '正在合并数据...';

  @override
  String get downloadingBackupTitle => '正在下载备份';

  @override
  String get sourceFileNotFoundOnThisMachine => '在此设备上找不到源文件';

  @override
  String get metadataExtractionNotSupportedForDaw => '此 DAW 不支持元数据提取';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      '在此设备上找不到源文件 — 仅元数据模式。您仍然可以编辑和导出元数据。';

  @override
  String get previewSongNotAvailableDownloadFirst => '预览歌曲不可用。请先下载备份。';

  @override
  String get sharePreviewSong => '分享预览歌曲';

  @override
  String get shareAsZip => '以ZIP格式分享';

  @override
  String get share => '分享';

  @override
  String get convertingAudioForSharing => '正在准备要分享的音频…';

  @override
  String get shareSheetUnavailable =>
      '系统分享菜单在此不可用——请改用歌曲预览中的“拖动以分享”按钮，将文件拖到其他应用中。';

  @override
  String get dragToShare => '拖动以分享';

  @override
  String get dragToShareTooltip =>
      '把它拖到另一个应用的窗口（例如 WhatsApp）即可直接分享文件——当“分享”按钮无法打开分享菜单时很有用。';

  @override
  String get mp3ConversionFailed =>
      '此系统不支持音频转换——将分享原始文件，但某些应用（如 WhatsApp）可能会拒绝该文件。';

  @override
  String get shareZip => '分享ZIP';

  @override
  String get saveCopy => '保存副本';

  @override
  String savedCopyTo(String path) {
    return '已保存到 $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return '无法分享预览歌曲：$error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return '无法以ZIP格式分享预览歌曲：$error';
  }

  @override
  String get biographySaved => '简介已保存';

  @override
  String failedToSaveBiography(String error) {
    return '无法保存简介：$error';
  }

  @override
  String fileSavedTo(String filename) {
    return '文件已保存至 $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return '无法下载文件：$error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return '所有文件已保存至 $filename';
  }

  @override
  String get artworkAdded => '封面已添加';

  @override
  String failedToAddArtwork(String error) {
    return '无法添加封面：$error';
  }

  @override
  String get artworkRemoved => '封面已删除';

  @override
  String failedToRemoveArtwork(String error) {
    return '无法删除封面：$error';
  }

  @override
  String get pressKitFileAdded => '新闻资料袋文件已添加';

  @override
  String failedToAddPressKitFile(String error) {
    return '无法添加新闻资料袋文件：$error';
  }

  @override
  String get pressKitFileRemoved => '新闻资料袋文件已删除';

  @override
  String failedToRemovePressKitFile(String error) {
    return '无法删除新闻资料袋文件：$error';
  }

  @override
  String get selectFilesToDownload => '选择要下载的文件';

  @override
  String get biography => '简介';

  @override
  String get biographyWillBeSaved => '将保存为 biography.txt';

  @override
  String get artworkFiles => '封面文件';

  @override
  String get pressKitFiles => '新闻资料袋文件';

  @override
  String get additionalAssets => '附加资源';

  @override
  String downloadNFiles(int count, String plural) {
    return '下载 $count 个文件$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count 个文件$plural已保存至 $filename';
  }

  @override
  String get addAsset => '添加资源';

  @override
  String get assetNameLabel => '资源名称';

  @override
  String get assetNameHint => '例如：Logo、横幅、照片';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName 已成功添加';
  }

  @override
  String failedToAddAsset(String error) {
    return '无法添加资源：$error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName 已删除';
  }

  @override
  String failedToRemoveAsset(String error) {
    return '无法删除资源：$error';
  }

  @override
  String get profileNotFound => '找不到个人资料';

  @override
  String get downloadFilesSectionTitle => '下载文件';

  @override
  String get downloadFilesSectionDescription =>
      '将此档案的所有文件——简介、封面、新闻资料包和附加资源——下载为一个ZIP压缩包，或选择要包含的文件。';

  @override
  String get selectFiles => '选择文件';

  @override
  String get downloadAll => '全部下载';

  @override
  String get saveBiographyTooltip => '保存简介';

  @override
  String get enterBiographyHint => '输入个人简介...';

  @override
  String get addArtwork => '添加封面';

  @override
  String get addFile => '添加文件';

  @override
  String get openFile => '打开文件';

  @override
  String get menuView => '视图';

  @override
  String get menuAbout => '关于 DAW Project Manager';

  @override
  String get menuDocumentation => '文档';

  @override
  String get menuLanguage => '语言';

  @override
  String get menuWarnBeforeQuit => '退出前警告 (⌘+Q)';

  @override
  String get menuQuit => '退出 DAW Project Manager';

  @override
  String get quitConfirmTitle => '退出 DAW Project Manager？';

  @override
  String get quitConfirmMessage => '确定要退出吗？';

  @override
  String get quit => '退出';

  @override
  String get trayNoticeTitle => '仍在后台运行';

  @override
  String get trayNoticeBody => 'DAW Project Manager 已最小化到系统托盘。使用托盘图标可重新打开或退出。';

  @override
  String get trayShowWindow => '显示 DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return '上次备份：$when';
  }

  @override
  String get trayNeverBackedUp => '尚未备份';

  @override
  String get trayBackupNow => '立即备份';

  @override
  String get trayPauseSession => '暂停会话';

  @override
  String get trayResumeSession => '恢复会话';

  @override
  String get closeToTray => '关闭到系统托盘';

  @override
  String get closeToTrayDescription => '关闭窗口后继续在后台运行（系统托盘图标），以便自动备份和通知继续工作';

  @override
  String get autoStart => '开机自动启动';

  @override
  String get autoStartDescription => '登录电脑时自动打开 DAW Project Manager';

  @override
  String get startMinimized => '启动时最小化到托盘';

  @override
  String get startMinimizedDescription => '随电脑启动时，将应用隐藏在托盘中，而不显示窗口';

  @override
  String get onboardingStartMinimized => '最小化启动';

  @override
  String get autoStartFailed => '无法更改开机启动设置。您的系统可能不允许此操作。';

  @override
  String get onboardingStartupTitle => '开机自动启动';

  @override
  String get onboardingStartupBody =>
      '登录时自动打开 DAW Project Manager，让后台备份和截止日期提醒持续运行。';

  @override
  String get menuWindow => '窗口';

  @override
  String get donate => '捐赠';

  @override
  String get website => '网站';

  @override
  String get license => '许可证';

  @override
  String get reportIssue => '报告问题';

  @override
  String get switchToClassicDark => '切换到 Classic Dark';

  @override
  String get switchToNeonDark => '切换到 Neon Dark';

  @override
  String get switchToClassicTheme => '切换到经典主题';

  @override
  String get switchToNeonTheme => '切换到霓虹主题';

  @override
  String get switchToStudioLight => '切换到 Studio Light';

  @override
  String get menuTheme => '主题';

  @override
  String get appDescription => '面向音乐制作人和音效设计师的项目管理工具。';

  @override
  String get neonDarkThemeName => '霓虹暗色';

  @override
  String get classicDarkThemeName => '经典暗色';

  @override
  String get studioLightThemeName => '工作室亮色';

  @override
  String get statisticsTab => '统计';

  @override
  String get statsTotalProjects => '总项目数';

  @override
  String get statsInProgress => '进行中';

  @override
  String get statsFinished => '已完成';

  @override
  String get statsAvgCompletion => '平均完成时间';

  @override
  String get statsPhaseDistribution => '各阶段项目';

  @override
  String get statsAvgTimePerPhase => '每阶段平均天数';

  @override
  String get statsProductivity => '生产力';

  @override
  String get statsCreatedSeries => '已创建';

  @override
  String get statsProjectHealth => '项目年龄与健康';

  @override
  String get statsCatalogInsights => '目录洞察';

  @override
  String get statsBpmDistribution => 'BPM分布';

  @override
  String get statsTopKeys => '热门音乐调式';

  @override
  String get statsDawTypes => 'DAW类型';

  @override
  String get statsProjectActivity => '项目活动';

  @override
  String get statsSingleProjectActivity => '项目活动';

  @override
  String get statsNoData => '暂无数据';

  @override
  String get statsNoPhaseData => '项目变更阶段后将显示数据。';

  @override
  String statsLastActivityDaysAgo(int days) {
    return '最近活动: $days天前';
  }

  @override
  String get statsLastActivityToday => '今日活跃';

  @override
  String get statsNoEvents => '暂无事件记录';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return '阶段: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return '已更新: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return '已完成: $text';
  }

  @override
  String get statsEventFileModified => '磁盘上的文件已修改';

  @override
  String get statsClearHistory => '清除历史';

  @override
  String get statsClearHistoryConfirm => '清除此项目的所有记录事件？';

  @override
  String get statsSearchProjects => '搜索项目…';

  @override
  String statsEventCount(int count) {
    return '$count个事件';
  }

  @override
  String get statsViewHistory => '项目统计';

  @override
  String get statsPhaseHistory => '阶段历史';

  @override
  String get statsEventBreakdown => '事件概览';

  @override
  String statsDaysSoFar(int days) {
    return '已$days天';
  }

  @override
  String get statsNoProjectsFound => '未找到项目';

  @override
  String statsNotTouchedDays(int days) {
    return '$days天未修改';
  }

  @override
  String get sortByLastModified => '最后修改';

  @override
  String get sortByName => '名称';

  @override
  String get sortByPhase => '阶段';

  @override
  String get sortByCreatedAt => '添加日期';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => '最新优先';

  @override
  String get sortOldestFirst => '最早优先';

  @override
  String get sortTitleAZ => '标题 A–Z';

  @override
  String get sortTitleZA => '标题 Z–A';

  @override
  String get musicPlayerTab => '音乐播放器';

  @override
  String get previewAudioChangedRefreshing => '预览音频在磁盘上已更改 — 正在刷新波形…';

  @override
  String get audioFileChangedRefreshing => '音频文件在磁盘上已更改 — 正在刷新波形…';

  @override
  String get autoFitAllColumns => '自动调整列';

  @override
  String get uploadAutoDetectedPreviewSongs => '上传自动检测到的预览歌曲';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      '包括扫描器自动找到的歌曲，而不仅仅是手动设置的歌曲。';

  @override
  String get monoGenerating => '单声道…';

  @override
  String errorHandlingDroppedFiles(String error) {
    return '处理拖放文件时出错：$error';
  }

  @override
  String get resetOnboardingConfirm => '这将重新启动设置向导。是否继续？';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return '无法启动 $daw：$error';
  }

  @override
  String get couldNotOpenLink => '无法打开链接。';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => '单声道';

  @override
  String get monoToggleTooltip => '切换单声道播放';

  @override
  String get monoRequiresWav => '单声道混音需要WAV文件';

  @override
  String get monoUnsupportedFormat => '无法创建单声道混音 — 不支持的格式';

  @override
  String monoSwitchFailed(String error) {
    return '切换单声道失败：$error';
  }

  @override
  String get analyzeLabel => '分析';

  @override
  String get reAnalyzeLabel => '重新分析';

  @override
  String get analysisRequiresWav => '分析需要WAV文件';

  @override
  String get noResultsForFilter => '当前筛选条件无结果';

  @override
  String get noResultsForFilterHint => '请尝试调整搜索或筛选条件。';

  @override
  String get noProjectsFound => '未找到项目';

  @override
  String get noProjectsFoundHint => '请在设置中添加根文件夹以开始使用。';

  @override
  String get noProjectsFoundInFoldersHint => '请尝试添加另一个包含 DAW 项目的文件夹。';

  @override
  String get queueTab => '任务';

  @override
  String get queueSearchHint => '搜索任务...';

  @override
  String get queueNoPendingTasks => '全部完成！';

  @override
  String get queueNoPendingTasksHint => '您的项目中没有待处理的任务。';

  @override
  String get queueNoMatchingTasks => '未找到匹配的任务';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$projects个项目中有$tasks个待处理任务';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager $version';
  }

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get renameProjectFileTitle => '重命名项目文件';

  @override
  String get renameFileButtonLabel => '重命名文件';

  @override
  String get newFileNameLabel => '新文件名（不含扩展名）';

  @override
  String renameAlreadyExists(String name) {
    return '名为“$name”的文件已存在。';
  }

  @override
  String renameSuccess(String name) {
    return '已重命名为“$name”';
  }

  @override
  String renameFailed(String error) {
    return '重命名失败：$error';
  }

  @override
  String get nameCannotBeEmpty => '名称不能为空';

  @override
  String get nameInvalidCharacters => '名称不能包含 / \\ :';

  @override
  String get alsoRenameContainingFolder => '同时重命名所在文件夹';

  @override
  String get renameButton => '重命名';

  @override
  String get previewMixdownFolderTitle => '预览混音文件夹';

  @override
  String get previewMixdownFolderSubtitle =>
      '自动检测预览歌曲时，按顺序优先检查每个项目文件夹内的子文件夹名称。留空则使用DAW默认值。';

  @override
  String get previewMixdownFolderHint => '例如：Mixdowns';

  @override
  String get mixdownFoldersInfoTooltip => '工作原理';

  @override
  String get mixdownFoldersInfoDialogTitle => '预览检测的工作原理';

  @override
  String get mixdownFoldersInfoDialogBody =>
      '当项目没有手动选择的预览歌曲时，应用会查找最近修改的音频文件用作预览。它会先按顺序检查下面的自定义文件夹，然后再根据项目的DAW使用默认文件夹名称列表。';

  @override
  String get mixdownFoldersDawDefaultsHeading => '各DAW的默认文件夹';

  @override
  String get mixdownFoldersOtherDawLabel => '其他 / 未识别的DAW';

  @override
  String get addMixdownFolder => '添加';

  @override
  String get noCustomMixdownFolders => '未添加自定义文件夹 — 将使用DAW默认值。';

  @override
  String get mixdownFoldersTabLabel => '混音文件夹';

  @override
  String get mixdownFoldersSectionDescription =>
      '控制应用程序在哪个文件夹中查找项目导出/缩混的音频，当未手动设置预览曲目时会使用它。展开下方的DAW可查看默认检查的文件夹名称，如果你的设置使用不同的名称，也可以自行添加。';

  @override
  String get mixdownFoldersDefaultsLabel => '默认检查的文件夹：';

  @override
  String get mixdownFoldersCustomLabel => '你为此DAW添加的文件夹：';

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
    return 'DAW：$daw';
  }

  @override
  String bpmInfoLabel(String bpm) {
    return 'BPM：$bpm';
  }

  @override
  String keyInfoLabel(String key) {
    return '调性：$key';
  }

  @override
  String get audioFileNotFound => '找不到音频文件';

  @override
  String errorPlayingAudio(String error) {
    return '播放音频时出错：$error';
  }

  @override
  String get notificationTestTitle => '测试通知以验证时区和计划：';

  @override
  String get notificationSendNow => '立即发送';

  @override
  String get notificationSchedule30s => '计划 +30秒';

  @override
  String get notificationShowDebugInfo => '显示调试信息';

  @override
  String get notificationRescheduleAll => '重新计划全部';

  @override
  String get notificationTestSent => '✅ 测试通知已发送！';

  @override
  String get notificationTestScheduled => '✅ 测试通知已计划在 30 秒后发送！请查看控制台日志。';

  @override
  String notificationTestError(String error) {
    return '❌ 错误：$error';
  }

  @override
  String get notificationDebugTitle => '🐛 调试信息';

  @override
  String get autoDetected => '自动检测';

  @override
  String get matchedInDescription => '在描述中匹配';

  @override
  String get matchedInProjectNotes => '在 DAW 项目备注中匹配';

  @override
  String get relocateFolderDialogTitle => '重新定位文件夹';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已更新$count个项目路径',
      one: '已更新1个项目路径',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => '自定义标签页';

  @override
  String get alwaysVisible => '（始终可见）';

  @override
  String get customizeTabsDescription => '选择在导航栏中显示哪些标签页。项目标签页始终可见。';

  @override
  String get keyboardShortcuts => '键盘快捷键';

  @override
  String get shortcutGroupGlobal => '全局';

  @override
  String get shortcutGroupProjectsTable => '项目表格（表格必须处于焦点状态）';

  @override
  String get shortcutGroupReleasesTable => '发行表格（表格必须处于焦点状态）';

  @override
  String get shortcutGroupNavigation => '导航';

  @override
  String get shortcutFocusSearch => '聚焦搜索栏';

  @override
  String get shortcutRescan => '重新扫描项目文件夹';

  @override
  String get shortcutFocusTable => '聚焦项目表格';

  @override
  String get shortcutPlayPause => '播放 / 暂停预览歌曲';

  @override
  String get shortcutOpenInDaw => '在DAW中打开项目';

  @override
  String get shortcutViewDetails => '查看项目详情';

  @override
  String get shortcutOpenFolder => '打开项目文件夹';

  @override
  String get shortcutNavigateRows => '导航行';

  @override
  String get shortcutEditCell => '打开项目详情';

  @override
  String get shortcutViewRelease => '查看发行详情';

  @override
  String get shortcutGoBack => '返回';

  @override
  String get shortcutGroupProjectsTableStandardMode => '标准模式';

  @override
  String get shortcutGroupProjectsTableSessionMode => '会话模式';

  @override
  String get shortcutToggleSession => '开始 / 结束会话';

  @override
  String get shortcutGroupPreviewPlayer => '预览播放器';

  @override
  String get shortcutPlayerPlayPause => '播放 / 暂停';

  @override
  String get shortcutPlayerSeek5 => '快进/快退 ±5 秒';

  @override
  String get shortcutPlayerSeek30 => '快进/快退 ±30 秒';

  @override
  String get startupDialogTitle => '欢迎使用 DAW Project Manager';

  @override
  String get startupDialogSubtitle => '添加项目文件夹或从 Google Drive 备份恢复以开始使用。';

  @override
  String get startupAddFolderTitle => '添加项目文件夹';

  @override
  String get startupAddFolderSubtitle => '选择包含您 DAW 项目的文件夹。';

  @override
  String get startupGoogleDriveTitle => '同步 Google Drive 备份';

  @override
  String get startupGoogleDriveSubtitle => '从 Google Drive 备份中恢复您的项目。';

  @override
  String get startupDontShowAgain => '启动时不再显示';

  @override
  String get pinnedLibraryWarningTitle => '正在使用测试库';

  @override
  String get pinnedLibraryWarningBody =>
      '此版本将数据保存在单独的测试库中，因此不会影响已安装应用所使用的库。你在这里更改的项目、配置文件和设置不会出现在那里。';

  @override
  String get pinnedLibraryWarningLibraryLabel => '库';

  @override
  String get pinnedLibraryWarningLocationLabel => '位置';

  @override
  String get pinnedLibraryWarningDontShowAgain => '不再为此库发出警告';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get deleteAllDataSubtitle => '从此设备删除所有配置文件、项目、发行版、播放列表和设置。';

  @override
  String get deleteAllDataConfirm1Title => '删除所有数据？';

  @override
  String get deleteAllDataConfirm1Message =>
      '这将永久删除此设备上的所有配置文件、项目、发行版、播放列表和设置。您的 Google Drive 备份（如有）不受影响。';

  @override
  String get deleteAllDataConfirm2Title => '您绝对确定吗？';

  @override
  String get deleteAllDataConfirm2Message => '此操作无法撤销。应用将恢复到初始状态。';

  @override
  String get deleteEverything => '删除所有内容';

  @override
  String get allDataDeleted => '所有数据已被删除。';

  @override
  String get newerExportFound => '找到更新的导出文件';

  @override
  String newerExportFoundMessage(String filename) {
    return '在同一文件夹中找到了更新的文件：\n$filename\n\n是否替换预览歌曲？';
  }

  @override
  String get replaceAndPlay => '替换并播放';

  @override
  String get keepCurrent => '保留当前';

  @override
  String get autoBackup => '自动备份';

  @override
  String get autoBackupDescription => '按所选时间间隔自动将备份上传到Google Drive。';

  @override
  String get autoBackupInterval => '备份间隔';

  @override
  String get autoBackupOff => '关闭';

  @override
  String get autoBackupEvery30Min => '每30分钟';

  @override
  String get autoBackupHourly => '每小时';

  @override
  String get autoBackupEvery6Hours => '每6小时';

  @override
  String get autoBackupDaily => '每天';

  @override
  String autoBackupNextBackup(String time) {
    return '下次备份：$time';
  }

  @override
  String get autoBackupNextSoon => '很快';

  @override
  String autoBackupNextInMinutes(int count) {
    return '$count分钟后';
  }

  @override
  String get autoBackupNextInOneHour => '1小时后';

  @override
  String autoBackupNextInHours(int count) {
    return '$count小时后';
  }

  @override
  String get autoBackupNextInOneDay => '1天后';

  @override
  String autoBackupNextInDays(int count) {
    return '$count天后';
  }

  @override
  String get playerTitle => '音乐播放器';

  @override
  String get playerToggleQueue => '切换队列';

  @override
  String get playerSearchHint => '搜索曲目…';

  @override
  String playerTrackCount(int count) {
    return '$count首曲目';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs => '未找到预览曲目。\n请打开项目并设置预览曲目。';

  @override
  String playerNoTracksMatch(String query) {
    return '没有曲目匹配\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay => '双击曲目开始播放';

  @override
  String get playerSingleClickToPreview => '单击在下方播放栏中预览';

  @override
  String get playerQueueTitle => '队列';

  @override
  String get playerClearQueue => '清空队列';

  @override
  String get playerQueueEmptyHint => '双击曲目开始，\n或将曲目拖到此处加入队列。';

  @override
  String get playerPrev => '上一首';

  @override
  String get playerNext => '下一首';

  @override
  String get playerGoToProject => '前往项目';

  @override
  String get playerAddToQueue => '加入队列';

  @override
  String get playerRemoveFromQueue => '从队列移除';

  @override
  String get playerDismissDetail => '关闭详情';

  @override
  String get playerNotes => '备注';

  @override
  String get playerTasks => '任务';

  @override
  String get playerNoTasks => '暂无任务。';

  @override
  String get playerAddTaskHint => '添加任务…';

  @override
  String playerCompletedTasks(int count) {
    return '已完成 $count 项';
  }

  @override
  String get playerPreviousTrack => '上一曲';

  @override
  String get playerNextTrack => '下一曲';

  @override
  String get playerOpenProject => '打开项目';

  @override
  String get playerRepeatAll => '全部重复';

  @override
  String get playerShuffle => '随机';

  @override
  String get volumeMute => '静音';

  @override
  String get volumeUnmute => '取消静音';

  @override
  String totalWorkTime(String time) {
    return '总工作时间: $time';
  }

  @override
  String sessionTime(String time) {
    return '会话: $time';
  }

  @override
  String headerAgeOld(String age) {
    return '已创建 $age';
  }

  @override
  String headerEdited(String when) {
    return '$when编辑';
  }

  @override
  String headerWorked(String time) {
    return '已投入 $time';
  }

  @override
  String get sessionHistory => '会话历史';

  @override
  String get noSessionsYet => '尚未记录任何会话';

  @override
  String get removeSessionTitle => '删除会话？';

  @override
  String get editSessionTitle => '编辑会话时长';

  @override
  String get editSessionHours => '小时';

  @override
  String get editSessionInvalid => '时长至少需要1分钟';

  @override
  String get sessionTableDate => '日期';

  @override
  String get sessionTableTime => '时间';

  @override
  String get sessionTableDuration => '时长';

  @override
  String get sessionTableTotal => '合计';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个会话',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => '按阶段工作';

  @override
  String get tabPosition => '标签位置';

  @override
  String get tabPositionTop => '顶部';

  @override
  String get tabPositionLeft => '左侧';

  @override
  String updateAvailableMessage(String version) {
    return '版本 $version 已可用';
  }

  @override
  String get dismiss => '关闭';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkForUpdatesDescription => '当有新版本时获得通知。';

  @override
  String get checkNow => '立即检查';

  @override
  String updateAvailable(String version) {
    return '有可用更新：v$version';
  }

  @override
  String get upToDate => '应用已是最新版本';

  @override
  String get updateAvailableTitle => '有可用更新';

  @override
  String updateAvailableVersion(String version) {
    return '版本 $version 已就绪。';
  }

  @override
  String updateCurrentVersion(String version) {
    return '您当前使用的是 v$version。';
  }

  @override
  String get viewUpdateDetails => '查看详情';

  @override
  String get getOnMicrosoftStore => '在 Microsoft Store 获取';

  @override
  String get downloadFromGitHub => '从 GitHub 下载';

  @override
  String get updateWindowsInstructions =>
      '打开 Microsoft Store 更新 DAW Project Manager，或点击下方按钮。';

  @override
  String get updateMacInstructions => '从 GitHub 下载最新版本并替换当前应用。';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions => '原地更新并重启。';

  @override
  String get updateNowButtonLabel => '立即更新';

  @override
  String get appImageUpdateFetching => '正在查找更新…';

  @override
  String get appImageUpdateDownloading => '正在下载更新…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return '正在下载更新… $percent%';
  }

  @override
  String get appImageUpdateVerifying => '正在验证并安装…';

  @override
  String get appImageUpdateReadyTitle => '更新已就绪';

  @override
  String appImageUpdateReadyMessage(String version) {
    return '已更新到 v$version。请立即重启以完成更新。';
  }

  @override
  String get appImageUpdateRestartNow => '立即重启';

  @override
  String get appImageUpdateFailedTitle => '更新失败';

  @override
  String get appImageUpdateRetry => '重试';

  @override
  String get appImageUpdateErrorMessage => '更新时出错。您可以重试，或查看下方的错误详情。';

  @override
  String get appImageUpdateErrorDetailsLabel => '错误详情';

  @override
  String get appImageUpdateCopyErrorDetails => '复制错误详情';

  @override
  String get appImageUpdateErrorDetailsCopied => '错误详情已复制';

  @override
  String get resetOnboarding => '重置引导设置';

  @override
  String get onboardingWelcomeTitle => '欢迎使用 DAW Project Manager';

  @override
  String get onboardingWelcomeBody => '在一个地方管理您所有的音乐项目。';

  @override
  String get onboardingFeatureScanFolders => '自动扫描DAW项目文件夹';

  @override
  String get onboardingFeatureTrackMetadata => '跟踪BPM、调性、状态和截止日期';

  @override
  String get onboardingFeatureSyncDrive => '将元数据同步到Google Drive';

  @override
  String get onboardingFeatureTrackTime => '跟踪每个项目所花费的时间';

  @override
  String get onboardingLanguageTitle => '选择语言';

  @override
  String get onboardingThemeTitle => '选择主题';

  @override
  String get onboardingFoldersTitle => '添加项目文件夹';

  @override
  String get onboardingFoldersBody => '添加存储 DAW 项目的根文件夹。';

  @override
  String get onboardingDriveTitle => 'Google Drive 同步';

  @override
  String get onboardingDriveBody => '将项目元数据备份并同步到 Google Drive。';

  @override
  String get onboardingUpdatesTitle => '更新检查';

  @override
  String get onboardingUpdatesBody => '当有新版本时获得通知。';

  @override
  String get onboardingDoneTitle => '一切就绪！';

  @override
  String get onboardingDoneBody => '开始探索您的项目。';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingBack => '返回';

  @override
  String get onboardingGetStarted => '开始使用';

  @override
  String get dawSession => 'DAW会话';

  @override
  String get clearDawSession => '清除会话';

  @override
  String get stop => '停止';

  @override
  String get pause => '暂停';

  @override
  String get playPauseTooltip => '播放/暂停';

  @override
  String get resume => '继续';

  @override
  String get workTimerSection => '工作会话提醒';

  @override
  String get workTimerSectionDesc => '在工作会话处于活动状态时定期获取通知';

  @override
  String get workTimerRequiresSessionMode => '请先在上方启用会话模式以使用工作会话提醒';

  @override
  String get workTimerEnabled => '启用工作会话提醒';

  @override
  String get workTimerIntervalLabel => '每隔通知';

  @override
  String get minutes => '分钟';

  @override
  String workTimerNotifBody(String time) {
    return '您已工作 $time';
  }

  @override
  String get sendTestNotification => '发送测试通知';

  @override
  String get testNotificationTitle => '测试通知';

  @override
  String get testNotificationBody => '这是来自 DAW Project Manager 的测试通知。';

  @override
  String get general => '常规';

  @override
  String get expand => '展开';

  @override
  String get collapse => '折叠';

  @override
  String get lastModifiedColors => '最后修改日期颜色';

  @override
  String get lastModifiedColorsDescription =>
      '根据时间和状态为最后修改日期着色。绿色 = 已完成。较旧的日期从黄色渐变为红色——红色越深表示项目越长时间未被修改。';

  @override
  String get sessionMode => '会话模式';

  @override
  String get sessionModeDescription => '为项目开始一个会话，以跟踪工作时间并从工具栏进行管理';

  @override
  String get workSessionsTabLabel => '工作会话';

  @override
  String get normalMode => '普通模式';

  @override
  String get normalModeDescription => '启动时项目会直接在其DAW中打开。';

  @override
  String get sessionModeCardDescription => '开始一个会话以跟踪您在项目上的活动和时间。';

  @override
  String get startSession => '开始会话';

  @override
  String get endSession => '结束会话';

  @override
  String get switchSession => '切换会话';

  @override
  String get switchSessionBody => '停止当前会话并开始新会话？';

  @override
  String switchSessionCurrent(String project) {
    return '当前：$project';
  }

  @override
  String switchSessionNew(String project) {
    return '新建：$project';
  }

  @override
  String get sessionDuration => '会话时长';

  @override
  String get scanModeLabel => '扫描模式：';

  @override
  String get scanModeSectionTitle => '扫描模式';

  @override
  String get scanModeSectionDescription =>
      '控制每个文件夹中的项目在表格中的显示方式——作为简单的平铺列表或按子文件夹分组。';

  @override
  String get smartFolderOptionsSectionTitle => '智能文件夹选项';

  @override
  String get smartFolderOptionsSectionDescription => '微调智能文件夹分组在项目表格中的行为。';

  @override
  String get excludeSmartFoldersFromSort => '排序时排除智能文件夹';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      '按列对项目表排序时，智能文件夹分组会保持原位，不随排序移动——只有分组内的项目（以及未分组的项目）会重新排序。实验性功能，默认关闭。';

  @override
  String get mergeSmartFoldersByName => '合并同名的智能文件夹';

  @override
  String get mergeSmartFoldersByNameDescription =>
      '当两个扫描根目录（例如不同的 DAW）拥有同名的顶级文件夹时，将它们在项目表中视为一个合并的分组，而不是两个独立的分组。';

  @override
  String get alwaysShowSmartFolders => '始终显示智能文件夹';

  @override
  String get alwaysShowSmartFoldersDescription =>
      '即使某个智能文件夹当前只有一个项目可见（例如经过搜索或筛选后），也将其显示为独立的分组行，而不是折叠为普通的未分组行。';

  @override
  String get scanModeFlat => '平铺';

  @override
  String get scanModeSmartFolder => '智能文件夹';

  @override
  String get scanModeFlatDescription => '将所有项目显示为平铺列表。简单快速。';

  @override
  String get scanModeSmartFolderDescription => '当文件夹包含多个项目时，按文件夹分组显示。';

  @override
  String get skip => '跳过';

  @override
  String get suggestionsLabel => '建议';

  @override
  String get suggestionsRefresh => '刷新';

  @override
  String get suggestionsEmptyState => '暂无建议。点击刷新以重置已忽略的项目。';

  @override
  String get suggestionNewProject => '新建';

  @override
  String get showSuggestions => '显示建议';

  @override
  String get showSuggestionsDescription => '在没有会话运行时在工具栏中显示智能建议';

  @override
  String get onboardingSuggestionsTitle => '智能建议';

  @override
  String get onboardingSuggestionsBody => '在工作时在工具栏中获取个性化项目推荐';

  @override
  String get onboardingSessionModeTitle => '会话模式';

  @override
  String get onboardingSessionModeBody => '开始专注的工作会话，并自动跟踪每个项目花费的时间';

  @override
  String get suggestionsFeatureDeadlines => '即将截止项目的提醒';

  @override
  String get suggestionsFeatureResume => '恢复您上次处理的项目';

  @override
  String get suggestionsFeatureRecentlyModified => '继续最近修改的曲目';

  @override
  String get suggestionsEnableToggle => '启用智能建议';

  @override
  String get canBeChangedInSettings => '可以稍后在设置中更改';

  @override
  String get next => '下一步';

  @override
  String get createProject => '创建';

  @override
  String get createProjectTooltip => '创建新的项目文件夹';

  @override
  String get createProjectSelectFolder => '选择位置';

  @override
  String get createProjectSelectFolderHint => '选择要在哪个项目文件夹中创建新项目';

  @override
  String get createProjectNameTitle => '为您的项目命名';

  @override
  String get createProjectNameHint => '为新项目文件夹选择命名方案';

  @override
  String get createProjectSchemeArtistTrack => '艺术家 — 曲目';

  @override
  String get createProjectSchemeCollab => '合作';

  @override
  String get createProjectSchemeDate => '日期 — 曲目';

  @override
  String get createProjectSchemeCustom => '自定义';

  @override
  String get createProjectSchemeRemix => '混音';

  @override
  String get createProjectArtistName => '艺术家名称';

  @override
  String get createProjectTrackName => '曲目名称';

  @override
  String get createProjectCustomName => '文件夹名称';

  @override
  String get createProjectAddArtist => '添加艺术家';

  @override
  String get createProjectOriginalArtist => '原始艺术家';

  @override
  String get createProjectRemixerName => '混音师';

  @override
  String get createProjectAddRemixer => '添加混音师';

  @override
  String get createProjectSelectDaw => '在DAW中打开';

  @override
  String get createProjectSelectDawHint => '选择要打开哪个DAW来开始处理此项目';

  @override
  String get createProjectDetectDaws => '检测已安装的DAW';

  @override
  String get createProjectSkipDaw => '仅创建文件夹';

  @override
  String get createProjectNoDawsFound => '未找到任何DAW。文件夹仍将被创建。';

  @override
  String get createProjectCreateOnly => '创建文件夹';

  @override
  String get createProjectCreateAndOpen => '创建并打开';

  @override
  String get createProjectFolderExists => '已存在同名文件夹';

  @override
  String get createProjectInvalidChars => '文件夹名称包含无效字符';

  @override
  String get createProjectError => '创建文件夹失败';

  @override
  String get createProjectIncludeDate => '包含日期前缀';

  @override
  String get createProjectCreatedTitle => '文件夹已创建';

  @override
  String get createProjectCreatedMessage => '您的项目文件夹已创建：';

  @override
  String get createProjectCopyName => '复制文件夹名称';

  @override
  String get createProjectNameCopied => '已复制文件夹名称';

  @override
  String get createProjectTrackSession => '从现在开始追踪会话';

  @override
  String get pendingFolderSessionTitle => '检测到工作会话';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return '您已在\"$projectName\"上工作了$duration。';
  }

  @override
  String get pendingFolderSessionContinue => '继续会话';

  @override
  String get pendingFolderSessionEndRecord => '结束并记录';

  @override
  String get activeSessionSwitchTitle => '会话已激活';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return '「$current」的会话正在运行。切换到「$next」并保存当前会话？';
  }

  @override
  String get activeSessionSwitch => '切换';

  @override
  String get pendingProjectWaiting => '等待项目文件…';

  @override
  String get pendingProjectDelete => '删除空文件夹';

  @override
  String get pendingProjectDeleteTitle => '删除文件夹？';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return '删除\"$folderName\"及其内容？';
  }

  @override
  String get pendingProjectDismiss => '停止跟踪此文件夹';

  @override
  String get pendingProjectDismissTitle => '停止跟踪？';

  @override
  String get pendingProjectDismissKeep => '保留文件夹';

  @override
  String get pendingProjectDismissDelete => '删除并关闭';

  @override
  String get pendingProjectDeleteNotEmptyTitle => '文件夹不为空';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" 包含文件。永久删除所有内容？';
  }

  @override
  String get pendingProjectRefresh => '检查项目文件';

  @override
  String get pendingProjectNotFound => '尚未找到项目文件';

  @override
  String get phases => '阶段';

  @override
  String get phasesSubtitle => '添加、删除和重新排序项目阶段';

  @override
  String get phasesDescription =>
      '阶段用于跟踪每个项目在你的工作流程中所处的位置（例如：创意 → 混音 → 母带）。拖动可重新排序，点击彩色圆点可更改颜色，将某个阶段标记为已完成后，整个应用中都会将其视为完成状态。';

  @override
  String get resetToDefaults => '恢复默认设置';

  @override
  String get addPhase => '添加阶段';

  @override
  String get phaseNameHint => '阶段名称';

  @override
  String get phaseDuplicateError => '已存在同名阶段';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个项目使用此阶段',
      one: '1个项目使用此阶段',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => '选择颜色';

  @override
  String get markAsFinished => '标记为完成阶段';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个项目使用了将不再存在的阶段。',
      one: '1个项目使用了将不再存在的阶段。',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      '这些项目将保留当前状态，但不会出现在阶段筛选器中。您随时可以重新添加这些阶段。';

  @override
  String get resetPhasesConfirm => '将所有自定义阶段、颜色和已完成阶段标记重置为默认值？';

  @override
  String get camelotGenerateButton => '生成混音';

  @override
  String get camelotDialogTitle => 'Camelot 混音';

  @override
  String get camelotDialogDescription =>
      '使用 Camelot 轮盘按和声兼容性排列曲目，以 BPM 接近度作为同等情况下的决胜标准。';

  @override
  String camelotEligibleTracks(int count) {
    return '$count 首曲目符合条件（已设置调性）';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count 首将被跳过（无调性）';
  }

  @override
  String get camelotNoEligibleTracks => '没有曲目设置了调性。请打开项目并设置调性。';

  @override
  String get camelotGenerate => '生成';

  @override
  String camelotQueueGenerated(int count) {
    return '队列已填充 $count 首按和声排序的曲目';
  }

  @override
  String get camelotWheelGuideTooltip => 'Camelot 轮盘指南';

  @override
  String get camelotWheelGuideTitle => 'Camelot 轮盘指南';

  @override
  String get camelotGuideRingsTitle => '环形';

  @override
  String get camelotGuideRingsBody => '内环（A）  →  小调\n外环（B）  →  大调';

  @override
  String get camelotGuideNumbersTitle => '数字 1–12';

  @override
  String get camelotGuideNumbersBody => '位置按順时针排列。每个数字代表一个和声邻域——相邻位置共享强烈的音调关系。';

  @override
  String get camelotGuideColoursTitle => '颜色说明';

  @override
  String get camelotGuideColoursBody =>
      '● 明亮  →  您的歌曲调性\n● 柔和发光  →  适合混音的\n● 暗淡  →  避免用于流畅混音';

  @override
  String get camelotGuideTransitionsTitle => '兼容的过渡';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  （相同数字，切换环）\n  关系大调/小调 — 几乎无缝衔接。\n\n8A → 7A 或 9A  （±1，相同环）\n  相邻调性 — 平滑、细腻的变化。\n\n8A → 1A 或 3A  （±7，相同环）\n  能量提升或下降 — 更显著的转变。';

  @override
  String get playerMixSuggestions => '混音建议';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get noPreviewSongsAvailable => '没有可用的预览曲目';

  @override
  String get upNext => '接下来';

  @override
  String get playbackModeNormal => '正常';

  @override
  String get playbackModeRepeat => '循环';

  @override
  String get playbackModeShuffle => '随机播放';

  @override
  String get hideDatesInNames => '隐藏项目名称中的日期';

  @override
  String get hideDatesInNamesDescription =>
      '某些 DAW 会在项目文件名前加上创建日期（例如“2026-08-02 - My Track”）。隐藏它即可只显示标题。文件本身不会被重命名。';

  @override
  String get findPreviewAutomatically => '自动查找';

  @override
  String get noPreviewSongFoundAutomatically => '在此项目的混音文件夹中未找到预览歌曲。';

  @override
  String get selectProjects => '选择';

  @override
  String sharePreviewSongText(String name) {
    return '预览歌曲：$name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return '预览歌曲（ZIP）：$name';
  }

  @override
  String get songParts => '乐器与声部';

  @override
  String partsProgress(int done, int total) {
    return '$total 个中有 $done 个已完成终版';
  }

  @override
  String get noPartsYet => '尚未记录任何声部';

  @override
  String get noPartsYetHint => '列出这首歌需要的乐器、由谁演奏，以及每条录音的进度。';

  @override
  String get addPart => '添加声部';

  @override
  String get addPartHint => '例如：鼓、主唱、贝斯';

  @override
  String get partNameLabel => '声部';

  @override
  String get partNameRequired => '请填写声部名称';

  @override
  String get partPerformerLabel => '演奏者';

  @override
  String get partPerformerHint => '由谁演奏';

  @override
  String get partNotesLabel => '声部备注';

  @override
  String get partStatusLabel => '录音状态';

  @override
  String get partStatusNeeded => '待录制';

  @override
  String get partStatusRecording => '录制中';

  @override
  String get partStatusEarlyTake => '初版录音';

  @override
  String get partStatusFinalTake => '终版录音';

  @override
  String get editPart => '编辑声部';

  @override
  String get deletePart => '删除声部';

  @override
  String get partsUnassignedPerformer => '未指派';

  @override
  String get partTemplates => '声部模板';

  @override
  String get importPartsFromTemplate => '从模板导入声部';

  @override
  String get managePartTemplates => '管理声部模板';

  @override
  String get selectPartTemplate => '选择声部模板';

  @override
  String get noPartTemplatesAvailable => '没有可用的声部模板';

  @override
  String get noPartTemplatesYet => '还没有声部模板';

  @override
  String get createFirstPartTemplate => '创建一个模板，在多首歌曲中复用同一套编制';

  @override
  String get createPartTemplate => '创建声部模板';

  @override
  String get editPartTemplate => '编辑声部模板';

  @override
  String get deletePartTemplate => '删除声部模板';

  @override
  String deletePartTemplateConfirm(String name) {
    return '确定要删除声部模板“$name”吗？';
  }

  @override
  String get partTemplateCreated => '已创建声部模板';

  @override
  String get partTemplateUpdated => '已更新声部模板';

  @override
  String get partTemplateDeleted => '已删除声部模板';

  @override
  String get partTemplateItems => '声部（每行一个）';

  @override
  String get partTemplateItemsHint => '鼓 — Alex\n贝斯 — Sam\n主唱';

  @override
  String get partTemplateItemsHelp => '每行一个声部。在破折号后写上演奏者：鼓 — Alex';

  @override
  String get partTemplateItemsRequired => '请至少添加一个声部';

  @override
  String get partTemplateNameAndItemsRequired => '需要填写名称并至少添加一个声部';

  @override
  String partTemplateItemCount(int count) {
    return '$count 个声部';
  }

  @override
  String partTemplateImported(String name, int count) {
    return '已导入声部模板“$name”（$count 个声部）';
  }

  @override
  String get errorLoadingPartTemplates => '加载声部模板出错';

  @override
  String get exportPartsCsv => '将声部导出为 CSV';

  @override
  String get exportAllPartsCsv => '将所有歌曲的声部导出为 CSV';

  @override
  String get exportAllPartsCsvSubtitle => '所有项目的每个声部各占一行，便于与合作者分享进度';

  @override
  String get noPartsToExport => '没有可导出的声部';

  @override
  String partsCsvExported(int count) {
    return '已导出 $count 个声部';
  }

  @override
  String get projectExportPartsLabel => '声部：';

  @override
  String get csvHeaderProject => '项目';

  @override
  String get csvHeaderPart => '声部';

  @override
  String get csvHeaderPerformer => '演奏者';

  @override
  String get csvHeaderStatus => '状态';

  @override
  String get csvHeaderNotes => '备注';

  @override
  String get exportPartsXlsx => '将声部导出为 Excel (.xlsx)';

  @override
  String get exportAllPartsXlsx => '将所有歌曲的声部导出为 Excel (.xlsx)';

  @override
  String get exportAllPartsXlsxSubtitle => '与 CSV 相同的表格，另加冻结表头、列筛选器和彩色录音状态';

  @override
  String get importPartsFromSpreadsheet => '从电子表格导入声部';

  @override
  String get partsImportPickerTitle => '选择 CSV 或 Excel 文件';

  @override
  String partsImported(int added, int updated) {
    return '新增 $added 个声部，更新 $updated 个';
  }

  @override
  String get partsImportNothingFound => '该文件中没有找到声部';

  @override
  String partsImportFailed(String error) {
    return '无法读取该电子表格：$error';
  }

  @override
  String get partsMoreActions => '更多声部操作';

  @override
  String partsPageTitle(String name) {
    return '$name — 声部';
  }

  @override
  String get manageParts => '管理声部';

  @override
  String partsMoreCount(int count) {
    return '还有 $count 个';
  }

  @override
  String get searchParts => '搜索声部';

  @override
  String get allStatuses => '所有状态';

  @override
  String get allPerformers => '所有演奏者';

  @override
  String partsSelectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String get setPartStatus => '设置状态';

  @override
  String get assignPartPerformer => '指派演奏者';

  @override
  String get deleteSelectedParts => '删除所选';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return '要从这首歌中删除 $count 个声部吗？';
  }

  @override
  String partsDeleted(int count) {
    return '已删除 $count 个声部';
  }

  @override
  String get noPartsMatchFilters => '没有声部符合这些筛选条件';

  @override
  String get reorderNeedsUnfilteredList => '清除搜索、筛选和排序后即可拖动调整声部顺序';

  @override
  String get projectMarkers => '标记';

  @override
  String projectMarkerUnnamed(int index) {
    return '标记 $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return '区域 $index';
  }

  @override
  String get projectMarkerJumpTooltip => '跳转到预览歌曲的此位置';

  @override
  String get projectMarkerNoPreviewSong => '添加预览歌曲以跳转到标记';

  @override
  String get projectDetailLayout => '项目详情布局';

  @override
  String get projectDetailLayoutSettingDescription => '项目详情页面的排列方式。';

  @override
  String get projectDetailLayoutClassic => '经典';

  @override
  String get projectDetailLayoutClassicDescription => '所有内容在一个滚动页面中。';

  @override
  String get projectDetailLayoutSectioned => '分区';

  @override
  String get projectDetailLayoutSectionedDescription => '左侧栏每次选择一个分区。';

  @override
  String get stackAsVersions => '堆叠为版本';

  @override
  String get stackNeedsTwoVersions => '请至少选择两个项目，才能将它们堆叠为同一个主项目的版本。';

  @override
  String stackCreatedMessage(int count) {
    return '已将 $count 个版本堆叠为一个主项目。';
  }

  @override
  String get stackVersionsTitle => '版本';

  @override
  String stackVersionCount(int count) {
    return '$count 个版本';
  }

  @override
  String get stackAddVersion => '添加版本';

  @override
  String get stackAddVersionTitle => '添加版本';

  @override
  String get stackAddVersionEmpty => '没有可添加的未堆叠项目。';

  @override
  String get stackRemoveVersion => '从堆叠中移除';

  @override
  String get stackRemoveVersionMessage => '项目文件会保留在磁盘上，并作为独立项目回到列表中。';

  @override
  String get stackUnstack => '取消堆叠';

  @override
  String get stackUnstackTitle => '要取消这个主项目的堆叠吗？';

  @override
  String get stackUnstackMessage =>
      '每个版本将恢复为独立项目，并保留堆叠前的元数据。主项目上保存的共享笔记、任务和截止日期将被删除。';

  @override
  String get stackDefaultVersion => '默认打开';

  @override
  String get stackSetDefaultVersion => '默认打开此版本';

  @override
  String get stackChooseVersionToOpen => '要打开哪个版本？';

  @override
  String get stackMemberOf => '所属主项目';

  @override
  String get stackMemberNotice =>
      '此文件是某个堆叠项目的一个版本。共享的元数据、任务和工作时间保存在主项目上，而不是这里。';

  @override
  String get stackOpenMainProject => '打开主项目';

  @override
  String get stackWorkTimeAcrossVersions => '所有版本合计';

  @override
  String get scanModeVersionStack => '版本堆叠';

  @override
  String get scanModeVersionStackDescription =>
      '文件夹中的所有项目文件将合并为一个主项目，共享元数据、任务和工作时间。新发现的文件会自动加入。';

  @override
  String stackTooltipStacked(int count) {
    return '$count 个版本堆叠为一个主项目';
  }

  @override
  String get stackMetadataSourceTitle => '哪个项目应成为主项目？';

  @override
  String get stackMetadataSourceBody =>
      '其中有多个已经有自己的详细信息。你选择的那个将成为主项目：它的名称、BPM、调性、笔记、任务和截止日期将被堆叠使用。不会合并也不会丢失——其他项目保留各自的详细信息，取消堆叠后即可恢复。';

  @override
  String get stackMetadataSourceOldestHint => '最早的 — 建议';

  @override
  String get stackMetadataNoneLabel => '暂无详细信息';

  @override
  String stackMetadataTodosLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个任务',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataNotesLabel => '笔记';

  @override
  String get stackNotStackedYet => '尚未堆叠';

  @override
  String get stackStartFromHere => '添加其他项目文件，它们将成为同一个主项目的版本，共享元数据、任务和工作时间。';

  @override
  String get stackSearchProjects => '搜索项目';

  @override
  String get stackSearchNoMatches => '没有与搜索匹配的项目。';

  @override
  String get stackStartedMessage => '已堆叠为一个主项目。';

  @override
  String get stackDefaultVersionTooltip => '启动 DAW 时默认打开此版本。';

  @override
  String stackAddVersionsConfirm(int count) {
    return '添加 $count 个';
  }

  @override
  String get stackAddVersionMultiTitle => '添加版本';

  @override
  String get stackSelectAll => '全选';

  @override
  String get stackClearSelection => '清除';

  @override
  String stackMetadataPartsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个声部',
    );
    return '$_temp0';
  }

  @override
  String get stackMetadataDeadlineLabel => '截止日期';

  @override
  String get stackMetadataRenamedLabel => '自定义名称';

  @override
  String stackMetadataWorkHours(String hours) {
    return '已记录 $hours 小时';
  }

  @override
  String get stackUnstackReleaseTitle => '哪个版本保留在发行中？';

  @override
  String stackUnstackReleaseBody(String releases) {
    return '此项目是 $releases 中的一首曲目。取消堆叠会移除堆叠条目，因此需要由其中一个版本接替该位置——请选择发行应指向的版本。';
  }

  @override
  String get stackAutoConfirmTitle => '要堆叠这些版本吗？';

  @override
  String stackAutoConfirmBody(int projects, int folders) {
    return '版本堆叠会将 $folders 个文件夹中的 $projects 个项目分组。每个文件夹将成为一个主项目，共享元数据、任务和工作时间。不会删除任何内容，之后也可以取消堆叠。';
  }

  @override
  String get stackAutoConfirmApply => '堆叠';

  @override
  String stackAutoFolderEntry(String folder, int count) {
    return '$folder — $count 个版本';
  }

  @override
  String get stackAutoJoinsExisting => '加入现有的主项目';

  @override
  String get untitledTheme => '未命名主题';

  @override
  String switchToTheme(String themeName) {
    return '切换到 $themeName';
  }

  @override
  String get newTheme => '新建主题';

  @override
  String get editTheme => '编辑主题';

  @override
  String get duplicateTheme => '复制';

  @override
  String get deleteThemeTitle => '删除主题？';

  @override
  String deleteThemeMessage(String name) {
    return '将删除“$name”。此操作无法撤销。';
  }

  @override
  String get themeNameLabel => '主题名称';

  @override
  String get themeNameHint => '例如：Studio Amber';

  @override
  String get themeNameRequired => '请为主题命名。';

  @override
  String get themeColorAccent => '强调色';

  @override
  String get themeColorSecondaryAccent => '次强调色';

  @override
  String get themeColorBackground => '背景';

  @override
  String get themeColorCards => '卡片与面板';

  @override
  String get themeCardRoundness => '卡片圆角';

  @override
  String get themeButtonRoundness => '按钮圆角';

  @override
  String themeLowContrastWarning(String ratio) {
    return '对比度偏低（$ratio:1），文字可能不易阅读。';
  }

  @override
  String get exportTheme => '导出主题';

  @override
  String get importTheme => '导入主题';

  @override
  String themeExported(String path) {
    return '主题已导出到 $path';
  }

  @override
  String themeImported(String name) {
    return '已导入“$name”';
  }

  @override
  String get themeImportFailed => '该文件不是有效的主题。';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexInvalid => '请使用 #RRGGBB';

  @override
  String get apply => '应用';

  @override
  String themeCopyName(String name) {
    return '$name 副本';
  }

  @override
  String get suggestedColorsLabel => '推荐颜色';

  @override
  String get projectAttachments => '附件';

  @override
  String get attachmentAddFile => '添加文件';

  @override
  String get attachmentAddLink => '添加链接';

  @override
  String get attachmentsEmptyTitle => '还没有附件';

  @override
  String get attachmentsEmptyDescription =>
      '把参考曲、分轨交付链接、歌词和合同放在歌曲旁边，而不是散落在聊天记录里。';

  @override
  String get attachmentEditDialogTitle => '编辑附件';

  @override
  String get attachmentUrlLabel => '网址';

  @override
  String get attachmentPathLabel => '文件路径';

  @override
  String get attachmentLabelLabel => '标签（可选）';

  @override
  String get attachmentNoteLabel => '备注（可选）';

  @override
  String get attachmentUrlInvalid => '请输入有效链接，例如 https://example.com';

  @override
  String get attachmentPathRequired => '请输入文件路径';

  @override
  String get attachmentOpenTooltip => '打开';

  @override
  String get attachmentRemoveTitle => '移除附件';

  @override
  String attachmentRemoveMessage(String label) {
    return '要从此项目中移除“$label”吗？文件本身不会被删除。';
  }

  @override
  String get attachmentRemoved => '已移除附件';

  @override
  String get attachmentAdded => '已添加附件';

  @override
  String get attachmentOpenFailed => '无法打开该附件';

  @override
  String get attachmentPickFileTitle => '选择要附加的文件';

  @override
  String get attachmentAlreadyAdded => '该内容已附加到此项目';

  @override
  String get attachmentExport => '导出';

  @override
  String get attachmentExportTooltip => '保存附加的文件和链接';

  @override
  String get attachmentExportSaveTitle => '保存附件';

  @override
  String get attachmentExportNothing => '没有可导出的内容';

  @override
  String get attachmentExporting => '正在导出附件...';

  @override
  String attachmentExportSaved(String path) {
    return '已保存到：$path';
  }

  @override
  String attachmentExportSkippedMissing(int count, String plural) {
    return '已跳过 $count 个丢失的文件$plural';
  }

  @override
  String attachmentExportFailed(String error) {
    return '导出附件失败：$error';
  }
}
