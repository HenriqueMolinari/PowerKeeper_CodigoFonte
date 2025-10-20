import 'package:mysql1/mysql1.dart';
import 'DatabaseConfig.dart';

class DatabaseConnection {
  final DatabaseConfig config;
  MySqlConnection? _connection;

  DatabaseConnection(this.config);

  Future<bool> connect() async {
    try {
      _connection = await MySqlConnection.connect(ConnectionSettings(
        host: config.host,
        port: config.porta,
        user: config.usuario,
        password: config.senha,
        db: config.dbName,
      ));

      try {
        await _connection!.query('SELECT 1');
        print('✅ Conexão estabelecida com Sucesso!');
        return true;
      } catch (queryError) {
        print('❌ Erro ao executar query de teste: $queryError');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao conectar: $e');
      return false;
    }
  }

  Future<void> close() async {
    await _connection?.close();
    print('🔌 Conexão encerrada!');
  }

  MySqlConnection? get connection => _connection;
}
