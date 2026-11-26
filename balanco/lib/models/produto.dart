class Produto {
  final int? id;
  final String nome;
  final String categoria;
  final String? criadoEm;

  Produto({
    this.id,
    required this.nome,
    this.categoria = 'Geral',
    this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome': nome.trim(),
    'categoria': categoria.trim(),
    'criado_em': criadoEm ?? DateTime.now().toIso8601String(),
  };

  factory Produto.fromMap(Map<String, dynamic> map) => Produto(
    id: map['id'] as int?,
    nome: map['nome'] as String? ?? '',
    categoria: map['categoria'] as String? ?? 'Geral',
    criadoEm: map['criado_em'] as String?,
  );

  Produto copyWith({
    int? id,
    String? nome,
    String? categoria,
    String? criadoEm,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
