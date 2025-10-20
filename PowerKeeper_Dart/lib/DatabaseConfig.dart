class DatabaseConfig {
  final String host;
  final int porta;
  final String usuario;
  final String senha;
  final String dbName;

  DatabaseConfig({
    required this.host,
    required this.porta,
    required this.usuario,
    required this.senha,
    required this.dbName,
  });

  void exibirConfig() {
    print('''
🔧 CONFIGURAÇÃO DO BANCO DE DADOS:
   📍 Host: $host
   🚪 Porta: $porta
   👤 Usuário: $usuario
   🔑 Senha: ${'*' * senha.length}
   🗃️  Database: $dbName
''');
  }
}
