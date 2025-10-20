class Usuario {
  final int idUsuario;
  final String nome;
  final String email;
  final String senhaLogin;
  final String perfil;
  final DateTime dataCriacao;
  final DateTime ultimoLogin;
  final int empresaId;

  Usuario({
    required this.idUsuario,
    required this.nome,
    required this.email,
    required this.senhaLogin,
    required this.perfil,
    required this.dataCriacao,
    required this.ultimoLogin,
    required this.empresaId,
  });

  int get getIdUsuario => idUsuario;
  String get getNome => nome;
  String get getEmail => email;
  String get getSenhaLogin => senhaLogin;
  String get getPerfil => perfil;
  DateTime get getDataCriacao => dataCriacao;
  DateTime get getUltimoLogin => ultimoLogin;
  int get getEmpresaId => empresaId;

  void exibirDados() {
    print('👤 DADOS DO USUÁRIO');
    print('─' * 30);
    print('ID: $idUsuario');
    print('Nome: $nome');
    print('Email: $email');
    print('Perfil: $perfil');
    print('Data de Criação: ${_formatarData(dataCriacao)}');
    print('Último Login: ${_formatarData(ultimoLogin)}');
    print('Empresa ID: $empresaId');
    print('─' * 30);
  }

  String _formatarData(DateTime data) {
    return '${data.day}/${data.month}/${data.year} ${data.hour}:${data.minute}';
  }

  void atualizarUltimoLogin() {
    print('🕒 Último login atualizado para: ${_formatarData(DateTime.now())}');
  }

  bool isAdministrador() {
    return perfil.toLowerCase() == 'administrador';
  }

  bool isOperador() {
    return perfil.toLowerCase() == 'operador';
  }

  bool emailValido() {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void alterarSenha(String novaSenha) {
    if (novaSenha.length >= 6) {
      print('🔒 Senha alterada com sucesso!');
    } else {
      print('❌ Senha deve ter pelo menos 6 caracteres!');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'nome': nome,
      'email': email,
      'senhaLogin': senhaLogin,
      'perfil': perfil,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ultimoLogin': ultimoLogin.toIso8601String(),
      'empresa_idEmpresa': empresaId,
    };
  }

  @override
  String toString() {
    return 'Usuario{id: $idUsuario, nome: $nome, email: $email, perfil: $perfil}';
  }
}
