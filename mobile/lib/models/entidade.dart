class Entidade {
  final int? id;
  final String nome;
  final String cnpjCodigo;
  final String regime;
  final String observacao;
  final String? criadoEm;

  Entidade({
    this.id,
    required this.nome,
    this.cnpjCodigo = '',
    this.regime = 'Administração Direta',
    this.observacao = '',
    this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome': nome.trim(),
    'cnpj_codigo': cnpjCodigo.trim(),
    'regime': regime.trim(),
    'observacao': observacao.trim(),
    'criado_em': criadoEm ?? DateTime.now().toIso8601String(),
  };

  factory Entidade.fromMap(Map<String, dynamic> map) => Entidade(
    id: map['id'] as int?,
    nome: map['nome'] as String? ?? '',
    cnpjCodigo: map['cnpj_codigo'] as String? ?? '',
    regime: map['regime'] as String? ?? 'Administração Direta',
    observacao: map['observacao'] as String? ?? '',
    criadoEm: map['criado_em'] as String?,
  );

  Entidade copyWith({
    int? id,
    String? nome,
    String? cnpjCodigo,
    String? regime,
    String? observacao,
    String? criadoEm,
  }) {
    return Entidade(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cnpjCodigo: cnpjCodigo ?? this.cnpjCodigo,
      regime: regime ?? this.regime,
      observacao: observacao ?? this.observacao,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
