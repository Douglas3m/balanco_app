class Setor {
  final int? id;
  final int entidadeId;
  final String nome;
  final String andarBloco;
  final String responsavel;
  final String? criadoEm;
  final String? entidadeNome;

  Setor({
    this.id,
    required this.entidadeId,
    required this.nome,
    this.andarBloco = '',
    this.responsavel = '',
    this.criadoEm,
    this.entidadeNome,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'entidade_id': entidadeId,
    'nome': nome.trim(),
    'andar_bloco': andarBloco.trim(),
    'responsavel': responsavel.trim(),
    'criado_em': criadoEm ?? DateTime.now().toIso8601String(),
  };

  factory Setor.fromMap(Map<String, dynamic> map) => Setor(
    id: map['id'] as int?,
    entidadeId: map['entidade_id'] as int,
    nome: map['nome'] as String? ?? '',
    andarBloco: map['andar_bloco'] as String? ?? '',
    responsavel: map['responsavel'] as String? ?? '',
    criadoEm: map['criado_em'] as String?,
    entidadeNome: map['entidade_nome'] as String?,
  );

  Setor copyWith({
    int? id,
    int? entidadeId,
    String? nome,
    String? andarBloco,
    String? responsavel,
    String? criadoEm,
    String? entidadeNome,
  }) {
    return Setor(
      id: id ?? this.id,
      entidadeId: entidadeId ?? this.entidadeId,
      nome: nome ?? this.nome,
      andarBloco: andarBloco ?? this.andarBloco,
      responsavel: responsavel ?? this.responsavel,
      criadoEm: criadoEm ?? this.criadoEm,
      entidadeNome: entidadeNome ?? this.entidadeNome,
    );
  }
}
