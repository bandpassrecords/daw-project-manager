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
  String get cancel => '取消';

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
  String get scanning => '扫描中…';

  @override
  String get projectName => '项目名称';

  @override
  String get bpm => 'BPM';

  @override
  String get key => '调性（例如：C#m，F大调）';

  @override
  String get notes => '备注';

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
  String get clearLibrary => '清空库';

  @override
  String get clearLibraryMessage => '这将删除所有保存的项目和源文件夹。继续吗？';

  @override
  String get clear => '清空';

  @override
  String get roots => '根目录';

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
  String get deepScanTooltip =>
      '深度扫描从项目文件中提取完整的元数据：\n• BPM（每分钟节拍数）\n• 音乐调性\n• DAW版本\n这较慢，但提供完整信息。';

  @override
  String get deepScanConfirm =>
      '这将扫描所有项目并提取完整的元数据（BPM、调性、DAW版本）。这可能需要一些时间。继续吗？';

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
    return '您确定要删除「$profileName」吗？这将删除此配置文件的所有项目、根目录和发布。';
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
  String created(String date) {
    return '创建于';
  }

  @override
  String get toggleSort => '切换排序';

  @override
  String get clearLibraryTooltip => '清空库（项目和根目录）';

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
  String get allPhases => '所有阶段';

  @override
  String get daw => 'DAW';

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
  String get deleteRootPath => '删除根路径';

  @override
  String deleteRootPathMessage(String path) {
    return '您确定要删除「$path」吗？这也会删除此文件夹中不在发布中的所有项目。';
  }

  @override
  String rootsCount(int count) {
    return '根目录: $count';
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
  String get noProjectsFoundInRoots => '在选定的根目录中未找到项目。';

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
  String errorLoadingProjects(String error) {
    return '加载项目错误: $error';
  }

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
  String failedToOpenFile(String error) {
    return '打开文件失败: $error';
  }

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
  String get todoList => '待办事项列表';

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
  String get noFilesAddedYet => '尚未添加文件。\n点击\"添加文件\"上传发布文件。';

  @override
  String get noTodosYet => '还没有待办事项。请在上面添加一个。';

  @override
  String get done => '完成';

  @override
  String get backupAndRestore => '备份和恢复';

  @override
  String get exportBackup => '导出备份';

  @override
  String get importBackup => '导入备份';

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
    return '备份导入成功: $projectsCount 个项目，$rootsCount 个根目录，$releasesCount 个发布';
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
    return '备份已导入到新配置文件 \"$profileName\": $projectsCount 个项目，$rootsCount 个根目录，$releasesCount 个发布';
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
}
