import 'template_patterns.dart';

/// One line of a stage of `template-spec.md`.
class _Row {
  const _Row(this.name, this.type, this.parent, this.optional);
  final String name;
  final String type;
  final String? parent;
  final bool optional;
}

String _cell(String? text) => (text ?? '').replaceAll('|', r'\|');

/// Rows for [kind], parents before the folders and tracks inside them.
/// A parent that did not make the template leaves the cell empty.
List<_Row> _rows(TemplatePatterns patterns, TemplateKind kind) {
  final folderNames = <String, String>{
    for (final f in patterns.inTemplate(TemplateKind.folder))
      f.role: _copyName(f.name, 1, f.copies),
  };
  final rows = <_Row>[];
  for (final r in patterns.inTemplate(kind)) {
    final parentName =
        r.parentRole == null ? null : folderNames[r.parentRole];
    for (var i = 1; i <= r.copies; i++) {
      rows.add(_Row(
        _copyName(r.name, i, r.copies),
        r.typeMode.name,
        parentName,
        r.tier == RoleTier.common,
      ));
    }
  }
  if (kind != TemplateKind.folder) return rows;

  // A folder inside another is created after it.
  final placed = <_Row>[];
  var pending = rows;
  while (pending.isNotEmpty) {
    final names = {for (final p in placed) p.name};
    final ready = [
      for (final r in pending)
        if (r.parent == null || names.contains(r.parent)) r,
    ];
    if (ready.isEmpty) {
      // A loop of parents: break it rather than loop forever.
      placed.addAll([for (final r in pending) _Row(r.name, r.type, null, r.optional)]);
      break;
    }
    placed.addAll(ready);
    pending = [
      for (final r in pending)
        if (!ready.contains(r)) r,
    ];
  }
  return placed;
}

/// `template.md`: the same template as a tree a person can read and build by
/// hand. Folders hold what sits in them; every channel shows where it sends
/// its output and which plug-ins it carries, all in bypass.
String buildTemplateOutline(TemplatePatterns patterns) {
  final date = patterns.generated.toIso8601String().substring(0, 10);
  final routes = {for (final r in _routes(patterns)) r.$1: r.$2};
  final chains = <String, List<String>>{};
  for (final c in _chains(patterns)) {
    (chains[c.$1] ??= []).add(c.$3);
  }

  // Every item of the template, in build order, with the folder holding it.
  final items = <_Node>[];
  for (final kind in [
    TemplateKind.folder,
    TemplateKind.bus,
    TemplateKind.track,
  ]) {
    final rows = _rows(patterns, kind);
    for (final row in rows) {
      items.add(_Node(kind, row.name, row.type, row.parent, row.optional));
    }
  }

  final out = StringBuffer()
    ..writeln('# Template Cubase')
    ..writeln()
    ..writeln('Gerado em $date a partir de ${patterns.projectCount} projetos.')
    ..writeln()
    ..writeln('- Pastas contêm o que está recuado dentro delas')
    ..writeln('- `→ X`: a saída da trilha ou grupo vai para X; sem seta, '
        'fica na saída padrão')
    ..writeln('- `inserts`: plugins nos slots 0, 1, 2…, todos em bypass '
        '($kInsertState)')
    ..writeln('- _opcional_: item menos frequente, crie mutado ou apague')
    ..writeln()
    ..writeln('## Estrutura')
    ..writeln();

  String line(_Node n) {
    final parts = [
      '**${n.name}**',
      switch (n.kind) {
        TemplateKind.folder => 'pasta',
        TemplateKind.bus => 'grupo',
        TemplateKind.track => n.type,
      },
      if (routes[n.name] != null) '→ ${routes[n.name]}',
      if (n.optional) '_opcional_',
    ];
    return parts.join(' · ');
  }

  void write(_Node n, int depth) {
    final pad = '    ' * depth;
    out.writeln('$pad- ${line(n)}');
    final chain = chains[n.name];
    if (chain != null && n.kind != TemplateKind.folder) {
      out.writeln('$pad    - inserts: ${chain.join(' → ')}');
    }
    if (n.kind == TemplateKind.folder) {
      for (final child in items) {
        if (!identical(child, n) && child.parent == n.name) {
          write(child, depth + 1);
        }
      }
    }
  }

  final names = {for (final n in items) n.name};
  final top = [
    for (final n in items)
      if (n.parent == null || !names.contains(n.parent)) n,
  ];
  for (final n in top) {
    write(n, 0);
  }
  return out.toString();
}

class _Node {
  const _Node(this.kind, this.name, this.type, this.parent, this.optional);
  final TemplateKind kind;
  final String name;
  final String type;
  final String? parent;
  final bool optional;
}

/// (track or bus, destination bus) for every template channel whose usual
/// output is a bus of the template. Anything else keeps the default output.
List<(String, String)> _routes(TemplatePatterns patterns) {
  final busNames = <String, String>{
    for (final b in patterns.inTemplate(TemplateKind.bus))
      b.role: _copyName(b.name, 1, b.copies),
  };
  final routes = <(String, String)>[];
  for (final kind in [TemplateKind.bus, TemplateKind.track]) {
    for (final r in patterns.inTemplate(kind)) {
      final target = r.outputRole == null ? null : busNames[r.outputRole];
      if (target == null) continue;
      for (var i = 1; i <= r.copies; i++) {
        final name = _copyName(r.name, i, r.copies);
        if (name != target) routes.add((name, target));
      }
    }
  }
  return routes;
}

/// (channel, slot, plug-in) rows, slots filled in order from 0.
List<(String, int, String)> _chains(TemplatePatterns patterns) {
  final rows = <(String, int, String)>[];
  for (final kind in [TemplateKind.bus, TemplateKind.track]) {
    for (final r in patterns.inTemplate(kind)) {
      for (var i = 1; i <= r.copies; i++) {
        final name = _copyName(r.name, i, r.copies);
        for (var slot = 0; slot < r.inserts.length; slot++) {
          rows.add((name, slot, r.inserts[slot].plugin));
        }
      }
    }
  }
  return rows;
}

String _copyName(String name, int copy, int copies) =>
    copies > 1 ? '$name $copy' : name;

String _table(List<String> header, List<List<String>> rows) {
  final out = StringBuffer('| ${header.join(' | ')} |\n')
    ..writeln('| ${header.map((_) => '---').join(' | ')} |');
  for (final row in rows) {
    out.writeln('| ${row.join(' | ')} |');
  }
  return out.toString();
}

/// `template-spec.md`: the file Claude executes, step by step, in Cubase.
///
/// Every row is an action in Cubase's interface; an empty cell means "do
/// nothing". Whatever the parser could not read is under "Ajuste manual",
/// never guessed.
String buildTemplateSpec(TemplatePatterns patterns) {
  final folders = _rows(patterns, TemplateKind.folder);
  final buses = _rows(patterns, TemplateKind.bus);
  final tracks = _rows(patterns, TemplateKind.track);
  final date = patterns.generated.toIso8601String().substring(0, 10);

  final out = StringBuffer()
    ..writeln('# Template Cubase')
    ..writeln()
    ..writeln('## Contexto')
    ..writeln('- Gerado em $date a partir de '
        '${patterns.projectCount} projetos')
    ..writeln('- Cubase alvo: ${patterns.cubaseVersion ?? 'não registrado'}')
    ..writeln('- Tempo, compasso e sample rate: não lidos dos projetos; '
        'manter o padrão do Cubase');
  if (patterns.projectCount < kSmallCorpus) {
    out.writeln('- Atenção: só ${patterns.projectCount} projetos analisados; '
        'as estatísticas são fracas');
  }
  out
    ..writeln()
    ..writeln('## Ordem de execução')
    ..writeln('1. Criar projeto vazio com as configurações do Contexto')
    ..writeln('2. Etapa A (pastas)')
    ..writeln('3. Etapa B (grupos e buses)')
    ..writeln('4. Etapa C (trilhas)')
    ..writeln('5. Etapa D (roteamento de saída)')
    ..writeln('6. Etapa E (inserts)')
    ..writeln('7. Ativar o bypass geral do painel de inserts de cada trilha '
        'e grupo da Etapa E')
    ..writeln('8. Verificação')
    ..writeln('9. Parar e avisar: quem salva como template é o usuário')
    ..writeln()
    ..writeln('Itens marcados com "opcional" são criados normalmente, mas '
        'muteados, para o usuário apagar o que não quiser. Célula vazia '
        'significa não fazer nada.')
    ..writeln()
    ..writeln('insert_state: $kInsertState. Todo insert da Etapa E é só um '
        'lembrete do que costuma ser usado: carregue o plugin e deixe em '
        'bypass. Plugin que não estiver instalado: pule e anote em '
        'Pendências.')
    ..writeln()
    ..writeln('## Etapa A: pastas');
  out.write(_table(['#', 'Nome', 'Pai', 'Opcional'], [
    for (var i = 0; i < folders.length; i++)
      [
        '${i + 1}',
        _cell(folders[i].name),
        _cell(folders[i].parent),
        folders[i].optional ? 'opcional' : '',
      ],
  ]));
  out
    ..writeln()
    ..writeln('## Etapa B: grupos e buses');
  out.write(_table(['#', 'Nome', 'Tipo', 'Opcional'], [
    for (var i = 0; i < buses.length; i++)
      [
        '${i + 1}',
        _cell(buses[i].name),
        'grupo',
        buses[i].optional ? 'opcional' : '',
      ],
  ]));
  out
    ..writeln()
    ..writeln('## Etapa C: trilhas');
  out.write(_table(['#', 'Nome', 'Tipo', 'Pasta', 'Opcional'], [
    for (var i = 0; i < tracks.length; i++)
      [
        '${i + 1}',
        _cell(tracks[i].name),
        _cell(tracks[i].type),
        _cell(tracks[i].parent),
        tracks[i].optional ? 'opcional' : '',
      ],
  ]));
  final routes = _routes(patterns);
  out
    ..writeln()
    ..writeln('## Etapa D: roteamento de saída');
  out.write(_table(['Trilha', 'Saída'], [
    for (final r in routes) [_cell(r.$1), _cell(r.$2)],
  ]));
  final chains = _chains(patterns);
  out
    ..writeln()
    ..writeln('## Etapa E: inserts');
  out.write(_table(['Trilha ou bus', 'Slot', 'Plugin', 'insert_state'], [
    for (final c in chains)
      [_cell(c.$1), '${c.$2}', _cell(c.$3), kInsertState],
  ]));
  out
    ..writeln()
    ..writeln('## Verificação')
    ..writeln('- [ ] Total de pastas: ${folders.length}')
    ..writeln('- [ ] Total de grupos e buses: ${buses.length}')
    ..writeln('- [ ] Total de trilhas: ${tracks.length}')
    ..writeln('- [ ] Total de inserts: ${chains.length}')
    ..writeln('- [ ] Todos os inserts em bypass')
    ..writeln('- [ ] Plugins pulados: ')
    ..writeln()
    ..writeln('## Ajuste manual')
    ..writeln('- Sends, cores e presets não foram lidos dos projetos: o '
        'usuário configura depois')
    ..writeln('- Trilhas sem rota na Etapa D ficam na saída padrão')
    ..writeln('- Tipo de bus: grupo e FX não são distinguidos; todos '
        'aparecem como grupo');
  final plugins = patterns.plugins.take(10).toList();
  if (plugins.isNotEmpty) {
    out.writeln('- Plugins mais usados nos projetos (sugestão, não instalar '
        'nem inserir): ${plugins.map((p) => '${p.plugin} '
            '(${(p.presence * 100).round()}%)').join(', ')}');
  }
  out
    ..writeln()
    ..writeln('## Pendências')
    ..writeln('- ');
  return out.toString();
}
