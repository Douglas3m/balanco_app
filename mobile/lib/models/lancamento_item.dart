class LancamentoItem {
  final int? id;
  final String plaquetaCodigo;
  final int produtoId;
  final int setorId;
  final int entidadeId;
  final int quantidade;
  final String estadoConservacao;
  final String fotoPath;
  final String observacao;
  final String dataLancamento;
  final String? criadoEm;

  // Campos decorados via JOIN para visualizações rápidas e relatórios
  final String? produtoNome;
  final String? setorNome;
  final String? entidadeNome;

  LancamentoItem({
    this.id,
    required this.plaquetaCodigo,
    required this.produtoId,
    required this.setorId,
    required this.entidadeId,
    required this.quantidade,
    this.estadoConservacao = 'Ótimo',
    this.fotoPath = '',
    this.observacao = '',
    required this.dataLancamento,
    this.criadoEm,
    this.produtoNome,
    this.setorNome,
    this.entidadeNome,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'plaqueta_codigo': plaquetaCodigo.trim(),
    'produto_id': produtoId,
    'setor_id': setorId,
    'entidade_id': entidadeId,
    'quantidade': quantidade,
    'estado_conservacao': estadoConservacao,
    'foto_path': fotoPath,
    'observacao': observacao.trim(),
    'data_lancamento': dataLancamento,
    'criado_em': criadoEm ?? DateTime.now().toIso8601String(),
  };

  factory LancamentoItem.fromMap(Map<String, dynamic> map) => LancamentoItem(
    id: map['id'] as int?,
    plaquetaCodigo: map['plaqueta_codigo'] as String? ?? '',
    produtoId: map['produto_id'] as int,
    setorId: map['setor_id'] as int,
    entidadeId: map['entidade_id'] as int,
    quantidade: (map['quantidade'] as num?)?.toInt() ?? 1,
    estadoConservacao: map['estado_conservacao'] as String? ?? 'Ótimo',
    fotoPath: map['foto_path'] as String? ?? '',
    observacao: map['observacao'] as String? ?? '',
    dataLancamento: map['data_lancamento'] as String? ?? '',
    criadoEm: map['criado_em'] as String?,
    produtoNome: map['produto_nome'] as String?,
    setorNome: map['setor_nome'] as String?,
    entidadeNome: map['entidade_nome'] as String?,
  );

  LancamentoItem copyWith({
    int? id,
    String? plaquetaCodigo,
    int? produtoId,
    int? setorId,
    int? entidadeId,
    int? quantidade,
    String? estadoConservacao,
    String? fotoPath,
    String? observacao,
    String? dataLancamento,
    String? criadoEm,
    String? produtoNome,
    String? setorNome,
    String? entidadeNome,
  }) {
    return LancamentoItem(
      id: id ?? this.id,
      plaquetaCodigo: plaquetaCodigo ?? this.plaquetaCodigo,
      produtoId: produtoId ?? this.produtoId,
      setorId: setorId ?? this.setorId,
      entidadeId: entidadeId ?? this.entidadeId,
      quantidade: quantidade ?? this.quantidade,
      estadoConservacao: estadoConservacao ?? this.estadoConservacao,
      fotoPath: fotoPath ?? this.fotoPath,
      observacao: observacao ?? this.observacao,
      dataLancamento: dataLancamento ?? this.dataLancamento,
      criadoEm: criadoEm ?? this.criadoEm,
      produtoNome: produtoNome ?? this.produtoNome,
      setorNome: setorNome ?? this.setorNome,
      entidadeNome: entidadeNome ?? this.entidadeNome,
    );
  }
}
