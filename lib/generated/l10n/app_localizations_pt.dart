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
  String get enable => 'Ativar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get undo => 'Desfazer';

  @override
  String get customInterval => 'Personalizado';

  @override
  String get close => 'Fechar';

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
  String get refreshProject => 'Atualizar';

  @override
  String get scanning => 'Escaneando…';

  @override
  String get newProjectBadge => 'NOVO';

  @override
  String get projectName => 'Nome do Projeto';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tom (ex: C#m, F maior)';

  @override
  String get notes => 'Notas';

  @override
  String get expandNotes => 'Expandir';

  @override
  String get collapseNotes => 'Recolher';

  @override
  String get projectNotesFromDaw => 'Notas do Projeto (do arquivo da DAW)';

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
  String failedToLaunchProject(String projectName) {
    return 'Falha ao abrir $projectName';
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
  String get pathsSettingsDangerZoneTitle => 'Biblioteca';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Limpe todos os projetos e pastas de projetos do perfil atual.';

  @override
  String get projectFoldersSectionTitle => 'Pastas de projetos';

  @override
  String get projectFoldersSectionSubtitle =>
      'Pastas que serão escaneadas para encontrar projetos de DAW.';

  @override
  String get projectFoldersEmptyTitle => 'Nenhuma pasta de projetos ainda';

  @override
  String get projectFoldersEmptySubtitle =>
      'Adicione pelo menos uma pasta para começar a escanear projetos.';

  @override
  String get notScannedYet => 'Ainda não escaneado';

  @override
  String lastScan(String date) {
    return 'Último scan: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Pastas excluídas';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Estas pastas serão ignoradas durante o scan, mesmo que estejam dentro de uma pasta de projetos.';

  @override
  String get addExcludedFolder => 'Adicionar excluída';

  @override
  String get selectExcludedFolder => 'Selecione uma pasta para excluir';

  @override
  String get excludedFoldersEmptyTitle => 'Nenhuma pasta excluída';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Opcional: adicione pastas que você nunca quer escanear.';

  @override
  String get removeExcludedFolderTitle => 'Remover pasta excluída?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Esta pasta não será mais excluída:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Esta pasta não será mais excluída.';

  @override
  String get desktopOnlyPathsSettings =>
      'Esta página está disponível apenas no app desktop.';

  @override
  String get renameProjectFolderTitle => 'Nome de Exibição';

  @override
  String get flatpakPortalPathExplanation =>
      'Este caminho é um local isolado (sandbox), não o local real da pasta — o Flatpak não compartilha essa informação com o app. Use o nome acima para identificá-la.';

  @override
  String get removeProjectFolderTitle => 'Remover pasta de projetos?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Tem certeza de que deseja remover \"$path\"? Isso também removerá todos os projetos desta pasta que não estão em lançamentos.';
  }

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
  String get searchReleases => 'Pesquisar lançamentos...';

  @override
  String get searchPlaylists => 'Pesquisar playlists...';

  @override
  String get noReleasesFound => 'Nenhum lançamento encontrado';

  @override
  String get noPlaylistsFound => 'Nenhuma playlist encontrada';

  @override
  String get tryDifferentSearch => 'Tente um termo de busca diferente';

  @override
  String get deepScanConfirm =>
      'A Varredura Profunda extrai metadados completos dos arquivos de projeto:\n• BPM (Batidas Por Minuto)\n• Tom Musical\n• Versão do DAW\n• Notas do Projeto (quando suportado)\n\nIsso é mais lento que uma varredura comum e pode levar um tempo. Continuar?';

  @override
  String get deepScanViewSupportedDaws => 'Ver DAWs e campos suportados';

  @override
  String get deepScanOnlyUnscanned => 'Escanear apenas projetos sem metadados';

  @override
  String get metadataExtractionTitle => 'Extração de Metadados';

  @override
  String get metadataExtractionSubtitle => 'Veja quais dados cada DAW suporta';

  @override
  String get metadataExtractionIntro =>
      'A Varredura Profunda pode ler automaticamente alguns desses campos diretamente do arquivo do projeto — o restante precisa ser inserido manualmente. Esta tabela mostra o que é automático hoje para cada DAW suportada.';

  @override
  String get metadataFieldKey => 'Tom';

  @override
  String get metadataFieldVersion => 'Versão do DAW';

  @override
  String get metadataExtractionManualNote =>
      'Qualquer campo sem suporte automático ainda pode ser inserido manualmente no Detalhe do Projeto. Para BPM e Tom especificamente, colocar um arquivo bpm.txt ou key.txt ao lado do projeto também é detectado na próxima varredura.';

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
  String get filters => 'Filtros';

  @override
  String get allPhases => 'Todas as Fases';

  @override
  String get filterByDaw => 'Filtrar por DAW';

  @override
  String get allDaws => 'Todas as DAWs';

  @override
  String get daw => 'DAW';

  @override
  String get clearDaw => 'Limpar DAW';

  @override
  String get filterByKey => 'Filtrar por Tom';

  @override
  String get allKeys => 'Todos os Tons';

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
  String scanProgressLabel(int current, int total) {
    return 'Carregando projeto $current de $total…';
  }

  @override
  String get search => 'Buscar';

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
  String get deleteRootPath => 'Remover pasta de projetos';

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
  String get deleteMissingProjects => 'Excluir ausentes';

  @override
  String get deleteMissingProjectsTitle => 'Excluir projetos ausentes?';

  @override
  String deleteMissingProjectsConfirm(int count, String plural) {
    return '$count projeto$plural cujo arquivo não pôde ser encontrado nesta máquina serão excluídos permanentemente, junto com todas as notas, prazos e histórico de sessões. Isso não pode ser desfeito.';
  }

  @override
  String get deleteMissingProjectsConfirmButton => 'Excluir permanentemente';

  @override
  String missingProjectsDeleted(int count, String plural) {
    return '$count projeto$plural ausente excluído.';
  }

  @override
  String deleteMissingProjectsAlsoDeleteReleaseTracked(
    int count,
    String plural,
  ) {
    return 'Também excluir $count projeto$plural que fazem parte de um lançamento (também os remove desse lançamento)';
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
  String get folderAlreadyAdded => 'Esta pasta já foi adicionada.';

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
  String get scanCancelled => 'Varredura cancelada.';

  @override
  String scanFailuresSnackbar(int count, String plural) {
    return '$count projeto$plural não pôde/puderam ser carregado$plural.';
  }

  @override
  String get scanFailuresSnackbarAction => 'Detalhes';

  @override
  String get scanFailuresDialogTitle => 'Erros de Varredura';

  @override
  String get scanFailuresDialogIntro =>
      'Estes arquivos não puderam ser lidos durante a varredura (podem ter sido excluídos, movidos ou bloqueados por outro programa):';

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
  String get creatingZipFile => 'Criando arquivo ZIP...';

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
  String get errorLoadingProjects => 'Erro ao carregar projetos';

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
  String get failedToOpenFile => 'Falha ao abrir arquivo';

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
  String addTodoAtTimestamp(String timestamp) {
    return 'Adicionar tarefa em $timestamp';
  }

  @override
  String todoAddedAtTimestamp(String timestamp) {
    return 'Tarefa adicionada em $timestamp';
  }

  @override
  String get todoList => 'Lista de Tarefas';

  @override
  String get todoTemplates => 'Templates de TODO';

  @override
  String get createTemplate => 'Criar Template';

  @override
  String get editTemplate => 'Editar Template';

  @override
  String get deleteTemplate => 'Excluir Template';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Tem certeza que deseja excluir o template \"$name\"?';
  }

  @override
  String get templateName => 'Nome do Template';

  @override
  String get templateNameHint => 'ex. Checklist de Mixagem';

  @override
  String get templateItems => 'Itens do Template';

  @override
  String get templateItemsHint => 'Um item por linha';

  @override
  String get templateNameAndItemsRequired =>
      'Nome e itens do template são obrigatórios';

  @override
  String get templateItemsRequired => 'Pelo menos um item é obrigatório';

  @override
  String get templateCreated => 'Template criado';

  @override
  String get templateUpdated => 'Template atualizado';

  @override
  String get templateDeleted => 'Template excluído';

  @override
  String get noTemplatesYet => 'Nenhum template ainda';

  @override
  String get createFirstTemplate => 'Crie seu primeiro template de TODO';

  @override
  String templateItemCount(int count) {
    return '$count item(ns)';
  }

  @override
  String get selectTemplate => 'Selecionar Template';

  @override
  String get importFromTemplate => 'Importar de Template';

  @override
  String get manageTemplates => 'Gerenciar Templates';

  @override
  String get noTemplatesAvailable =>
      'Nenhum template disponível. Crie um primeiro.';

  @override
  String templateImported(String name, int count) {
    return 'Template \"$name\" importado ($count itens)';
  }

  @override
  String get errorLoadingTemplates => 'Erro ao carregar templates';

  @override
  String get createProjectStartFrom => 'Como você quer começar?';

  @override
  String get createProjectStartFromHint =>
      'Comece com uma pasta vazia ou copie um template registrado.';

  @override
  String get createProjectEmptyFolder => 'Pasta Vazia';

  @override
  String get createProjectFromTemplate => 'A partir de Template';

  @override
  String get selectTemplateMainFile =>
      'Selecione o Arquivo Principal do Template';

  @override
  String get registerTemplate => 'Registrar Template';

  @override
  String get projectTemplates => 'Templates de Projeto';

  @override
  String get searchTemplates => 'Buscar templates...';

  @override
  String get createFirstProjectTemplate =>
      'Registre uma pasta de template para reutilizar em novos projetos';

  @override
  String get noMatchingTemplates => 'Nenhum template correspondente';

  @override
  String get templateSourceMissing =>
      'Pasta de origem do template não encontrada';

  @override
  String get useTemplate => 'Usar';

  @override
  String get selectTemplatesParentFolder =>
      'Selecione a Pasta Principal dos Templates';

  @override
  String get templateSourceFolder => 'Pasta de Origem';

  @override
  String get dateCreatedColumn => 'Criado';

  @override
  String get dateModifiedColumn => 'Modificado';

  @override
  String get manageTemplateFolders => 'Gerenciar Pastas';

  @override
  String get addTemplateFolder => 'Adicionar Pasta';

  @override
  String get removeTemplateFolder => 'Remover Pasta de Template';

  @override
  String removeTemplateFolderConfirm(String path) {
    return 'Remover \"$path\" das suas pastas de templates registradas? Templates já importados não serão excluídos.';
  }

  @override
  String get noTemplateFoldersRegistered =>
      'Nenhuma pasta de template registrada';

  @override
  String get refreshTemplateFolders =>
      'Atualizar templates das pastas registradas';

  @override
  String lastRefreshed(String date) {
    return 'Última atualização $date';
  }

  @override
  String templatesRefreshedSummary(int count) {
    return '$count novo(s) template(s) adicionado(s)';
  }

  @override
  String templatesSelected(int count, String plural) {
    return '$count template$plural selecionado$plural';
  }

  @override
  String get deleteSelectedTemplates => 'Excluir selecionados';

  @override
  String deleteSelectedTemplatesConfirm(int count, String plural) {
    return 'Tem certeza de que deseja excluir $count template$plural?';
  }

  @override
  String templatesDeleted(int count, String plural) {
    return '$count template$plural excluído$plural';
  }

  @override
  String get templateDetailTitle => 'Template';

  @override
  String get templateNotFound => 'Template não encontrado';

  @override
  String get saveAsTemplate => 'Salvar como Template';

  @override
  String get newTemplateNameLabel => 'Nome do template';

  @override
  String get savedAsTemplate => 'Salvo como template';

  @override
  String get duplicateTemplate => 'Duplicar';

  @override
  String get templateDuplicated => 'Template duplicado';

  @override
  String get fileInfo => 'Informações do Arquivo';

  @override
  String get fileSize => 'Tamanho do Arquivo';

  @override
  String get filePath => 'Caminho';

  @override
  String get fileModified => 'Última Modificação';

  @override
  String projectsFromThisTemplate(int count) {
    return 'Projetos Criados a Partir Deste Template ($count)';
  }

  @override
  String get noProjectsFromThisTemplate =>
      'Nenhum projeto criado a partir deste template ainda';

  @override
  String get importTodos => 'Importar Tarefas de Arquivo';

  @override
  String get noTodosInFile => 'Nenhuma tarefa encontrada no arquivo';

  @override
  String todosImported(int count) {
    return '$count tarefa(s) importada(s) com sucesso';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Erro ao importar tarefas: $error';
  }

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
  String get dropImageHere => 'Solte a imagem aqui';

  @override
  String get removeArtwork => 'Remover arte';

  @override
  String get removeArtworkConfirm =>
      'Remover esta arte? O arquivo de imagem será excluído.';

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
  String get backupTabLabel => 'Backup';

  @override
  String get aboutTabLabel => 'Sobre';

  @override
  String get localBackup => 'Backup Local';

  @override
  String get appearanceTabLabel => 'Aparência';

  @override
  String get exportBackup => 'Exportar Backup';

  @override
  String get importBackup => 'Importar Backup';

  @override
  String get exportProjectInfo => 'Exportar informações';

  @override
  String get exportProjectInfoTooltip =>
      'Salvar as informações deste projeto em um arquivo de texto';

  @override
  String get exportAllProjectsInfo => 'Exportar todos os projetos para TXT';

  @override
  String get exportAllProjectsInfoSubtitle =>
      'Salva um registro em texto com as informações de todos os projetos, mantido mesmo após excluir o arquivo do DAW';

  @override
  String get projectInfoExported => 'Informações do projeto exportadas';

  @override
  String allProjectsInfoExported(int count) {
    return 'Informações exportadas de $count projetos';
  }

  @override
  String failedToExportProjectInfo(String error) {
    return 'Falha ao exportar informações do projeto: $error';
  }

  @override
  String get projectExportHeaderTitle => 'DAW PROJECT MANAGER — PROJECT EXPORT';

  @override
  String projectExportExportedLabel(String dateTime) {
    return 'Exportado: $dateTime';
  }

  @override
  String projectExportTotalProjectsLabel(int count) {
    return 'Total de projetos: $count';
  }

  @override
  String projectExportProjectLabel(String name) {
    return 'Projeto: $name';
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
    return 'Status: $status';
  }

  @override
  String projectExportBpmLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String projectExportKeyLabel(String key) {
    return 'Tom: $key';
  }

  @override
  String projectExportKeyWithCamelotLabel(String key, String code) {
    return 'Tom: $key (Camelot $code)';
  }

  @override
  String projectExportFilePathLabel(String path) {
    return 'Caminho do arquivo: $path';
  }

  @override
  String projectExportFileSizeLabel(String size) {
    return 'Tamanho do arquivo: $size';
  }

  @override
  String projectExportFileCreatedLabel(String date) {
    return 'Arquivo criado: $date';
  }

  @override
  String projectExportAddedToLibraryLabel(String date) {
    return 'Adicionado à biblioteca: $date';
  }

  @override
  String projectExportLastModifiedLabel(String date) {
    return 'Última modificação: $date';
  }

  @override
  String projectExportDeadlineLabel(String date) {
    return 'Prazo: $date';
  }

  @override
  String projectExportDeadlineWithStatusLabel(String date, String status) {
    return 'Prazo: $date ($status)';
  }

  @override
  String projectExportTotalTimeWorkedLabel(String duration) {
    return 'Tempo total trabalhado: $duration';
  }

  @override
  String get projectExportNotesLabel => 'Notas:';

  @override
  String get projectExportTodosLabel => 'Tarefas:';

  @override
  String projectExportWorkSessionsLabel(int count) {
    return 'Sessões de trabalho ($count):';
  }

  @override
  String get noProjectsToExport => 'Nenhum projeto para exportar';

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

  @override
  String get previewSong => 'Música de Prévia';

  @override
  String get noPreviewSongTitle => 'Sem música de visualização';

  @override
  String get noPreviewSongMessage =>
      'Este projeto não tem uma música de visualização definida. Selecione um arquivo de áudio para carregá-lo e reproduzi-lo.';

  @override
  String get noPreviewSongDragHint =>
      'Você também pode arrastar e soltar um arquivo de áudio diretamente na linha do projeto na tabela.';

  @override
  String get previewSongRemoved => 'Música de prévia removida';

  @override
  String get previewSongAdded => 'Música de prévia adicionada';

  @override
  String get previewSongFileNotFound =>
      'Arquivo de música de prévia não encontrado';

  @override
  String get previewSongFileNotFoundMessage =>
      'O arquivo da música de visualização não foi encontrado no disco. Deseja selecionar um novo arquivo ou remover a entrada?';

  @override
  String get selectNewFile => 'Selecionar novo arquivo';

  @override
  String failedToPlayPreview(String error) {
    return 'Falha ao reproduzir prévia: $error';
  }

  @override
  String get removePreviewSong => 'Remover música de prévia';

  @override
  String get removePreviewSongConfirm =>
      'Tem certeza de que deseja remover a música de prévia? Esta ação não pode ser desfeita.';

  @override
  String get noPreviewSongSelected => 'Nenhuma música de prévia selecionada';

  @override
  String get changePreviewSong => 'Alterar Música de Prévia';

  @override
  String get selectPreviewSong => 'Selecionar Música de Prévia';

  @override
  String get dropAudioFileHere => 'Solte o arquivo de áudio aqui';

  @override
  String projectAge(String age) {
    return 'Idade do projeto: $age';
  }

  @override
  String createdDate(String date) {
    return 'criado $date';
  }

  @override
  String completedIn(String duration) {
    return 'Concluído em: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'finalizado $date';
  }

  @override
  String get dateToday => 'hoje';

  @override
  String get dateYesterday => 'ontem';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count semanas',
      one: 'há 1 semana',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count meses',
      one: 'há 1 mês',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    return 'há $count ano$plural';
  }

  @override
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  ) {
    return '$years ano$yearPlural, $months meses';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years ano$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months meses, $days dia$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months meses';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days dia$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours hora$plural';
  }

  @override
  String get ageJustNow => 'Agora mesmo';

  @override
  String get ageLessThanHour => 'Menos de uma hora';

  @override
  String get viewProfile => 'Ver Perfil';

  @override
  String get googleDriveSync => 'Sincronização Google Drive';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Sincronize seus dados com o Google Drive para fazer backup e restaurar entre dispositivos.';

  @override
  String get manageGoogleDriveSync => 'Gerenciar Sincronização Google Drive';

  @override
  String get signInToGoogleDrive => 'Entrar no Google Drive';

  @override
  String get syncNow => 'Sincronizar Agora';

  @override
  String get uploadBackup => 'Enviar Backup';

  @override
  String get downloadBackup => 'Baixar Backup';

  @override
  String get newerBackupAvailable => 'Novo backup disponível na nuvem';

  @override
  String get restoreProjectFromDrive => 'Restaurar do Drive';

  @override
  String get restoringProjectFromDrive => 'Restaurando do Drive...';

  @override
  String get projectRestoredFromDrive => 'Projeto restaurado do Drive';

  @override
  String get projectNotFoundInBackup =>
      'Este projeto não foi encontrado no backup do Drive';

  @override
  String get signInToGoogleDriveFirst =>
      'Por favor, faça login no Google Drive primeiro (abra as configurações do Drive Sync)';

  @override
  String get signOut => 'Sair';

  @override
  String get downloadPreviewSongs => 'Baixar músicas de prévia';

  @override
  String get downloadPreviewSongsExplanation =>
      'Se desmarcado, as músicas de prévia serão ignoradas (economiza tempo e armazenamento). Você pode baixá-las depois se necessário.';

  @override
  String get replaceLocalData => 'Substituir Dados Locais';

  @override
  String get downloadBackupConfirmation =>
      'Isso substituirá seus dados locais pelo backup do Google Drive.\n\nTem certeza de que deseja continuar?';

  @override
  String get enterAuthorizationCode => 'Inserir Código de Autorização';

  @override
  String get authorizationCode => 'Código de Autorização';

  @override
  String get pasteCodeFromBrowser => 'Cole o código do navegador';

  @override
  String get sessionActive => 'Sessão ativa';

  @override
  String get signedIn => 'Conectado';

  @override
  String get creatingInitialBackup => 'Criando backup inicial...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Conectado e backup criado com sucesso no Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Conectado e backup criado com sucesso no Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Conectado com sucesso ao Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Conectado com sucesso ao Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Entrada cancelada ou falhou. Verifique o console para detalhes.';

  @override
  String get failedToLaunchBrowser => 'Falha ao abrir o navegador';

  @override
  String get signInCancelled => 'Entrada cancelada';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Falha ao trocar código de autorização';

  @override
  String errorSigningIn(String error) {
    return 'Erro ao entrar: $error';
  }

  @override
  String get unknownError => 'Erro desconhecido';

  @override
  String get googleSignInError => 'Erro de Entrada do Google';

  @override
  String get developerConsoleNotSetUp =>
      'O console do desenvolvedor não está configurado corretamente. Verifique sua configuração OAuth no Google Cloud Console.';

  @override
  String get platformError => 'Erro de Plataforma';

  @override
  String get signedOutFromGoogleDrive => 'Desconectado do Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Erro ao sair: $error';
  }

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get errorNoProfileSelected => 'Erro: Nenhum perfil selecionado';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Sincronização concluída! Projetos: +$projectsAdded ~$projectsUpdated, Lançamentos: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Erro ao sincronizar: $error';
  }

  @override
  String get uploadingBackup => 'Enviando backup...';

  @override
  String get backupUploadedSuccessfully => 'Backup enviado com sucesso!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Backup enviado com sucesso para o Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Erro ao enviar backup: $error';
  }

  @override
  String get downloadingBackup => 'Baixando backup...';

  @override
  String get checkingForBackup => 'Verificando backup...';

  @override
  String get backupUpToDate => 'Backup está atualizado';

  @override
  String errorCheckingBackup(String error) {
    return 'Erro ao verificar backup: $error';
  }

  @override
  String get download => 'Baixar';

  @override
  String get remoteBackupIsNewer =>
      'O backup remoto é mais recente que os dados locais. O upload irá sobrescrevê-lo.';

  @override
  String get confirmUpload => 'Confirmar Upload';

  @override
  String get noBackupFileFound =>
      'Nenhum arquivo de backup encontrado no Google Drive. Crie um backup primeiro sincronizando seus dados.';

  @override
  String get noBackupFileFoundStatus =>
      'Nenhum arquivo de backup encontrado. Crie um backup primeiro.';

  @override
  String get downloadCancelled => 'Download cancelado';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Backup baixado! Projetos: +$projectsAdded ~$projectsUpdated, Lançamentos: +$releasesAdded ~$releasesUpdated';
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
    return 'Backup baixado!\n\nProjetos:\n  • $projectsAdded adicionados\n  • $projectsUpdated atualizados\n\nLançamentos:\n  • $releasesAdded adicionados\n  • $releasesUpdated atualizados\n\nPreview Songs:\n  • $previewSongsDownloaded baixadas\n  • $previewSongsUpdated atualizadas';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Erro ao baixar backup: $error';
  }

  @override
  String get notSignedInYet => 'Não conectado';

  @override
  String get never => 'Nunca';

  @override
  String signedInAs(String email) {
    return 'Conectado como: $email';
  }

  @override
  String lastSync(String date) {
    return 'Última sincronização: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Backup remoto: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Último envio: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Último download: $date';
  }

  @override
  String get checkForBackup => 'Verificar Backup';

  @override
  String get notificationSettings => 'Configurações de Notificação';

  @override
  String get notificationsOnlyOnAndroid =>
      'Notificações de prazo estão disponíveis apenas em dispositivos Android.';

  @override
  String get notificationPermissionRequired =>
      'Permissão de Notificação Necessária';

  @override
  String get notificationPermissionDescription =>
      'Por favor, habilite notificações para receber lembretes de prazos.';

  @override
  String get notificationPermissionDenied =>
      'Permissão de notificação negada. Por favor, habilite nas configurações.';

  @override
  String get notificationSettingsSaved =>
      'Configurações de notificação salvas com sucesso';

  @override
  String get errorSavingSettings => 'Erro ao salvar configurações';

  @override
  String get enableDeadlineNotifications => 'Habilitar Notificações de Prazo';

  @override
  String get receiveRemindersForDeadlines =>
      'Receber lembretes para prazos de projetos';

  @override
  String get notificationTime => 'Horário de Notificação';

  @override
  String get timeToReceiveNotifications =>
      'Horário do dia para receber notificações';

  @override
  String get reminderDays => 'Dias de Lembrete';

  @override
  String get selectDaysBeforeDeadline =>
      'Selecione quantos dias antes do prazo você deseja ser notificado';

  @override
  String get notifyOnDeadlineDay => 'Notificar no Dia do Prazo';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Também receber uma notificação no próprio dia do prazo';

  @override
  String get howItWorks => 'Como Funciona';

  @override
  String get deadlineNotificationsHelp =>
      'Você receberá notificações no horário especificado nos dias selecionados antes de cada prazo de projeto. Toque em uma notificação para abrir os detalhes do projeto.';

  @override
  String get oneDay => '1 dia';

  @override
  String xDays(int count) {
    return '$count dias';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get searchSettings => 'Pesquisar configurações';

  @override
  String noSettingsFoundFor(String query) {
    return 'Nenhuma configuração encontrada para \"$query\"';
  }

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get languageSettingDescription =>
      'O idioma usado em todo o aplicativo.';

  @override
  String get themeSettingDescription => 'O tema de cores do aplicativo.';

  @override
  String get waveformStyle => 'Estilo da Forma de Onda';

  @override
  String get waveformStyleSettingDescription =>
      'Como a forma de onda da prévia de áudio é desenhada.';

  @override
  String get waveformStyleDetailed => 'Detalhado';

  @override
  String get waveformStyleDetailedDescription =>
      'Barras por pixel com corpo sombreado, como em uma DAW.';

  @override
  String get waveformStyleClassic => 'Clássico';

  @override
  String get waveformStyleClassicDescription => 'Um único contorno preenchido.';

  @override
  String get waveformChannels => 'Canais';

  @override
  String get waveformChannelsSettingDescription =>
      'Se a forma de onda divide o estéreo em duas faixas.';

  @override
  String get waveformChannelsSingle => 'Único';

  @override
  String get waveformChannelsDual => 'Duplo';

  @override
  String get waveformChannelsSingleDescription =>
      'Uma faixa mostrando a mixagem estéreo.';

  @override
  String get waveformChannelsDualDescription =>
      'Esquerda e direita empilhadas em faixas separadas.';

  @override
  String get waveformChannelsUnavailable => 'Este arquivo tem apenas um canal';

  @override
  String get support => 'Apoiar';

  @override
  String get shareDiagnosticLog => 'Compartilhar Log de Diagnóstico';

  @override
  String get shareDiagnosticLogEmpty => 'Ainda não há log de diagnóstico';

  @override
  String get shareDiagnosticLogFolderOpened =>
      'O compartilhamento não está disponível aqui. A pasta de logs foi aberta para que você possa anexar o arquivo manualmente.';

  @override
  String get enableDiagnosticLogging => 'Ativar Registro de Diagnóstico';

  @override
  String get enableDiagnosticLoggingDescription =>
      'Mantém um pequeno registro de falhas e erros neste dispositivo, para que você possa compartilhá-lo se algo der errado. Desativado por padrão.';

  @override
  String get clearDiagnosticLog => 'Limpar Registro de Diagnóstico';

  @override
  String get clearDiagnosticLogConfirmTitle =>
      'Limpar registro de diagnóstico?';

  @override
  String get clearDiagnosticLogConfirmMessage =>
      'Isso excluirá permanentemente o arquivo de registro de diagnóstico. Essa ação não pode ser desfeita.';

  @override
  String get diagnosticLogCleared => 'Registro de diagnóstico limpo';

  @override
  String get supportTheProject => 'Apoie o projeto';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Não foi possível abrir o navegador. Por favor, visite: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Erro ao abrir o navegador: $error';
  }

  @override
  String get generateTestingDatabase => 'Gerar Base de Dados de Teste';

  @override
  String get generateTestingDatabaseMessage =>
      'Isso irá criar (ou atualizar) um perfil dedicado \"Demo — Screenshots\" preenchido com uma grande variedade de projetos, lançamentos e playlists de exemplo em todas as DAWs suportadas, e mudar para ele. Seus outros perfis permanecem inalterados. Continuar?';

  @override
  String get testingDatabaseGenerated =>
      'Perfil de demonstração pronto — alternado para ele!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Falha ao gerar base de dados de teste: $error';
  }

  @override
  String get removeTestingDatabase => 'Remover base de dados de teste';

  @override
  String get removeTestingDatabaseMessage =>
      'Isso excluirá permanentemente o perfil \"Demo — Screenshots\" e todos os seus projetos, lançamentos, playlists e arquivos de áudio de pré-visualização de exemplo. Continuar?';

  @override
  String get testingDatabaseRemoved => 'Dados de demonstração removidos.';

  @override
  String get noTestingDatabaseFound =>
      'Nenhum dado de demonstração encontrado para remover.';

  @override
  String failedToRemoveTestingDatabase(String error) {
    return 'Falha ao remover base de dados de teste: $error';
  }

  @override
  String get playlists => 'Playlists';

  @override
  String get playlistsDesktopOnly =>
      'Playlists estão disponíveis apenas no Android.';

  @override
  String get noPlaylistsYet => 'Ainda não há playlists';

  @override
  String get createFirstPlaylist =>
      'Toque no botão + para criar sua primeira playlist';

  @override
  String playlistSongCount(int count) {
    return '$count músicas';
  }

  @override
  String get createPlaylist => 'Criar Playlist';

  @override
  String get playlistName => 'Nome da Playlist';

  @override
  String get playlistNameHint => 'Minha Playlist';

  @override
  String get playlistNameRequired => 'Nome da playlist é obrigatório';

  @override
  String get editPlaylist => 'Editar Playlist';

  @override
  String get stopPlaybackBeforeEditing =>
      'Por favor, pare a reprodução antes de editar a playlist';

  @override
  String get selectPreviewSongs => 'Selecionar Prévias';

  @override
  String get deletePlaylist => 'Excluir Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Tem certeza que deseja excluir \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Playlist excluída';

  @override
  String get errorDeletingPlaylist => 'Erro ao excluir playlist';

  @override
  String get playlistUpdated => 'Playlist atualizada';

  @override
  String get changeSong => 'Trocar Música';

  @override
  String get changeSongConfirm =>
      'Uma música está tocando. Deseja trocar para esta música?';

  @override
  String get changeSongButton => 'Trocar';

  @override
  String playlistProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'Nenhuma prévia disponível nesta playlist';

  @override
  String get tapEditToAddSongs =>
      'Toque em editar para adicionar músicas a esta playlist';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Nenhum projeto com músicas de preview disponíveis para adicionar';

  @override
  String get noProjectsInDatabase =>
      'Nenhum projeto encontrado no banco de dados. Por favor, sincronize seus projetos primeiro.';

  @override
  String get firstTimeSyncTitle => 'Parece que é sua primeira vez aqui!';

  @override
  String get firstTimeSyncMessage =>
      'Vamos sincronizar seus dados do Google Drive para começar';

  @override
  String get syncWithGoogleDrive => 'Sincronizar com Google Drive';

  @override
  String get errorLoadingPlaylists => 'Erro ao carregar playlists';

  @override
  String get playlistItems => 'Itens da Playlist';

  @override
  String get addSongs => 'Adicionar Músicas';

  @override
  String get addAudioFiles => 'Adicionar Arquivos de Áudio';

  @override
  String get selectAudioFiles => 'Selecionar Arquivos de Áudio';

  @override
  String get selectFromProjects => 'Selecionar dos Projetos';

  @override
  String get add => 'Adicionar';

  @override
  String get addTaskAtTimestamp => 'Adicionar tarefa no tempo atual';

  @override
  String get taskDescriptionHint => 'Descrição da tarefa';

  @override
  String get taskAdded => 'Tarefa adicionada';

  @override
  String get fromProject => 'Do Projeto';

  @override
  String get projectDeadline => 'Prazo do Projeto';

  @override
  String get noDeadlineSet => 'Sem prazo definido';

  @override
  String get camelotCode => 'Código Camelot';

  @override
  String get deadline => 'Prazo';

  @override
  String get dueToday => 'Vence hoje';

  @override
  String daysLate(int days) {
    return '${days}d atrasado';
  }

  @override
  String daysLeft(int days) {
    return '${days}d restantes';
  }

  @override
  String get hideFinished => 'Ocultar Finalizados';

  @override
  String get showOnlyDeadlines => 'Mostrar prazo';

  @override
  String get filterByDeadline => 'Filtrar por Prazo';

  @override
  String get allDeadlines => 'Todos os Prazos';

  @override
  String get hasDeadline => 'Com Prazo';

  @override
  String get overdue => 'Atrasado';

  @override
  String get dueSoon => 'Vence em Breve (7d)';

  @override
  String get today => 'Hoje';

  @override
  String get noPreviewSong => 'Sem prévia';

  @override
  String get playPreview => 'Reproduzir Prévia';

  @override
  String get uploadCancelled => 'Upload cancelado';

  @override
  String get backupUploadCancelledByUser =>
      'Upload de backup cancelado pelo usuário';

  @override
  String get collectingData => 'Coletando dados...';

  @override
  String get uploadingPreviewSongs => 'Enviando músicas de prévia...';

  @override
  String get uploadingProfilePhotos => 'Enviando fotos de perfil...';

  @override
  String get uploadingReleaseArtwork => 'Enviando artwork de lançamentos...';

  @override
  String get uploadingDatabase => 'Enviando banco de dados...';

  @override
  String get completed => 'Concluído!';

  @override
  String get cancelling => 'Cancelando...';

  @override
  String get uploadingBackupTitle => 'Enviando Backup';

  @override
  String get cancellingUpload => 'Cancelando upload...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Por favor aguarde enquanto paramos o upload...';

  @override
  String get downloadingDatabase => 'Baixando banco de dados...';

  @override
  String get downloadingPreviewSongs => 'Baixando músicas de prévia...';

  @override
  String get downloadingProfilePhotos => 'Baixando fotos de perfil...';

  @override
  String get downloadingReleaseArtwork => 'Baixando artwork de lançamentos...';

  @override
  String get mergingData => 'Mesclando dados...';

  @override
  String get downloadingBackupTitle => 'Baixando Backup';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Arquivo fonte não encontrado nesta máquina';

  @override
  String get metadataExtractionNotSupportedForDaw =>
      'A extração de metadados não é suportada para este DAW';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Arquivo fonte não encontrado nesta máquina — modo somente metadados. Você ainda pode editar e exportar metadados.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Música de prévia não disponível. Por favor, baixe o backup primeiro.';

  @override
  String get sharePreviewSong => 'Compartilhar música de prévia';

  @override
  String get shareAsZip => 'Compartilhar como ZIP';

  @override
  String get share => 'Compartilhar';

  @override
  String get convertingAudioForSharing =>
      'Preparando o áudio para compartilhar…';

  @override
  String get shareSheetUnavailable =>
      'O menu de compartilhamento do sistema não está disponível aqui — use o botão \"Arraste para Compartilhar\" na prévia da música para arrastar o arquivo até outro app.';

  @override
  String get dragToShare => 'Arraste para Compartilhar';

  @override
  String get dragToShareTooltip =>
      'Arraste isso para a janela de outro app (ex: WhatsApp) pra compartilhar o arquivo direto — útil quando o botão Compartilhar não abre um menu de compartilhamento.';

  @override
  String get mp3ConversionFailed =>
      'A conversão de áudio não está disponível neste sistema — compartilhando o arquivo original, que alguns apps como o WhatsApp podem rejeitar.';

  @override
  String get shareZip => 'Compartilhar ZIP';

  @override
  String get saveCopy => 'Baixar cópia';

  @override
  String savedCopyTo(String path) {
    return 'Guardado em $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Falha ao compartilhar música de prévia: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Falha ao compartilhar música de prévia como ZIP: $error';
  }

  @override
  String get biographySaved => 'Biografia salva';

  @override
  String failedToSaveBiography(String error) {
    return 'Falha ao salvar biografia: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Arquivo salvo em $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Falha ao baixar arquivo: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Todos os arquivos salvos em $filename';
  }

  @override
  String get artworkAdded => 'Arte adicionada';

  @override
  String failedToAddArtwork(String error) {
    return 'Falha ao adicionar arte: $error';
  }

  @override
  String get artworkRemoved => 'Arte removida';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Falha ao remover arte: $error';
  }

  @override
  String get pressKitFileAdded => 'Arquivo do press kit adicionado';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Falha ao adicionar arquivo do press kit: $error';
  }

  @override
  String get pressKitFileRemoved => 'Arquivo do press kit removido';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Falha ao remover arquivo do press kit: $error';
  }

  @override
  String get selectFilesToDownload => 'Selecionar Arquivos para Baixar';

  @override
  String get biography => 'Biografia';

  @override
  String get biographyWillBeSaved => 'Será salvo como biography.txt';

  @override
  String get artworkFiles => 'Arquivos de Arte';

  @override
  String get pressKitFiles => 'Arquivos do Press Kit';

  @override
  String get additionalAssets => 'Ativos Adicionais';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Baixar $count arquivo$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count arquivo$plural salvo em $filename';
  }

  @override
  String get addAsset => 'Adicionar Ativo';

  @override
  String get assetNameLabel => 'Nome do Ativo';

  @override
  String get assetNameHint => 'ex.: Logo, Banner, Foto';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName adicionado com sucesso';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Falha ao adicionar ativo: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName removido';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Falha ao remover ativo: $error';
  }

  @override
  String get profileNotFound => 'Perfil não encontrado';

  @override
  String get downloadFilesSectionTitle => 'Baixar Arquivos';

  @override
  String get downloadFilesSectionDescription =>
      'Baixe todos os arquivos deste perfil — biografia, arte, press kit e ativos adicionais — como um único ZIP, ou selecione quais incluir.';

  @override
  String get selectFiles => 'Selecionar Arquivos';

  @override
  String get downloadAll => 'Baixar Tudo';

  @override
  String get saveBiographyTooltip => 'Salvar Biografia';

  @override
  String get enterBiographyHint => 'Digite a biografia do perfil...';

  @override
  String get addArtwork => 'Adicionar Arte';

  @override
  String get addFile => 'Adicionar Arquivo';

  @override
  String get openFile => 'Abrir Arquivo';

  @override
  String get menuView => 'Visualizar';

  @override
  String get menuAbout => 'Sobre o DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentação';

  @override
  String get menuLanguage => 'Idioma';

  @override
  String get menuWarnBeforeQuit => 'Avisar Antes de Sair (⌘+Q)';

  @override
  String get menuQuit => 'Sair do DAW Project Manager';

  @override
  String get quitConfirmTitle => 'Sair do DAW Project Manager?';

  @override
  String get quitConfirmMessage => 'Tem certeza de que deseja sair?';

  @override
  String get quit => 'Sair';

  @override
  String get trayNoticeTitle => 'Ainda rodando em segundo plano';

  @override
  String get trayNoticeBody =>
      'O DAW Project Manager foi minimizado para a bandeja do sistema. Use o ícone da bandeja para reabrir ou sair.';

  @override
  String get trayShowWindow => 'Mostrar DAW Project Manager';

  @override
  String trayLastBackup(String when) {
    return 'Último backup: $when';
  }

  @override
  String get trayNeverBackedUp => 'Nenhum backup feito ainda';

  @override
  String get trayBackupNow => 'Fazer Backup Agora';

  @override
  String get trayPauseSession => 'Pausar Sessão';

  @override
  String get trayResumeSession => 'Retomar Sessão';

  @override
  String get closeToTray => 'Fechar para a bandeja';

  @override
  String get closeToTrayDescription =>
      'Continuar rodando em segundo plano (ícone na bandeja) ao fechar a janela, para o backup automático e as notificações continuarem funcionando';

  @override
  String get autoStart => 'Iniciar com o sistema';

  @override
  String get autoStartDescription =>
      'Abrir o DAW Project Manager automaticamente ao entrar no computador';

  @override
  String get startMinimized => 'Iniciar minimizado na bandeja';

  @override
  String get startMinimizedDescription =>
      'Quando o app iniciar com o computador, abri-lo oculto na bandeja em vez de mostrar a janela';

  @override
  String get onboardingStartMinimized => 'Iniciar minimizado';

  @override
  String get autoStartFailed =>
      'Não foi possível alterar a configuração de inicialização. Seu sistema pode não permitir.';

  @override
  String get onboardingStartupTitle => 'Iniciar com o Sistema';

  @override
  String get onboardingStartupBody =>
      'Deixe o DAW Project Manager abrir automaticamente ao entrar no computador, para que os backups e os lembretes de prazo continuem funcionando.';

  @override
  String get menuWindow => 'Janela';

  @override
  String get donate => 'Doar';

  @override
  String get website => 'Site';

  @override
  String get license => 'Licença';

  @override
  String get reportIssue => 'Relatar um Problema';

  @override
  String get switchToClassicDark => 'Mudar para Classic Dark';

  @override
  String get switchToNeonDark => 'Mudar para Neon Dark';

  @override
  String get switchToClassicTheme => 'Mudar para Tema Classic';

  @override
  String get switchToNeonTheme => 'Mudar para Tema Neon';

  @override
  String get switchToStudioLight => 'Mudar para Studio Light';

  @override
  String get menuTheme => 'Tema';

  @override
  String get appDescription =>
      'Um gerenciador de projetos para produtores musicais e designers de som.';

  @override
  String get neonDarkThemeName => 'Neon Escuro';

  @override
  String get classicDarkThemeName => 'Clássico Escuro';

  @override
  String get studioLightThemeName => 'Studio Claro';

  @override
  String get statisticsTab => 'Estatísticas';

  @override
  String get statsTotalProjects => 'Total de Projetos';

  @override
  String get statsInProgress => 'Em andamento';

  @override
  String get statsFinished => 'Concluídos';

  @override
  String get statsAvgCompletion => 'Conclusão média';

  @override
  String get statsPhaseDistribution => 'Projetos por Fase';

  @override
  String get statsAvgTimePerPhase => 'Dias médios por Fase';

  @override
  String get statsProductivity => 'Produtividade';

  @override
  String get statsCreatedSeries => 'Criados';

  @override
  String get statsProjectHealth => 'Idade e Saúde dos Projetos';

  @override
  String get statsCatalogInsights => 'Análise do Catálogo';

  @override
  String get statsBpmDistribution => 'Distribuição de BPM';

  @override
  String get statsTopKeys => 'Tonalidades mais usadas';

  @override
  String get statsDawTypes => 'Tipos de DAW';

  @override
  String get statsProjectActivity => 'Atividade dos Projetos';

  @override
  String get statsSingleProjectActivity => 'Atividade do Projeto';

  @override
  String get statsNoData => 'Sem dados ainda';

  @override
  String get statsNoPhaseData =>
      'Os dados de fases aparecerão após os projetos mudarem de fase.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Última atividade: há $days dias';
  }

  @override
  String get statsLastActivityToday => 'Ativo hoje';

  @override
  String get statsNoEvents => 'Nenhum evento registrado ainda';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Fase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Atualizado: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Concluído: $text';
  }

  @override
  String get statsEventFileModified => 'Arquivo modificado no disco';

  @override
  String get statsClearHistory => 'Limpar histórico';

  @override
  String get statsClearHistoryConfirm =>
      'Limpar todos os eventos registrados para este projeto?';

  @override
  String get statsSearchProjects => 'Pesquisar projetos…';

  @override
  String statsEventCount(int count) {
    return '$count eventos';
  }

  @override
  String get statsViewHistory => 'Estatísticas do Projeto';

  @override
  String get statsPhaseHistory => 'Histórico de Fases';

  @override
  String get statsEventBreakdown => 'Resumo de Eventos';

  @override
  String statsDaysSoFar(int days) {
    return '${days}d até agora';
  }

  @override
  String get statsNoProjectsFound => 'Nenhum projeto encontrado';

  @override
  String statsNotTouchedDays(int days) {
    return 'Sem alterações há $days dias';
  }

  @override
  String get sortByLastModified => 'Última modificação';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByPhase => 'Fase';

  @override
  String get sortByCreatedAt => 'Data de criação';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get sortNewestFirst => 'Mais recentes primeiro';

  @override
  String get sortOldestFirst => 'Mais antigos primeiro';

  @override
  String get sortTitleAZ => 'Título A–Z';

  @override
  String get sortTitleZA => 'Título Z–A';

  @override
  String get musicPlayerTab => 'Reprodutor de Música';

  @override
  String get previewAudioChangedRefreshing =>
      'O áudio de pré-visualização mudou no disco — atualizando a forma de onda…';

  @override
  String get audioFileChangedRefreshing =>
      'O arquivo de áudio mudou no disco — atualizando a forma de onda…';

  @override
  String get autoFitAllColumns => 'Redimensionar colunas';

  @override
  String get uploadAutoDetectedPreviewSongs =>
      'Enviar músicas de pré-visualização detectadas automaticamente';

  @override
  String get uploadAutoDetectedPreviewSongsSubtitle =>
      'Incluir músicas encontradas automaticamente pelo scanner, não apenas as definidas manualmente.';

  @override
  String get monoGenerating => 'Mono…';

  @override
  String errorHandlingDroppedFiles(String error) {
    return 'Erro ao processar os arquivos soltos: $error';
  }

  @override
  String get resetOnboardingConfirm =>
      'Isto irá reiniciar o assistente de configuração. Continuar?';

  @override
  String couldNotLaunchDaw(String daw, String error) {
    return 'Não foi possível iniciar $daw: $error';
  }

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link.';

  @override
  String get githubButtonLabel => 'GitHub';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Alternar reprodução mono';

  @override
  String get monoRequiresWav => 'A mixagem mono requer um arquivo WAV';

  @override
  String get monoUnsupportedFormat =>
      'Não foi possível criar a mistura mono — formato não suportado';

  @override
  String monoSwitchFailed(String error) {
    return 'Falha na troca para mono: $error';
  }

  @override
  String get analyzeLabel => 'Analisar';

  @override
  String get reAnalyzeLabel => 'Re-analisar';

  @override
  String get analysisRequiresWav => 'A análise requer um arquivo WAV';

  @override
  String get noResultsForFilter => 'Nenhum resultado para o filtro atual';

  @override
  String get noResultsForFilterHint =>
      'Tente ajustar a pesquisa ou os filtros.';

  @override
  String get noProjectsFound => 'Nenhum projeto encontrado';

  @override
  String get noProjectsFoundHint =>
      'Adicione uma pasta raiz nas configurações para começar.';

  @override
  String get noProjectsFoundInFoldersHint =>
      'Tente adicionar outra pasta que contenha projetos de DAW.';

  @override
  String get queueTab => 'Tarefas';

  @override
  String get queueSearchHint => 'Buscar tarefas...';

  @override
  String get queueNoPendingTasks => 'Tudo em dia!';

  @override
  String get queueNoPendingTasksHint =>
      'Sem tarefas pendentes nos seus projetos.';

  @override
  String get queueNoMatchingTasks => 'Nenhuma tarefa encontrada';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks tarefas pendentes em $projects projetos';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager $version';
  }

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get renameProjectFileTitle => 'Renomear arquivo de projeto';

  @override
  String get renameFileButtonLabel => 'Renomear arquivo';

  @override
  String get newFileNameLabel => 'Novo nome do arquivo (sem extensão)';

  @override
  String renameAlreadyExists(String name) {
    return 'Um arquivo chamado \"$name\" já existe.';
  }

  @override
  String renameSuccess(String name) {
    return 'Renomeado para \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Falha ao renomear: $error';
  }

  @override
  String get nameCannotBeEmpty => 'O nome não pode estar vazio';

  @override
  String get nameInvalidCharacters => 'O nome não pode conter / \\ :';

  @override
  String get alsoRenameContainingFolder =>
      'Também renomear a pasta que o contém';

  @override
  String get renameButton => 'Renomear';

  @override
  String get previewMixdownFolderTitle => 'Pastas de mixagem de visualização';

  @override
  String get previewMixdownFolderSubtitle =>
      'Nomes de subpastas dentro de cada pasta de projeto a verificar primeiro, em ordem, ao detectar automaticamente músicas de visualização. Deixe vazio para usar os padrões do DAW.';

  @override
  String get previewMixdownFolderHint => 'ex. Mixdowns';

  @override
  String get mixdownFoldersInfoTooltip => 'Como isso funciona';

  @override
  String get mixdownFoldersInfoDialogTitle =>
      'Como funciona a detecção de pré-visualização';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'Quando um projeto não tem uma música de pré-visualização escolhida manualmente, o app procura o arquivo de áudio modificado mais recentemente para usar como pré-visualização. Ele verifica primeiro suas pastas personalizadas abaixo, em ordem, e depois recorre a uma lista de nomes de pastas padrão com base no DAW do projeto.';

  @override
  String get mixdownFoldersDawDefaultsHeading => 'Pastas padrão por DAW';

  @override
  String get mixdownFoldersOtherDawLabel => 'Outro / DAW não reconhecido';

  @override
  String get addMixdownFolder => 'Adicionar';

  @override
  String get noCustomMixdownFolders =>
      'Nenhuma pasta personalizada adicionada — os padrões do DAW serão usados.';

  @override
  String get mixdownFoldersTabLabel => 'Pastas de Mixdown';

  @override
  String get mixdownFoldersSectionDescription =>
      'Controla em qual pasta o aplicativo procura o áudio exportado/bounced de um projeto, usado como música de prévia quando nenhuma é definida manualmente. Expanda um DAW abaixo para ver os nomes de pasta já verificados por padrão, e adicione os seus caso sua configuração use um nome diferente.';

  @override
  String get mixdownFoldersDefaultsLabel => 'Pastas verificadas por padrão:';

  @override
  String get mixdownFoldersCustomLabel => 'Suas adições para este DAW:';

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
    return 'Tom: $key';
  }

  @override
  String get audioFileNotFound => 'Arquivo de áudio não encontrado';

  @override
  String errorPlayingAudio(String error) {
    return 'Erro ao reproduzir áudio: $error';
  }

  @override
  String get notificationTestTitle =>
      'Testar notificações para verificar fuso horário e agendamento:';

  @override
  String get notificationSendNow => 'Enviar agora';

  @override
  String get notificationSchedule30s => 'Agendar +30s';

  @override
  String get notificationShowDebugInfo => 'Mostrar informações de depuração';

  @override
  String get notificationRescheduleAll => 'Reagendar tudo';

  @override
  String get notificationTestSent => '✅ Notificação de teste enviada!';

  @override
  String get notificationTestScheduled =>
      '✅ Notificação de teste agendada para 30 segundos! Verifique os logs.';

  @override
  String notificationTestError(String error) {
    return '❌ Erro: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Informações de depuração';

  @override
  String get autoDetected => 'Detectado automaticamente';

  @override
  String get matchedInDescription => 'Encontrado na descrição';

  @override
  String get matchedInProjectNotes => 'Encontrado nas notas do projeto do DAW';

  @override
  String get relocateFolderDialogTitle => 'Realocar pasta';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caminhos de projeto atualizados',
      one: '1 caminho de projeto atualizado',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Personalizar abas';

  @override
  String get alwaysVisible => '(sempre visível)';

  @override
  String get customizeTabsDescription =>
      'Escolha quais abas exibir na barra de navegacao. A aba Projetos e sempre visivel.';

  @override
  String get keyboardShortcuts => 'Atalhos de teclado';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Tabela de projetos (a tabela deve estar focada)';

  @override
  String get shortcutGroupReleasesTable =>
      'Tabela de lançamentos (a tabela deve estar focada)';

  @override
  String get shortcutGroupNavigation => 'Navegação';

  @override
  String get shortcutFocusSearch => 'Focar na barra de pesquisa';

  @override
  String get shortcutRescan => 'Reanalisar pastas de projetos';

  @override
  String get shortcutFocusTable => 'Focar na tabela de projetos';

  @override
  String get shortcutPlayPause =>
      'Reproduzir / pausar música de pré-visualização';

  @override
  String get shortcutOpenInDaw => 'Abrir projeto no DAW';

  @override
  String get shortcutViewDetails => 'Ver detalhes do projeto';

  @override
  String get shortcutOpenFolder => 'Abrir pasta do projeto';

  @override
  String get shortcutNavigateRows => 'Navegar nas linhas';

  @override
  String get shortcutEditCell => 'Abrir detalhes do projeto';

  @override
  String get shortcutViewRelease => 'Ver detalhes do lançamento';

  @override
  String get shortcutGoBack => 'Voltar';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Modo padrão';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Modo sessão';

  @override
  String get shortcutToggleSession => 'Iniciar / Encerrar sessão';

  @override
  String get shortcutGroupPreviewPlayer => 'Reprodutor de prévia';

  @override
  String get shortcutPlayerPlayPause => 'Reproduzir / pausar';

  @override
  String get shortcutPlayerSeek5 => 'Avançar/Retroceder ±5 segundos';

  @override
  String get shortcutPlayerSeek30 => 'Avançar/Retroceder ±30 segundos';

  @override
  String get startupDialogTitle => 'Bem-vindo ao DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Comece adicionando uma pasta de projetos ou restaurando um backup do Google Drive.';

  @override
  String get startupAddFolderTitle => 'Adicionar pasta de projetos';

  @override
  String get startupAddFolderSubtitle =>
      'Selecione uma pasta com seus projetos DAW.';

  @override
  String get startupGoogleDriveTitle => 'Sincronizar backup do Google Drive';

  @override
  String get startupGoogleDriveSubtitle =>
      'Restaure seus projetos a partir de um backup no Google Drive.';

  @override
  String get startupDontShowAgain => 'Não mostrar isso na inicialização';

  @override
  String get deleteAllData => 'Excluir todos os dados';

  @override
  String get deleteAllDataSubtitle =>
      'Remover todos os perfis, projetos, lançamentos, playlists e configurações deste dispositivo.';

  @override
  String get deleteAllDataConfirm1Title => 'Excluir todos os dados?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Isso apagará permanentemente todos os perfis, projetos, lançamentos, playlists e configurações deste dispositivo. Seu backup no Google Drive (se houver) não será afetado.';

  @override
  String get deleteAllDataConfirm2Title => 'Tem certeza absoluta?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Esta ação não pode ser desfeita. O aplicativo voltará ao estado inicial.';

  @override
  String get deleteEverything => 'Excluir tudo';

  @override
  String get allDataDeleted => 'Todos os dados foram excluídos.';

  @override
  String get newerExportFound => 'Exportação mais recente encontrada';

  @override
  String newerExportFoundMessage(String filename) {
    return 'Um arquivo mais recente foi encontrado na mesma pasta:\n$filename\n\nSubstituir a música de pré-visualização?';
  }

  @override
  String get replaceAndPlay => 'Substituir e reproduzir';

  @override
  String get keepCurrent => 'Manter atual';

  @override
  String get autoBackup => 'Backup Automático';

  @override
  String get autoBackupDescription =>
      'Envia automaticamente um backup para o Google Drive no intervalo selecionado.';

  @override
  String get autoBackupInterval => 'Intervalo de backup';

  @override
  String get autoBackupOff => 'Desativado';

  @override
  String get autoBackupEvery30Min => 'A cada 30 minutos';

  @override
  String get autoBackupHourly => 'A cada hora';

  @override
  String get autoBackupEvery6Hours => 'A cada 6 horas';

  @override
  String get autoBackupDaily => 'Diariamente';

  @override
  String autoBackupNextBackup(String time) {
    return 'Próximo backup: $time';
  }

  @override
  String get autoBackupNextSoon => 'em breve';

  @override
  String autoBackupNextInMinutes(int count) {
    return 'em $count min';
  }

  @override
  String get autoBackupNextInOneHour => 'em 1 hora';

  @override
  String autoBackupNextInHours(int count) {
    return 'em $count horas';
  }

  @override
  String get autoBackupNextInOneDay => 'em 1 dia';

  @override
  String autoBackupNextInDays(int count) {
    return 'em $count dias';
  }

  @override
  String get playerTitle => 'Reprodutor de Música';

  @override
  String get playerToggleQueue => 'Alternar fila';

  @override
  String get playerSearchHint => 'Pesquisar faixas…';

  @override
  String playerTrackCount(int count) {
    return '$count faixas';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'Nenhuma prévia encontrada.\nAbra um projeto e defina uma prévia.';

  @override
  String playerNoTracksMatch(String query) {
    return 'Nenhuma faixa corresponde a\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay =>
      'Clique duplo para começar a reproduzir';

  @override
  String get playerSingleClickToPreview =>
      'Clique simples para ouvir na barra abaixo';

  @override
  String get playerQueueTitle => 'Fila';

  @override
  String get playerClearQueue => 'Limpar fila';

  @override
  String get playerQueueEmptyHint =>
      'Clique duplo para começar,\nou arraste faixas para a fila.';

  @override
  String get playerPrev => 'Anterior';

  @override
  String get playerNext => 'Próximo';

  @override
  String get playerGoToProject => 'Ir ao projeto';

  @override
  String get playerAddToQueue => 'Adicionar à fila';

  @override
  String get playerRemoveFromQueue => 'Remover da fila';

  @override
  String get playerDismissDetail => 'Fechar detalhes';

  @override
  String get playerNotes => 'NOTAS';

  @override
  String get playerTasks => 'TAREFAS';

  @override
  String get playerNoTasks => 'Nenhuma tarefa ainda.';

  @override
  String get playerAddTaskHint => 'Adicionar uma tarefa…';

  @override
  String playerCompletedTasks(int count) {
    return '$count concluída(s)';
  }

  @override
  String get playerPreviousTrack => 'Faixa anterior';

  @override
  String get playerNextTrack => 'Próxima faixa';

  @override
  String get playerOpenProject => 'Abrir projeto';

  @override
  String get playerRepeatAll => 'Repetir tudo';

  @override
  String get playerShuffle => 'Aleatório';

  @override
  String get volumeMute => 'Silenciar';

  @override
  String get volumeUnmute => 'Reativar som';

  @override
  String totalWorkTime(String time) {
    return 'Trabalho total: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Sessão: $time';
  }

  @override
  String headerAgeOld(String age) {
    return '$age de vida';
  }

  @override
  String headerEdited(String when) {
    return 'editado $when';
  }

  @override
  String headerWorked(String time) {
    return '$time trabalhado';
  }

  @override
  String get sessionHistory => 'Histórico de sessões';

  @override
  String get noSessionsYet => 'Nenhuma sessão registrada ainda';

  @override
  String get removeSessionTitle => 'Remover sessão?';

  @override
  String get editSessionTitle => 'Editar duração da sessão';

  @override
  String get editSessionHours => 'Horas';

  @override
  String get editSessionInvalid => 'A duração deve ser de pelo menos 1 minuto';

  @override
  String get sessionTableDate => 'Data';

  @override
  String get sessionTableTime => 'Hora';

  @override
  String get sessionTableDuration => 'Duração';

  @override
  String get sessionTableTotal => 'Total';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessões',
      one: '1 sessão',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'Trabalho por fase';

  @override
  String get tabPosition => 'Posição das abas';

  @override
  String get tabPositionTop => 'Topo';

  @override
  String get tabPositionLeft => 'Esquerda';

  @override
  String updateAvailableMessage(String version) {
    return 'Versão $version disponível';
  }

  @override
  String get dismiss => 'Dispensar';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get checkForUpdatesDescription =>
      'Seja notificado quando uma nova versão estiver disponível.';

  @override
  String get checkNow => 'Verificar agora';

  @override
  String updateAvailable(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get upToDate => 'O app está atualizado';

  @override
  String get updateAvailableTitle => 'Atualização disponível';

  @override
  String updateAvailableVersion(String version) {
    return 'A versão $version está pronta.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Você está usando v$version.';
  }

  @override
  String get viewUpdateDetails => 'Ver detalhes';

  @override
  String get getOnMicrosoftStore => 'Obter na Microsoft Store';

  @override
  String get downloadFromGitHub => 'Baixar do GitHub';

  @override
  String get updateWindowsInstructions =>
      'Abra a Microsoft Store e atualize o DAW Project Manager, ou clique abaixo.';

  @override
  String get updateMacInstructions =>
      'Baixe a versão mais recente do GitHub e substitua o app atual.';

  @override
  String get updateAppImageSourceLabel => 'AppImage';

  @override
  String get updateAppImageInstructions => 'Atualiza no local e reinicia.';

  @override
  String get updateNowButtonLabel => 'Atualizar agora';

  @override
  String get appImageUpdateFetching => 'Procurando atualização…';

  @override
  String get appImageUpdateDownloading => 'Baixando atualização…';

  @override
  String appImageUpdateDownloadingProgress(int percent) {
    return 'Baixando atualização… $percent%';
  }

  @override
  String get appImageUpdateVerifying => 'Verificando e instalando…';

  @override
  String get appImageUpdateReadyTitle => 'Atualização pronta';

  @override
  String appImageUpdateReadyMessage(String version) {
    return 'Atualizado para a versão $version. Reinicie agora para concluir.';
  }

  @override
  String get appImageUpdateRestartNow => 'Reiniciar agora';

  @override
  String get appImageUpdateFailedTitle => 'Falha na atualização';

  @override
  String get appImageUpdateRetry => 'Tentar novamente';

  @override
  String get appImageUpdateErrorMessage =>
      'Ocorreu um erro durante a atualização. Você pode tentar novamente ou verificar os detalhes do erro abaixo.';

  @override
  String get appImageUpdateErrorDetailsLabel => 'Detalhes do Erro';

  @override
  String get appImageUpdateCopyErrorDetails => 'Copiar Detalhes do Erro';

  @override
  String get appImageUpdateErrorDetailsCopied => 'Detalhes do erro copiados';

  @override
  String get resetOnboarding => 'Redefinir integração inicial';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Organize todos os seus projetos musicais em um só lugar.';

  @override
  String get onboardingFeatureScanFolders =>
      'Escaneia automaticamente as pastas de projetos DAW';

  @override
  String get onboardingFeatureTrackMetadata =>
      'Acompanha BPM, tom, status e prazos';

  @override
  String get onboardingFeatureSyncDrive =>
      'Sincroniza metadados com o Google Drive';

  @override
  String get onboardingFeatureTrackTime =>
      'Acompanha o tempo gasto em cada projeto';

  @override
  String get onboardingLanguageTitle => 'Escolha o Idioma';

  @override
  String get onboardingThemeTitle => 'Escolha um Tema';

  @override
  String get onboardingFoldersTitle => 'Adicionar Pastas de Projetos';

  @override
  String get onboardingFoldersBody =>
      'Adicione a pasta raiz onde seus projetos de DAW estão armazenados.';

  @override
  String get onboardingDriveTitle => 'Sincronização Google Drive';

  @override
  String get onboardingDriveBody =>
      'Faça backup e sincronize os metadados do projeto com o Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Verificações de Atualizações';

  @override
  String get onboardingUpdatesBody =>
      'Seja notificado quando uma nova versão estiver disponível.';

  @override
  String get onboardingDoneTitle => 'Tudo Pronto!';

  @override
  String get onboardingDoneBody => 'Comece a explorar seus projetos.';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get dawSession => 'Sessão DAW';

  @override
  String get clearDawSession => 'Encerrar sessão';

  @override
  String get stop => 'Parar';

  @override
  String get pause => 'Pausar';

  @override
  String get playPauseTooltip => 'Reproduzir / Pausar';

  @override
  String get resume => 'Retomar';

  @override
  String get workTimerSection => 'Lembretes de sessão de trabalho';

  @override
  String get workTimerSectionDesc =>
      'Receba notificações periodicamente enquanto tiver uma sessão de trabalho ativa';

  @override
  String get workTimerRequiresSessionMode =>
      'Ative o Modo sessão acima para usar os lembretes de sessão de trabalho';

  @override
  String get workTimerEnabled => 'Ativar lembretes de sessão de trabalho';

  @override
  String get workTimerIntervalLabel => 'Notificar a cada';

  @override
  String get minutes => 'minutos';

  @override
  String workTimerNotifBody(String time) {
    return 'Você está trabalhando há $time';
  }

  @override
  String get sendTestNotification => 'Enviar notificação de teste';

  @override
  String get testNotificationTitle => 'Notificação de teste';

  @override
  String get testNotificationBody =>
      'Esta é uma notificação de teste do DAW Project Manager.';

  @override
  String get general => 'Geral';

  @override
  String get expand => 'Expandir';

  @override
  String get collapse => 'Recolher';

  @override
  String get lastModifiedColors => 'Cores da data de última modificação';

  @override
  String get lastModifiedColorsDescription =>
      'Colore a data de última modificação com base na idade e no estado. Verde = Concluído. Datas mais antigas desvanecem de amarelo para vermelho — vermelho mais intenso significa que o projeto não foi tocado há mais tempo.';

  @override
  String get sessionMode => 'Modo sessão';

  @override
  String get sessionModeDescription =>
      'Inicie uma sessão em um projeto para rastrear seu tempo de trabalho e gerenciá-lo pela barra de ferramentas';

  @override
  String get workSessionsTabLabel => 'Sessões de Trabalho';

  @override
  String get normalMode => 'Modo Normal';

  @override
  String get normalModeDescription =>
      'Os projetos abrem diretamente em seu DAW ao serem iniciados.';

  @override
  String get sessionModeCardDescription =>
      'Inicie uma sessão para rastrear sua atividade e tempo no projeto.';

  @override
  String get startSession => 'Iniciar sessão';

  @override
  String get endSession => 'Encerrar sessão';

  @override
  String get switchSession => 'Trocar sessão';

  @override
  String get switchSessionBody => 'Encerrar a sessão atual e iniciar uma nova?';

  @override
  String switchSessionCurrent(String project) {
    return 'Atual: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'Nova: $project';
  }

  @override
  String get sessionDuration => 'Tempo de sessão';

  @override
  String get scanModeLabel => 'Modo de varredura:';

  @override
  String get scanModeSectionTitle => 'Modo de varredura';

  @override
  String get scanModeSectionDescription =>
      'Controla como os projetos em cada pasta são exibidos na tabela — como uma lista simples ou agrupados por subpasta.';

  @override
  String get smartFolderOptionsSectionTitle => 'Opções de Pastas Inteligentes';

  @override
  String get smartFolderOptionsSectionDescription =>
      'Ajuste como os grupos de pastas inteligentes se comportam na tabela de projetos.';

  @override
  String get excludeSmartFoldersFromSort =>
      'Manter as pastas inteligentes fora da ordenação';

  @override
  String get excludeSmartFoldersFromSortDescription =>
      'Ao ordenar a tabela de projetos por uma coluna, os grupos de pastas inteligentes permanecem no lugar em vez de se mover com a ordenação — apenas os projetos dentro deles (e os projetos não agrupados) são reordenados. Experimental: desativado por padrão.';

  @override
  String get mergeSmartFoldersByName =>
      'Mesclar pastas inteligentes com o mesmo nome';

  @override
  String get mergeSmartFoldersByNameDescription =>
      'Quando duas pastas raiz de digitalização (por exemplo, DAWs diferentes) têm uma pasta de nível superior com o mesmo nome, elas são tratadas como um único grupo mesclado na tabela de projetos, em vez de dois grupos separados.';

  @override
  String get alwaysShowSmartFolders => 'Sempre mostrar pastas inteligentes';

  @override
  String get alwaysShowSmartFoldersDescription =>
      'Mostra uma pasta inteligente como sua própria linha de grupo mesmo quando apenas um de seus projetos está visível no momento (por exemplo, após uma busca ou filtro), em vez de reduzi-la a uma linha simples sem agrupamento.';

  @override
  String get scanModeFlat => 'Simples';

  @override
  String get scanModeSmartFolder => 'Pasta inteligente';

  @override
  String get scanModeFlatDescription =>
      'Mostra cada projeto como uma lista simples. Simples e rápido.';

  @override
  String get scanModeSmartFolderDescription =>
      'Agrupa projetos por pasta quando uma pasta contém mais de um projeto.';

  @override
  String get skip => 'Pular';

  @override
  String get suggestionsLabel => 'Sugestões';

  @override
  String get suggestionsRefresh => 'Atualizar';

  @override
  String get suggestionsEmptyState =>
      'Sem sugestões no momento. Toque em Atualizar para redefinir os itens descartados.';

  @override
  String get suggestionNewProject => 'Novo';

  @override
  String get showSuggestions => 'Mostrar sugestões';

  @override
  String get showSuggestionsDescription =>
      'Exibe sugestões inteligentes na barra de ferramentas quando nenhuma sessão está em execução';

  @override
  String get onboardingSuggestionsTitle => 'Sugestões inteligentes';

  @override
  String get onboardingSuggestionsBody =>
      'Receba recomendações de projetos personalizadas na barra de ferramentas enquanto trabalha';

  @override
  String get onboardingSessionModeTitle => 'Modo sessão';

  @override
  String get onboardingSessionModeBody =>
      'Inicie sessões de trabalho focadas e acompanhe automaticamente o tempo gasto em cada projeto';

  @override
  String get suggestionsFeatureDeadlines =>
      'Lembretes de prazo para projetos futuros';

  @override
  String get suggestionsFeatureResume =>
      'Retomar o último projeto em que você trabalhou';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Continuar as faixas modificadas recentemente';

  @override
  String get suggestionsEnableToggle => 'Ativar sugestões inteligentes';

  @override
  String get canBeChangedInSettings =>
      'Pode ser alterado mais tarde nas Configurações';

  @override
  String get next => 'Próximo';

  @override
  String get createProject => 'Criar';

  @override
  String get createProjectTooltip => 'Criar uma nova pasta de projeto';

  @override
  String get createProjectSelectFolder => 'Escolher local';

  @override
  String get createProjectSelectFolderHint =>
      'Selecione em qual pasta criar o novo projeto';

  @override
  String get createProjectNameTitle => 'Nomeie seu projeto';

  @override
  String get createProjectNameHint =>
      'Escolha um esquema de nomenclatura para a nova pasta';

  @override
  String get createProjectSchemeArtistTrack => 'Artista — Faixa';

  @override
  String get createProjectSchemeCollab => 'Colaboração';

  @override
  String get createProjectSchemeDate => 'Data — Faixa';

  @override
  String get createProjectSchemeCustom => 'Personalizado';

  @override
  String get createProjectSchemeRemix => 'Remix';

  @override
  String get createProjectArtistName => 'Nome do artista';

  @override
  String get createProjectTrackName => 'Nome da faixa';

  @override
  String get createProjectCustomName => 'Nome da pasta';

  @override
  String get createProjectAddArtist => 'Adicionar artista';

  @override
  String get createProjectOriginalArtist => 'Artista Original';

  @override
  String get createProjectRemixerName => 'Remixer';

  @override
  String get createProjectAddRemixer => 'Adicionar remixer';

  @override
  String get createProjectSelectDaw => 'Abrir no DAW';

  @override
  String get createProjectSelectDawHint =>
      'Escolha qual DAW abrir para trabalhar neste projeto';

  @override
  String get createProjectDetectDaws => 'Detectar DAWs instalados';

  @override
  String get createProjectSkipDaw => 'Apenas criar a pasta';

  @override
  String get createProjectNoDawsFound =>
      'Nenhum DAW encontrado. A pasta ainda será criada.';

  @override
  String get createProjectCreateOnly => 'Criar pasta';

  @override
  String get createProjectCreateAndOpen => 'Criar e abrir';

  @override
  String get createProjectFolderExists => 'Já existe uma pasta com este nome';

  @override
  String get createProjectInvalidChars => 'O nome contém caracteres inválidos';

  @override
  String get createProjectError => 'Falha ao criar pasta';

  @override
  String get createProjectIncludeDate => 'Incluir prefixo de data';

  @override
  String get createProjectCreatedTitle => 'Pasta criada';

  @override
  String get createProjectCreatedMessage =>
      'A pasta do seu projeto foi criada:';

  @override
  String get createProjectCopyName => 'Copiar nome da pasta';

  @override
  String get createProjectNameCopied => 'Nome da pasta copiado';

  @override
  String get createProjectTrackSession => 'Rastrear sessão a partir de agora';

  @override
  String get pendingFolderSessionTitle => 'Sessão de trabalho detectada';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'Você trabalhou em \"$projectName\" por $duration.';
  }

  @override
  String get pendingFolderSessionContinue => 'Continuar sessão';

  @override
  String get pendingFolderSessionEndRecord => 'Encerrar e registrar';

  @override
  String get activeSessionSwitchTitle => 'Sessão já ativa';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'Uma sessão está ativa para \"$current\". Mudar para \"$next\" e salvar a sessão atual?';
  }

  @override
  String get activeSessionSwitch => 'Mudar';

  @override
  String get pendingProjectWaiting => 'Aguardando arquivo de projeto…';

  @override
  String get pendingProjectDelete => 'Excluir pasta vazia';

  @override
  String get pendingProjectDeleteTitle => 'Excluir pasta?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return 'Excluir \"$folderName\" e seu conteúdo?';
  }

  @override
  String get pendingProjectDismiss => 'Parar de rastrear esta pasta';

  @override
  String get pendingProjectDismissTitle => 'Parar de rastrear?';

  @override
  String get pendingProjectDismissKeep => 'Manter pasta';

  @override
  String get pendingProjectDismissDelete => 'Excluir e fechar';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'A pasta não está vazia';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" contém arquivos. Excluir tudo permanentemente?';
  }

  @override
  String get pendingProjectRefresh => 'Verificar arquivo de projeto';

  @override
  String get pendingProjectNotFound =>
      'Nenhum arquivo de projeto encontrado ainda';

  @override
  String get phases => 'Fases';

  @override
  String get phasesSubtitle =>
      'Adicionar, remover e reordenar fases do projeto';

  @override
  String get phasesDescription =>
      'As fases acompanham o estágio de cada projeto no seu fluxo de trabalho (ex.: Ideia → Mixagem → Masterização). Arraste para reordenar, toque em um ponto colorido para recolorir, e marque uma fase como concluída para tratá-la como completa em todo o app.';

  @override
  String get resetToDefaults => 'Restaurar padrões';

  @override
  String get addPhase => 'Adicionar fase';

  @override
  String get phaseNameHint => 'Nome da fase';

  @override
  String get phaseDuplicateError => 'Já existe uma fase com esse nome';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projetos usam esta fase',
      one: '1 projeto usa esta fase',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Selecionar cor';

  @override
  String get markAsFinished => 'Marcar como fase concluída';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projetos usam fases que não existirão mais.',
      one: '1 projeto usa uma fase que não existirá mais.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Esses projetos manterão seu status atual, mas não aparecerão nos filtros de fase. Você sempre pode adicionar essas fases novamente depois.';

  @override
  String get resetPhasesConfirm =>
      'Restaurar todas as fases personalizadas, cores e marcações de fase concluída para os padrões?';

  @override
  String get camelotGenerateButton => 'Gerar mix';

  @override
  String get camelotDialogTitle => 'Mix Camelot';

  @override
  String get camelotDialogDescription =>
      'Ordena suas faixas por compatibilidade harmônica usando a roda Camelot. A proximidade de BPM é usada como critério de desempate.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count faixas elegíveis (tonalidade definida)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count serão ignoradas (sem tonalidade)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'Nenhuma faixa tem tonalidade definida. Abra um projeto e defina sua tonalidade.';

  @override
  String get camelotGenerate => 'Gerar';

  @override
  String camelotQueueGenerated(int count) {
    return 'Fila preenchida com $count faixas em ordem harmônica';
  }

  @override
  String get camelotWheelGuideTooltip => 'Guia da roda Camelot';

  @override
  String get camelotWheelGuideTitle => 'Guia da Roda Camelot';

  @override
  String get camelotGuideRingsTitle => 'Os Anéis';

  @override
  String get camelotGuideRingsBody =>
      'Anel interno (A)  →  tonalidades menores\nAnel externo (B)  →  tonalidades maiores';

  @override
  String get camelotGuideNumbersTitle => 'Números 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Posições dispostas no sentido horário. Cada número representa uma vizinhança harmônica — os vizinhos compartilham fortes relações tonais.';

  @override
  String get camelotGuideColoursTitle => 'Guia de Cores';

  @override
  String get camelotGuideColoursBody =>
      '● Brilhante  →  a tonalidade da sua música\n● Suavemente iluminado  →  compatível para mixagem\n● Apagado  →  evitar para uma mixagem suave';

  @override
  String get camelotGuideTransitionsTitle => 'Transições Compatíveis';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (mesmo número, trocar anel)\n  Maior/menor relativo — praticamente sem emenda.\n\n8A → 7A ou 9A  (±1, mesmo anel)\n  Tom adjacente — mudança suave e sutil.\n\n8A → 1A ou 3A  (±7, mesmo anel)\n  Impulso ou queda de energia — mudança mais dramática.';

  @override
  String get playerMixSuggestions => 'SUGESTÕES DE MIX';

  @override
  String get nowPlaying => 'Tocando agora';

  @override
  String get noPreviewSongsAvailable => 'Nenhuma música de prévia disponível';

  @override
  String get upNext => 'A seguir';

  @override
  String get playbackModeNormal => 'Normal';

  @override
  String get playbackModeRepeat => 'Repetir';

  @override
  String get playbackModeShuffle => 'Aleatório';

  @override
  String get hideDatesInNames => 'Ocultar datas nos nomes dos projetos';

  @override
  String get hideDatesInNamesDescription =>
      'Algumas DAWs colocam a data de criação no início do nome do arquivo do projeto (por exemplo \"2026-08-02 - Minha Faixa\"). Oculte-a para mostrar apenas o título. Os arquivos nunca são renomeados.';

  @override
  String get findPreviewAutomatically => 'Localizar automaticamente';

  @override
  String get noPreviewSongFoundAutomatically =>
      'Nenhuma música de prévia encontrada nas pastas de mixagem deste projeto.';

  @override
  String get selectProjects => 'Selecionar';

  @override
  String sharePreviewSongText(String name) {
    return 'Música de prévia: $name';
  }

  @override
  String sharePreviewSongZipText(String name) {
    return 'Música de prévia (ZIP): $name';
  }

  @override
  String get songParts => 'Instrumentos e Partes';

  @override
  String partsProgress(int done, int total) {
    return '$done de $total takes finais';
  }

  @override
  String get noPartsYet => 'Nenhuma parte registrada ainda';

  @override
  String get noPartsYetHint =>
      'Liste os instrumentos que a música precisa, quem toca cada um e em que ponto está cada take.';

  @override
  String get addPart => 'Adicionar parte';

  @override
  String get addPartHint => 'ex.: Bateria, Vocal principal, Baixo';

  @override
  String get partNameLabel => 'Parte';

  @override
  String get partNameRequired => 'O nome da parte é obrigatório';

  @override
  String get partPerformerLabel => 'Músico';

  @override
  String get partPerformerHint => 'Quem toca';

  @override
  String get partNotesLabel => 'Notas da parte';

  @override
  String get partStatusLabel => 'Status do take';

  @override
  String get partStatusNeeded => 'Necessária';

  @override
  String get partStatusRecording => 'Gravando';

  @override
  String get partStatusEarlyTake => 'Take inicial';

  @override
  String get partStatusFinalTake => 'Take final';

  @override
  String get editPart => 'Editar parte';

  @override
  String get deletePart => 'Excluir parte';

  @override
  String get partsUnassignedPerformer => 'Sem responsável';

  @override
  String get partTemplates => 'Templates de Partes';

  @override
  String get importPartsFromTemplate => 'Importar partes de um template';

  @override
  String get managePartTemplates => 'Gerenciar templates de partes';

  @override
  String get selectPartTemplate => 'Selecione um template de partes';

  @override
  String get noPartTemplatesAvailable => 'Nenhum template de partes disponível';

  @override
  String get noPartTemplatesYet => 'Nenhum template de partes ainda';

  @override
  String get createFirstPartTemplate =>
      'Crie um para reutilizar a mesma formação em várias músicas';

  @override
  String get createPartTemplate => 'Criar template de partes';

  @override
  String get editPartTemplate => 'Editar template de partes';

  @override
  String get deletePartTemplate => 'Excluir template de partes';

  @override
  String deletePartTemplateConfirm(String name) {
    return 'Tem certeza de que deseja excluir o template de partes \"$name\"?';
  }

  @override
  String get partTemplateCreated => 'Template de partes criado';

  @override
  String get partTemplateUpdated => 'Template de partes atualizado';

  @override
  String get partTemplateDeleted => 'Template de partes excluído';

  @override
  String get partTemplateItems => 'Partes (uma por linha)';

  @override
  String get partTemplateItemsHint =>
      'Bateria — Alex\nBaixo — Sam\nVocal principal';

  @override
  String get partTemplateItemsHelp =>
      'Uma parte por linha. Informe o músico após um travéssão: Bateria — Alex';

  @override
  String get partTemplateItemsRequired => 'Adicione pelo menos uma parte';

  @override
  String get partTemplateNameAndItemsRequired =>
      'É necessário um nome e pelo menos uma parte';

  @override
  String partTemplateItemCount(int count) {
    return '$count parte(s)';
  }

  @override
  String partTemplateImported(String name, int count) {
    return 'Template de partes \"$name\" importado ($count partes)';
  }

  @override
  String get errorLoadingPartTemplates =>
      'Erro ao carregar os templates de partes';

  @override
  String get exportPartsCsv => 'Exportar partes como CSV';

  @override
  String get exportAllPartsCsv =>
      'Exportar as partes de todas as músicas como CSV';

  @override
  String get exportAllPartsCsvSubtitle =>
      'Uma linha de planilha por parte, de todos os projetos — para compartilhar o progresso com colaboradores';

  @override
  String get noPartsToExport => 'Nenhuma parte para exportar';

  @override
  String partsCsvExported(int count) {
    return '$count partes exportadas';
  }

  @override
  String get projectExportPartsLabel => 'Partes:';

  @override
  String get csvHeaderProject => 'Projeto';

  @override
  String get csvHeaderPart => 'Parte';

  @override
  String get csvHeaderPerformer => 'Músico';

  @override
  String get csvHeaderStatus => 'Status';

  @override
  String get csvHeaderNotes => 'Notas';

  @override
  String get exportPartsXlsx => 'Exportar partes como Excel (.xlsx)';

  @override
  String get exportAllPartsXlsx =>
      'Exportar as partes de todas as músicas como Excel (.xlsx)';

  @override
  String get exportAllPartsXlsxSubtitle =>
      'A mesma planilha do CSV, com cabeçalho fixo, filtros nas colunas e status de take coloridos';

  @override
  String get importPartsFromSpreadsheet => 'Importar partes de uma planilha';

  @override
  String get partsImportPickerTitle => 'Selecione um arquivo CSV ou Excel';

  @override
  String partsImported(int added, int updated) {
    return '$added partes adicionadas, $updated atualizadas';
  }

  @override
  String get partsImportNothingFound =>
      'Nenhuma parte encontrada nesse arquivo';

  @override
  String partsImportFailed(String error) {
    return 'Não foi possível ler essa planilha: $error';
  }

  @override
  String get partsMoreActions => 'Mais ações de partes';

  @override
  String partsPageTitle(String name) {
    return '$name — Partes';
  }

  @override
  String get manageParts => 'Gerenciar partes';

  @override
  String partsMoreCount(int count) {
    return '+$count a mais';
  }

  @override
  String get searchParts => 'Buscar partes';

  @override
  String get allStatuses => 'Todos os status';

  @override
  String get allPerformers => 'Todos os músicos';

  @override
  String partsSelectedCount(int count) {
    return '$count selecionadas';
  }

  @override
  String get setPartStatus => 'Definir status';

  @override
  String get assignPartPerformer => 'Atribuir músico';

  @override
  String get deleteSelectedParts => 'Excluir selecionadas';

  @override
  String deleteSelectedPartsConfirm(int count) {
    return 'Excluir $count partes desta música?';
  }

  @override
  String partsDeleted(int count) {
    return '$count partes excluídas';
  }

  @override
  String get noPartsMatchFilters => 'Nenhuma parte corresponde a esses filtros';

  @override
  String get reorderNeedsUnfilteredList =>
      'Limpe a busca, os filtros e a ordenação para arrastar as partes';

  @override
  String get projectMarkers => 'Marcadores';

  @override
  String projectMarkerUnnamed(int index) {
    return 'Marcador $index';
  }

  @override
  String projectRegionUnnamed(int index) {
    return 'Região $index';
  }

  @override
  String get projectMarkerJumpTooltip =>
      'Ir para este ponto na música de prévia';

  @override
  String get projectMarkerNoPreviewSong =>
      'Adicione uma música de prévia para pular para os marcadores';

  @override
  String get projectDetailLayout => 'Layout dos Detalhes do Projeto';

  @override
  String get projectDetailLayoutSettingDescription =>
      'Como a página de detalhes do projeto é organizada.';

  @override
  String get projectDetailLayoutClassic => 'Clássico';

  @override
  String get projectDetailLayoutClassicDescription =>
      'Tudo em uma única rolagem.';

  @override
  String get projectDetailLayoutSectioned => 'Seções';

  @override
  String get projectDetailLayoutSectionedDescription =>
      'Uma barra à esquerda escolhe uma seção por vez.';
}
