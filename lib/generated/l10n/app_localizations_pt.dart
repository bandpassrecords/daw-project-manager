// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gerenciador de Projetos DAW';

  @override
  String get projectDetails => 'Detalhes do Projeto';

  @override
  String get back => 'Voltar';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get launch => 'Abrir';

  @override
  String get view => 'Ver';

  @override
  String get openFolder => 'Abrir Pasta';

  @override
  String get openInDaw => 'Lançar no DAW';

  @override
  String get extract => 'Extrair';

  @override
  String get extracting => 'Extraindo…';

  @override
  String get extractingMetadata => 'Extraindo metadados...';

  @override
  String get deepScan => 'Varredura Profunda';

  @override
  String get rescan => 'Reescanear';

  @override
  String get scanning => 'Escaneando…';

  @override
  String get projectName => 'Nome do Projeto';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tom (ex: C#m, F maior)';

  @override
  String get notes => 'Notas';

  @override
  String get projectPhase => 'Fase do Projeto';

  @override
  String get failedToLoad => 'Falha ao carregar';

  @override
  String get fileMissing => 'Arquivo ausente.';

  @override
  String launchingProject(String projectName) {
    return 'Abrindo $projectName…';
  }

  @override
  String get clearLibrary => 'Limpar Biblioteca';

  @override
  String get clearLibraryMessage =>
      'Isso removerá todos os projetos salvos e pastas de origem. Continuar?';

  @override
  String get clear => 'Limpar';

  @override
  String get roots => 'Pastas de Projetos';

  @override
  String get projects => 'Projetos';

  @override
  String get hidden => 'ocultos';

  @override
  String get profileManager => 'Gerenciador de Perfis';

  @override
  String get createNewProfile => 'Criar Novo Perfil';

  @override
  String get profileName => 'Nome do Perfil';

  @override
  String get create => 'Criar';

  @override
  String get profiles => 'Perfis';

  @override
  String get active => 'Ativo';

  @override
  String get switchProfile => 'Alternar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get addFolder => 'Adicionar Pasta';

  @override
  String get searchProjects => 'Pesquisar projetos...';

  @override
  String get deepScanTooltip =>
      'A Varredura Profunda extrai metadados completos dos arquivos de projeto:\n• BPM (Batidas Por Minuto)\n• Tom Musical\n• Versão do DAW\nIsso é mais lento, mas fornece informações completas.';

  @override
  String get deepScanConfirm =>
      'Isso escaneará todos os projetos e extrairá metadados completos (BPM, Tom, Versão do DAW). Isso pode levar um tempo. Continuar?';

  @override
  String get metadataExtractedSuccessfully => 'Metadados extraídos com sucesso';

  @override
  String failedToExtractMetadata(String error) {
    return 'Falha ao extrair metadados: $error';
  }

  @override
  String get saved => 'Salvo';

  @override
  String get failedToLaunchDaw => 'Falha ao abrir DAW';

  @override
  String get releaseDetails => 'Detalhes do Lançamento';

  @override
  String get releaseNotFound => 'Lançamento Não Encontrado';

  @override
  String get error => 'Erro';

  @override
  String get loading => 'Carregando...';

  @override
  String get deleteProfile => 'Excluir Perfil';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Tem certeza de que deseja excluir \"$profileName\"? Isso excluirá todos os projetos, pastas de projetos e lançamentos deste perfil.';
  }

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get changePhoto => 'Alterar Foto';

  @override
  String get remove => 'Remover';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Tem certeza de que deseja remover \"$trackName\" deste lançamento?';
  }

  @override
  String get saveName => 'Salvar Nome';

  @override
  String get profilePhotoUpdated => 'Foto do perfil atualizada.';

  @override
  String get profilePhotoRemoved => 'Foto do perfil removida.';

  @override
  String profileRenamed(String newName) {
    return 'Perfil renomeado para \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Perfil \"$name\" criado com sucesso';
  }

  @override
  String profileDeleted(String name) {
    return 'Perfil \"$name\" excluído';
  }

  @override
  String get pleaseEnterProfileName => 'Por favor, insira um nome de perfil';

  @override
  String failedToCreateProfile(String error) {
    return 'Falha ao criar perfil: $error';
  }

  @override
  String get noProfilesFound => 'Nenhum perfil encontrado. Crie um acima.';

  @override
  String created(String date) {
    return 'Criado';
  }

  @override
  String get toggleSort => 'Alternar ordenação';

  @override
  String get clearLibraryTooltip =>
      'Limpar Biblioteca (projetos e pastas de projetos)';

  @override
  String lastModified(String date) {
    return 'Última modificação: $date';
  }

  @override
  String get name => 'Nome';

  @override
  String get status => 'Status';

  @override
  String get phase => 'Fase';

  @override
  String get filterByPhase => 'Filtrar por Fase';

  @override
  String get allPhases => 'Todas as Fases';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Última Modificação';

  @override
  String get actions => 'Ações';

  @override
  String get hide => 'Ocultar';

  @override
  String get unhide => 'Mostrar';

  @override
  String get extractMetadata => 'Extrair Metadados';

  @override
  String get createRelease => 'Criar Lançamento';

  @override
  String get clearSelection => 'Limpar Seleção';

  @override
  String get selectAllProjects => 'Selecionar todos os projetos';

  @override
  String get switchingProfiles => 'Alternando perfis...';

  @override
  String get scanningProjects => 'Escaneando projetos...';

  @override
  String get projectsTab => 'Projetos';

  @override
  String get releasesTab => 'Lançamentos';

  @override
  String get showHidden => 'Mostrar Ocultos';

  @override
  String get showAll => 'Mostrar Todos';

  @override
  String get showOnlyHidden => 'Mostrar Apenas Ocultos';

  @override
  String get deleteRootPath => 'Excluir Caminho Raiz';

  @override
  String deleteRootPathMessage(String path) {
    return 'Tem certeza de que deseja remover \"$path\"? Isso também removerá todos os projetos desta pasta que não estão em lançamentos.';
  }

  @override
  String rootsCount(int count) {
    return 'Pastas de Projetos: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projetos: $count';
  }

  @override
  String get hiddenOnly => '(apenas ocultos)';

  @override
  String hiddenCount(int count) {
    return '($count ocultos)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count projeto$plural oculto$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count projeto$plural mostrado$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Falha ao ocultar projetos: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Falha ao mostrar projetos: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Tem certeza de que deseja ocultar \"$projectName\"?';
  }

  @override
  String releaseCreated(String title) {
    return 'Lançamento \"$title\" criado com sucesso.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Falha ao criar lançamento: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Erro ao adicionar pasta: $error';
  }

  @override
  String get noProjectsFoundInRoots =>
      'Nenhum projeto encontrado nas pastas de projetos selecionadas.';

  @override
  String get selectProjectsFolder => 'Selecione uma pasta de projetos';

  @override
  String get enterReleaseTitle => 'Digite o Título do Lançamento';

  @override
  String get releaseTitle => 'Título do Lançamento';

  @override
  String get enterReleaseTitleHint => 'Digite o título do lançamento';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Metadados extraídos para $count projeto$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count falhou$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Falha ao escrever arquivo BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Falha ao escrever arquivo de tom: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Falha ao abrir: $error';
  }

  @override
  String get libraryCleared => 'Biblioteca limpa.';

  @override
  String scanType(String type) {
    return 'Varredura $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type concluída: $count projeto$plural adicionado$plural/atualizado$plural.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count projeto$plural selecionado$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Abrindo pasta para $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Falha ao abrir pasta: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Sistema operacional não suportado para abrir pasta.';

  @override
  String get noProjectsAvailable =>
      'Nenhum projeto disponível. Por favor, adicione projetos primeiro.';

  @override
  String get createNewRelease => 'Criar Novo Lançamento';

  @override
  String get deleteRelease => 'Excluir Lançamento';

  @override
  String deleteReleaseMessage(String title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Lançamento \"$title\" excluído.';
  }

  @override
  String get selectTracks => 'Selecionar Faixas';

  @override
  String get continueButton => 'Continuar';

  @override
  String get noReleasesYet => 'Ainda não há lançamentos';

  @override
  String get createFirstRelease =>
      'Crie seu primeiro lançamento selecionando faixas dos seus projetos';

  @override
  String releasesCount(int count) {
    return 'Lançamentos ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Erro ao carregar lançamentos: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Faixas ($count)';
  }

  @override
  String get addTracks => 'Adicionar Faixas';

  @override
  String get allProjectsAlreadyInRelease =>
      'Todos os projetos já estão neste lançamento.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Adicionada$plural $count faixa$plural ao lançamento.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Arquivos do Lançamento ($count)';
  }

  @override
  String get addFiles => 'Adicionar Arquivos';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Adicionado$plural $count arquivo$plural ao lançamento.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Falha ao adicionar arquivos: $error';
  }

  @override
  String get noFilesToDownload => 'Nenhum arquivo para baixar.';

  @override
  String zipFileSaved(String path) {
    return 'Arquivo ZIP salvo em: $path';
  }

  @override
  String failedToCreateZip(String error) {
    return 'Falha ao criar ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Arquivo selecionado não existe.';

  @override
  String get imageSavedSuccessfully => 'Imagem salva com sucesso!';

  @override
  String failedToSaveImage(String error) {
    return 'Falha ao salvar imagem: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Erro ao carregar lançamento: $error';
  }

  @override
  String errorLoadingProjects(String error) {
    return 'Erro ao carregar projetos: $error';
  }

  @override
  String get releaseSaved => 'Lançamento salvo.';

  @override
  String get releaseDate => 'Data do Lançamento';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Falha ao salvar data do lançamento: $error';
  }

  @override
  String get releaseDateSaved => 'Data do lançamento salva.';

  @override
  String get releaseDateCleared => 'Data do lançamento limpa.';

  @override
  String get saveReleaseFilesZip => 'Salvar arquivos ZIP do lançamento';

  @override
  String failedToOpenFile(String error) {
    return 'Falha ao abrir arquivo: $error';
  }

  @override
  String failedToPlayAudio(String error) {
    return 'Falha ao reproduzir áudio: $error';
  }

  @override
  String get renameFile => 'Renomear Arquivo';

  @override
  String get selectTracksToAdd => 'Selecionar Faixas para Adicionar';

  @override
  String get fileNameUpdated => 'Nome do arquivo atualizado.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Erro ao atualizar nome do arquivo: $error';
  }

  @override
  String get deleteFile => 'Excluir Arquivo';

  @override
  String deleteFileMessage(String fileName) {
    return 'Tem certeza de que deseja excluir \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Arquivo \"$fileName\" excluído.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Falha ao excluir arquivo: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Não foi possível abrir a pasta: $error';
  }

  @override
  String get artwork => 'Arte';

  @override
  String get title => 'Título';

  @override
  String get tracks => 'Faixas';

  @override
  String get description => 'Descrição';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Selecionar faixas para incluir no lançamento ($count selecionada$plural)';
  }

  @override
  String get searchTracks => 'Pesquisar faixas';

  @override
  String get searchTracksHint => 'Pesquisar por nome ou tipo de DAW';

  @override
  String get noTracksFound => 'Nenhuma faixa encontrada';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get fileNotFound => 'Arquivo não encontrado';

  @override
  String get fileName => 'Nome do Arquivo';

  @override
  String get editTodo => 'Editar Tarefa';

  @override
  String get todoText => 'Texto da tarefa';

  @override
  String get enterTodoText => 'Digite o texto da tarefa';

  @override
  String get addNewTodo => 'Adicionar nova tarefa';

  @override
  String get enterTodoItem => 'Digite o item da tarefa';

  @override
  String get todoList => 'Lista de Tarefas';

  @override
  String get addToRelease => 'Adicionar ao Lançamento';

  @override
  String get createNew => 'Criar Novo';

  @override
  String get addToExisting => 'Adicionar ao Existente';

  @override
  String get createAndAdd => 'Criar e Adicionar';

  @override
  String get selectRelease => 'Selecione um lançamento';

  @override
  String get noExistingReleasesFound =>
      'Nenhum lançamento existente encontrado.';

  @override
  String get addToSelectedRelease => 'Adicionar ao Lançamento Selecionado';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Falha ao salvar foto do perfil: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Falha ao remover foto do perfil: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Falha ao renomear perfil: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Falha ao excluir perfil: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Erro ao carregar perfis: $error';
  }

  @override
  String get projectPhaseIdea => 'Ideia';

  @override
  String get projectPhaseArranging => 'Arranjo';

  @override
  String get projectPhaseMixing => 'Mixagem';

  @override
  String get projectPhaseMastering => 'Masterização';

  @override
  String get projectPhaseFinished => 'Finalizado';

  @override
  String get changeStatus => 'Alterar Fase';

  @override
  String get selectNewStatus => 'Selecione a nova fase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Fase alterada para \"$status\" em $count projeto$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Fase alterada para \"$status\" em $successCount projeto$successPlural, $failCount falhou$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Falha ao alterar fase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Editar nome do perfil';

  @override
  String get tooltipAddTodo => 'Adicionar tarefa';

  @override
  String get tooltipClearDate => 'Limpar data';

  @override
  String get tooltipPickDate => 'Escolher data';

  @override
  String get tooltipViewDetails => 'Ver Detalhes';

  @override
  String get tooltipLaunchInDaw => 'Abrir no DAW';

  @override
  String get tooltipRemoveFromRelease => 'Remover do Lançamento';

  @override
  String get profile => 'Perfil';

  @override
  String get noDateSet => 'Nenhuma data definida';

  @override
  String get imageNotFound => 'Imagem não encontrada';

  @override
  String get clickToBrowseArtwork => 'Clique para procurar arte';

  @override
  String get noFilesAddedYet =>
      'Nenhum arquivo adicionado ainda.\nClique em \"Adicionar Arquivos\" para fazer upload dos arquivos do lançamento.';

  @override
  String get noTodosYet => 'Nenhuma tarefa ainda. Adicione uma acima.';

  @override
  String get done => 'Concluído';

  @override
  String get backupAndRestore => 'Backup e Restauração';

  @override
  String get exportBackup => 'Exportar Backup';

  @override
  String get importBackup => 'Importar Backup';

  @override
  String get backupExportedSuccessfully => 'Backup exportado com sucesso';

  @override
  String failedToExportBackup(String error) {
    return 'Falha ao exportar backup: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup importado com sucesso: $projectsCount projetos, $rootsCount pastas de projetos, $releasesCount lançamentos';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Falha ao importar backup: $error';
  }

  @override
  String get importBackupMessage => 'Escolha como importar o backup:';

  @override
  String get mergeWithCurrentProfile => 'Mesclar com o perfil ativo atual';

  @override
  String get replaceCurrentProfile =>
      'Substituir completamente o perfil atual (AVISO: Isso excluirá todos os dados do perfil atual)';

  @override
  String get createNewProfileForImport =>
      'Criar um novo perfil para estes dados';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup importado para o novo perfil \"$profileName\": $projectsCount projetos, $rootsCount pastas de projetos, $releasesCount lançamentos';
  }

  @override
  String get noProfileSelected => 'Nenhum perfil selecionado';

  @override
  String get exportBackupDialogTitle => 'Exportar Backup';

  @override
  String get importBackupDialogTitle => 'Importar Backup';

  @override
  String get invalidBackupFileFormat =>
      'Formato de arquivo de backup inválido: versão ausente';

  @override
  String get profileNameRequiredForNewProfile =>
      'O nome do perfil é obrigatório ao criar um novo perfil';

  @override
  String get currentProfileRequired =>
      'O perfil atual é obrigatório para o modo mesclar ou substituir';
}
