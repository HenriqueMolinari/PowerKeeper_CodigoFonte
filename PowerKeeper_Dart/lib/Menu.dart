import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Empresa.dart';
import 'Local.dart';
import 'Dispositivo.dart';
import 'SensorSCT013.dart';
import 'Leitura.dart';
import 'Usuario.dart';
import 'DatabaseConnection.dart';

class Menu {
  final DatabaseConnection dbConnection;
  bool _conectado = false;

  // 🔥 CONFIGURAÇÕES FIREBASE - POWERKEEPER
  static const String _baseUrl =
      'powerkeeper-c708c-default-rtdb.firebaseio.com';

  // Listas locais
  final List<Empresa> _empresas = [];
  final List<Local> _locais = [];
  final List<Dispositivo> _dispositivos = [];
  final List<SensorSCT013> _sensores = [];
  final List<Leitura> _leituras = [];
  final List<Usuario> _usuarios = [];

  Menu(this.dbConnection);

  Future<void> inicializar() async {
    print('\n🔄 INICIALIZANDO SISTEMA POWERKEEPER...');
    _conectado = await dbConnection.connect();

    if (_conectado) {
      print('🎉 CONEXÃO COM BANCO ESTABELECIDA COM SUCESSO!');
      await _carregarDadosDoBanco();
    } else {
      print('❌ FALHA NA CONEXÃO COM BANCO');
      print('⚠️  Os dados serão salvos apenas localmente');
    }

    print('\n🔥 CONECTANDO AO FIREBASE...');
    await _carregarLeiturasFirebase();
  }

  Future<void> _carregarLeiturasFirebase() async {
    try {
      print('📡 Buscando leituras no Firebase...');
      _leituras.clear();

      // 🔄 PRIMEIRO: Buscar dados atuais
      await _carregarDadosAtuais();

      // 🔄 SEGUNDO: Buscar histórico de leituras
      await _carregarHistoricoLeituras();

      print('✅ Total de leituras carregadas: ${_leituras.length}');
    } catch (e) {
      print('❌ Erro de conexão com Firebase: $e');
    }
  }

  Future<void> _carregarDadosAtuais() async {
    try {
      final url = Uri.https(_baseUrl, '/monitor/dados_atuais.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dados = json.decode(response.body);

        if (dados != null) {
          final leitura = Leitura.fromFirebase(dados, 'atual');
          _leituras.add(leitura);
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar dados atuais: $e');
    }
  }

  Future<void> _carregarHistoricoLeituras() async {
    try {
      final List<String> caminhosPossiveis = [
        '/leituras.json',
        '/monitor/leituras.json',
      ];

      int leiturasCarregadas = 0;

      for (final caminho in caminhosPossiveis) {
        try {
          final url = Uri.https(_baseUrl, caminho);
          final response = await http.get(url);

          if (response.statusCode == 200) {
            final historicoData = json.decode(response.body);

            if (historicoData != null && historicoData is Map) {
              historicoData.forEach((key, value) {
                if (value is Map) {
                  final Map<String, dynamic> valueAsStringMap = {};
                  value.forEach((k, v) {
                    valueAsStringMap[k.toString()] = v;
                  });

                  final leitura =
                      Leitura.fromFirebase(valueAsStringMap, key.toString());
                  _leituras.add(leitura);
                  leiturasCarregadas++;
                }
              });

              if (leiturasCarregadas > 0) {
                print('✅ $leiturasCarregadas leituras históricas carregadas');
                _leituras.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                return;
              }
            }
          }
        } catch (e) {
          // Continua para o próximo caminho
        }
      }

      if (leiturasCarregadas == 0) {
        print('ℹ️  Nenhuma leitura histórica encontrada');
      }
    } catch (e) {
      print('❌ Erro ao carregar histórico de leituras: $e');
    }
  }

  Future<void> _carregarDadosDoBanco() async {
    if (!_conectado) return;

    try {
      print('\n📥 CARREGANDO DADOS DO BANCO...');

      _empresas.clear();
      _locais.clear();
      _dispositivos.clear();
      _sensores.clear();
      _usuarios.clear();

      await _carregarDadosRobusto();

      print('\n✅ RESUMO DO CARREGAMENTO:');
      print('🏢 Empresas: ${_empresas.length}');
      print('🏠 Locais: ${_locais.length}');
      print('⚙️  Dispositivos: ${_dispositivos.length}');
      print('📡 Sensores: ${_sensores.length}');
      print('👤 Usuários: ${_usuarios.length}');
    } catch (e) {
      print('❌ Erro ao carregar dados do banco: $e');
    }
  }

  Future<void> _carregarDadosRobusto() async {
    try {
      // 🏢 CARREGAR EMPRESAS
      try {
        var resultados =
            await dbConnection.connection!.query('SELECT * FROM empresa');
        for (var row in resultados) {
          var dados = row.toList();
          if (dados.length >= 3 && _safeString(dados[1]).isNotEmpty) {
            _empresas.add(Empresa(_safeInt(dados[0]), _safeString(dados[1]),
                _safeString(dados[2])));
          }
        }
      } catch (e) {
        print('❌ Erro ao carregar empresas: $e');
      }

      // 🏠 CARREGAR LOCAIS
      try {
        var resultados =
            await dbConnection.connection!.query('SELECT * FROM local');
        for (var row in resultados) {
          var dados = row.toList();
          if (dados.length >= 4) {
            _locais.add(Local(_safeInt(dados[0]), _safeString(dados[1]),
                _safeString(dados[2]), _safeInt(dados[3])));
          }
        }
      } catch (e) {
        print('❌ Erro ao carregar locais: $e');
      }

      // ⚙️ CARREGAR DISPOSITIVOS
      try {
        var resultados =
            await dbConnection.connection!.query('SELECT * FROM dispositivo');
        for (var row in resultados) {
          var dados = row.toList();
          if (dados.length >= 3) {
            int localId = dados.length >= 4 ? _safeInt(dados[3]) : 0;
            int sensorId = dados.length >= 5 ? _safeInt(dados[4]) : 0;
            _dispositivos.add(Dispositivo(_safeInt(dados[0]),
                _safeString(dados[1]), _safeString(dados[2]),
                localId: localId, sensorId: sensorId));
          }
        }
      } catch (e) {
        print('❌ Erro ao carregar dispositivos: $e');
      }

      // 📡 CARREGAR SENSORES
      try {
        var resultados =
            await dbConnection.connection!.query('SELECT * FROM sensor');
        for (var row in resultados) {
          var dados = row.toList();
          if (dados.length >= 3) {
            _sensores.add(SensorSCT013(_safeInt(dados[0]),
                _safeString(dados[1]), _safeString(dados[2]), 30.0, 2.5));
          }
        }
      } catch (e) {
        print('❌ Erro ao carregar sensores: $e');
      }

      // 👤 CARREGAR USUÁRIOS
      try {
        var resultados =
            await dbConnection.connection!.query('SELECT * FROM usuario');
        for (var row in resultados) {
          var dados = row.toList();
          if (dados.length >= 3) {
            _usuarios.add(Usuario(
              idUsuario: _safeInt(dados[0]),
              nome: _safeString(dados[1]),
              email: dados.length > 2
                  ? _safeString(dados[2])
                  : 'email@exemplo.com',
              senhaLogin: dados.length > 3 ? _safeString(dados[3]) : 'senha',
              perfil: dados.length > 4 ? _safeString(dados[4]) : 'Usuario',
              dataCriacao: DateTime.now(),
              ultimoLogin: DateTime.now(),
              empresaId: dados.length > 7 ? _safeInt(dados[7]) : 1,
            ));
          }
        }
      } catch (e) {
        print('❌ Erro ao carregar usuários: $e');
      }
    } catch (e) {
      print('❌ Erro geral no carregamento: $e');
    }
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  // ========== MÉTODOS DE CADASTRO ==========
  Future<void> _cadastrarEmpresa() async {
    print('\n🏢 CADASTRAR EMPRESA');

    stdout.write('Nome: ');
    final nome = stdin.readLineSync()?.trim() ?? '';

    stdout.write('CNPJ: ');
    final cnpj = stdin.readLineSync()?.trim() ?? '';

    if (nome.isEmpty || cnpj.isEmpty) {
      print('❌ Nome e CNPJ são obrigatórios!');
      return;
    }

    final empresaExistente = _empresas.firstWhere(
      (empresa) => empresa.cnpj == cnpj,
      orElse: () => Empresa(0, '', ''),
    );

    if (empresaExistente.cnpj.isNotEmpty) {
      print('❌ Já existe uma empresa com este CNPJ!');
      return;
    }

    int novoId = _empresas.isEmpty
        ? 1
        : (_empresas.map((e) => e.idEmpresa).reduce((a, b) => a > b ? a : b) +
            1);
    final empresa = Empresa(novoId, nome, cnpj);
    _empresas.add(empresa);

    if (_conectado) {
      try {
        await dbConnection.connection!.query(
          'INSERT INTO empresa (nome, cnpj) VALUES (?, ?)',
          [empresa.nome, empresa.cnpj],
        );
        print('💾 Empresa salva no banco de dados!');
      } catch (e) {
        print('❌ Erro ao salvar empresa no banco: $e');
      }
    }

    print('✅ Empresa cadastrada com sucesso!');
    empresa.exibirDados();
  }

  Future<void> _cadastrarLocal() async {
    print('\n🏠 CADASTRAR LOCAL');

    if (_empresas.isEmpty) {
      print('❌ É necessário cadastrar uma empresa primeiro!');
      return;
    }

    print('\n📋 Empresas disponíveis:');
    for (int i = 0; i < _empresas.length; i++) {
      print('${i + 1} - ${_empresas[i].nome} (CNPJ: ${_empresas[i].cnpj})');
    }

    int? empresaIndex;
    do {
      stdout.write('Selecione a empresa (1-${_empresas.length}): ');
      final input = stdin.readLineSync()?.trim();
      empresaIndex = int.tryParse(input ?? '');

      if (empresaIndex == null ||
          empresaIndex < 1 ||
          empresaIndex > _empresas.length) {
        print('❌ Selecione uma empresa válida!');
      }
    } while (empresaIndex == null);

    final empresaSelecionada = _empresas[empresaIndex - 1];

    stdout.write('Nome do local: ');
    final nome = stdin.readLineSync()?.trim() ?? '';

    stdout.write('Referência: ');
    final referencia = stdin.readLineSync()?.trim() ?? '';

    if (nome.isEmpty || referencia.isEmpty) {
      print('❌ Nome e referência são obrigatórios!');
      return;
    }

    int novoId = _locais.isEmpty
        ? 1
        : (_locais.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final local = Local(novoId, nome, referencia, empresaSelecionada.idEmpresa);
    _locais.add(local);

    if (_conectado) {
      try {
        await dbConnection.connection!.query(
          'INSERT INTO local (nome, referencia, empresa_idEmpresa) VALUES (?, ?, ?)',
          [local.nome, local.referencia, local.empresaId],
        );
        print('💾 Local salvo no banco de dados!');
      } catch (e) {
        print('❌ Erro ao salvar local no banco: $e');
      }
    }

    print('✅ Local cadastrado com sucesso!');
    local.exibirDados();
  }

  Future<void> _cadastrarDispositivo() async {
    print('\n⚙️  CADASTRAR DISPOSITIVO');

    stdout.write('Modelo: ');
    final modelo = stdin.readLineSync()?.trim() ?? '';

    stdout.write('Status (Ativo/Inativo): ');
    final status = stdin.readLineSync()?.trim() ?? '';

    if (modelo.isEmpty || status.isEmpty) {
      print('❌ Modelo e status são obrigatórios!');
      return;
    }

    int? localId;
    if (_locais.isNotEmpty) {
      print('\n📋 Locais disponíveis:');
      for (int i = 0; i < _locais.length; i++) {
        print('${i + 1} - ${_locais[i].nome}');
      }
      stdout.write('Selecione o local (0 para nenhum): ');
      final input = stdin.readLineSync()?.trim();
      final localIndex = int.tryParse(input ?? '');
      if (localIndex != null &&
          localIndex > 0 &&
          localIndex <= _locais.length) {
        localId = _locais[localIndex - 1].id;
      }
    }

    int? sensorId;
    if (_sensores.isNotEmpty) {
      print('\n📋 Sensores disponíveis:');
      for (int i = 0; i < _sensores.length; i++) {
        print('${i + 1} - ${_sensores[i].tipo}');
      }
      stdout.write('Selecione o sensor (0 para nenhum): ');
      final input = stdin.readLineSync()?.trim();
      final sensorIndex = int.tryParse(input ?? '');
      if (sensorIndex != null &&
          sensorIndex > 0 &&
          sensorIndex <= _sensores.length) {
        sensorId = _sensores[sensorIndex - 1].id;
      }
    }

    int novoId = _dispositivos.isEmpty
        ? 1
        : (_dispositivos.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final dispositivo = Dispositivo(novoId, modelo, status,
        localId: localId, sensorId: sensorId);
    _dispositivos.add(dispositivo);

    if (_conectado) {
      try {
        await dbConnection.connection!.query(
          'INSERT INTO dispositivo (modelo, status, local_idLocal, sensor_idSensor) VALUES (?, ?, ?, ?)',
          [
            dispositivo.modelo,
            dispositivo.status,
            dispositivo.localId,
            dispositivo.sensorId
          ],
        );
        print('💾 Dispositivo salvo no banco de dados!');
      } catch (e) {
        print('❌ Erro ao salvar dispositivo no banco: $e');
      }
    }

    print('✅ Dispositivo cadastrado com sucesso!');
    dispositivo.exibirDados();
  }

  Future<void> _cadastrarSensor() async {
    print('\n📡 CADASTRAR SENSOR SCT-013');

    stdout.write('Tipo: ');
    final tipo = stdin.readLineSync()?.trim() ?? 'SCT-013';

    stdout.write('Unidade de Medida: ');
    final unidadeMedida = stdin.readLineSync()?.trim() ?? 'A';

    stdout.write('Fator de Calibração: ');
    final fatorCalibracao =
        double.tryParse(stdin.readLineSync()?.trim() ?? '30.0') ?? 30.0;

    stdout.write('Tensão de Referência (V): ');
    final tensaoReferencia =
        double.tryParse(stdin.readLineSync()?.trim() ?? '2.5') ?? 2.5;

    if (tipo.isEmpty || unidadeMedida.isEmpty) {
      print('❌ Tipo e unidade de medida são obrigatórios!');
      return;
    }

    int novoId = _sensores.isEmpty
        ? 1
        : (_sensores.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final sensor = SensorSCT013(
        novoId, tipo, unidadeMedida, fatorCalibracao, tensaoReferencia);
    _sensores.add(sensor);

    if (_conectado) {
      try {
        await dbConnection.connection!.query(
          'INSERT INTO sensor (tipo, unidadeMedida) VALUES (?, ?)',
          [sensor.tipo, sensor.unidadeMedida],
        );
        print('💾 Sensor salvo no banco de dados!');
      } catch (e) {
        print('❌ Erro ao salvar sensor no banco: $e');
      }
    }

    print('✅ Sensor cadastrado com sucesso!');
    sensor.exibirDados();
  }

  Future<void> _cadastrarUsuario() async {
    print('\n👤 CADASTRAR USUÁRIO');

    if (_empresas.isEmpty) {
      print('❌ É necessário cadastrar uma empresa primeiro!');
      return;
    }

    stdout.write('Nome: ');
    final nome = stdin.readLineSync()?.trim() ?? '';

    stdout.write('Email: ');
    final email = stdin.readLineSync()?.trim() ?? '';

    stdout.write('Senha: ');
    final senha = stdin.readLineSync()?.trim() ?? '';

    stdout.write('Perfil (Administrador/Operador/Visualizador): ');
    final perfil = stdin.readLineSync()?.trim() ?? '';

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || perfil.isEmpty) {
      print('❌ Todos os campos são obrigatórios!');
      return;
    }

    print('\n📋 Empresas disponíveis:');
    for (int i = 0; i < _empresas.length; i++) {
      print('${i + 1} - ${_empresas[i].nome}');
    }

    int? empresaIndex;
    do {
      stdout.write('Selecione a empresa (1-${_empresas.length}): ');
      final input = stdin.readLineSync()?.trim();
      empresaIndex = int.tryParse(input ?? '');

      if (empresaIndex == null ||
          empresaIndex < 1 ||
          empresaIndex > _empresas.length) {
        print('❌ Selecione uma empresa válida!');
      }
    } while (empresaIndex == null);

    final empresaSelecionada = _empresas[empresaIndex - 1];

    int novoId = _usuarios.isEmpty
        ? 1
        : (_usuarios.map((e) => e.idUsuario).reduce((a, b) => a > b ? a : b) +
            1);
    final usuario = Usuario(
      idUsuario: novoId,
      nome: nome,
      email: email,
      senhaLogin: senha,
      perfil: perfil,
      dataCriacao: DateTime.now(),
      ultimoLogin: DateTime.now(),
      empresaId: empresaSelecionada.idEmpresa,
    );

    _usuarios.add(usuario);

    if (_conectado) {
      try {
        await dbConnection.connection!.query(
          'INSERT INTO usuario (nome, email, senhaLogin, perfil, dataCriacao, ultimoLogin, empresa_idEmpresa) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            usuario.nome,
            usuario.email,
            usuario.senhaLogin,
            usuario.perfil,
            usuario.dataCriacao.toIso8601String(),
            usuario.ultimoLogin.toIso8601String(),
            usuario.empresaId
          ],
        );
        print('💾 Usuário salvo no banco de dados!');
      } catch (e) {
        print('❌ Erro ao salvar usuário no banco: $e');
      }
    }

    print('✅ Usuário cadastrado com sucesso!');
    usuario.exibirDados();
  }

  // ========== MÉTODOS DE CONSULTA ==========
  void _listarTodasEntidades() {
    print('\n📋 RESUMO GERAL DO SISTEMA POWERKEEPER');
    print('═' * 50);
    print('🏢 EMPRESAS: ${_empresas.length}');
    for (var empresa in _empresas) {
      print('   • ${empresa.nome} (CNPJ: ${empresa.cnpj})');
    }

    print('\n🏠 LOCAIS: ${_locais.length}');
    for (var local in _locais) {
      print('   • ${local.nome} (Ref: ${local.referencia})');
    }

    print('\n⚙️  DISPOSITIVOS: ${_dispositivos.length}');
    for (var dispositivo in _dispositivos) {
      print('   • ${dispositivo.modelo} (Status: ${dispositivo.status})');
    }

    print('\n📡 SENSORES: ${_sensores.length}');
    for (var sensor in _sensores) {
      print('   • ${sensor.tipo} (Unidade: ${sensor.unidadeMedida})');
    }

    print('\n👤 USUÁRIOS: ${_usuarios.length}');
    for (var usuario in _usuarios) {
      print('   • ${usuario.nome} (Perfil: ${usuario.perfil})');
    }

    print('\n📊 LEITURAS ENERGÉTICAS: ${_leituras.length}');
    if (_leituras.isNotEmpty) {
      final ultimaLeitura = _leituras.last;
      print(
          '   • Última: ${ultimaLeitura.potencia.toStringAsFixed(1)}W - ${ultimaLeitura.corrente.toStringAsFixed(3)}A - ${ultimaLeitura.consumoKwh.toStringAsFixed(6)}kWh');
    }
    print('═' * 50);
  }

  void _listarEmpresas() {
    print('\n🏢 LISTA DE EMPRESAS');
    print('═' * 50);
    if (_empresas.isEmpty) {
      print('📭 Nenhuma empresa cadastrada');
    } else {
      for (var empresa in _empresas) {
        empresa.exibirDados();
      }
    }
  }

  void _listarLocais() {
    print('\n🏠 LISTA DE LOCAIS');
    print('═' * 50);
    if (_locais.isEmpty) {
      print('📭 Nenhum local cadastrada');
    } else {
      for (var local in _locais) {
        local.exibirDados();
      }
    }
  }

  void _listarDispositivos() {
    print('\n⚙️  LISTA DE DISPOSITIVOS');
    print('═' * 50);
    if (_dispositivos.isEmpty) {
      print('📭 Nenhum dispositivo cadastrado');
    } else {
      for (var dispositivo in _dispositivos) {
        dispositivo.exibirDados();
      }
    }
  }

  void _listarSensores() {
    print('\n📡 LISTA DE SENSORES');
    print('═' * 50);
    if (_sensores.isEmpty) {
      print('📭 Nenhum sensor cadastrado');
    } else {
      for (var sensor in _sensores) {
        sensor.exibirDados();
      }
    }
  }

  void _listarUsuarios() {
    print('\n👤 LISTA DE USUÁRIOS');
    print('═' * 50);
    if (_usuarios.isEmpty) {
      print('📭 Nenhum usuário cadastrado');
    } else {
      for (var usuario in _usuarios) {
        usuario.exibirDados();
      }
    }
  }

  void _listarLeituras() {
    print('\n📊 LISTA DE LEITURAS ENERGÉTICAS');
    print('═' * 50);
    if (_leituras.isEmpty) {
      print('📭 Nenhuma leitura registrada');
    } else {
      for (var leitura in _leituras) {
        print(leitura.toString());
      }
    }
  }

  // ========== MÉTODOS ESPECÍFICOS DO POWERKEEPER ==========
  void _calcularEconomia() {
    print('\n💰 CALCULAR ECONOMIA DE ENERGIA');
    print('═' * 50);

    if (_leituras.isEmpty) {
      print('❌ Nenhuma leitura disponível');
      return;
    }

    double consumoTotal =
        _leituras.map((l) => l.consumoKwh).reduce((a, b) => a + b);
    double custoTotal = _leituras.map((l) => l.custo).reduce((a, b) => a + b);
    double potenciaMedia =
        _leituras.map((l) => l.potencia).reduce((a, b) => a + b) /
            _leituras.length;

    print('📊 ANÁLISE DE CONSUMO');
    print('─' * 40);
    print('💡 Consumo total: ${consumoTotal.toStringAsFixed(2)} kWh');
    print('💰 Custo total: R\$ ${custoTotal.toStringAsFixed(2)}');
    print('⚡ Potência média: ${potenciaMedia.toStringAsFixed(1)} W');
    print('📈 Número de medições: ${_leituras.length}');
    print('─' * 40);

    if (potenciaMedia > 1000) {
      print('💡 SUGESTÃO: Considere otimizar equipamentos de alto consumo');
    }
    if (consumoTotal > 100) {
      print(
          '💡 SUGESTÃO: Avalie a possibilidade de migração para tarifa branca');
    }
  }

  Future<void> _enviarLeiturasParaMySQL() async {
    print('\n📤 ENVIAR LEITURAS DO FIREBASE PARA MYSQL');
    print('═' * 50);

    if (_leituras.isEmpty) {
      print('❌ Nenhuma leitura disponível para enviar');
      return;
    }

    if (!_conectado) {
      print('❌ Sem conexão com o banco MySQL');
      return;
    }

    if (_sensores.isEmpty) {
      print('❌ Nenhum sensor cadastrado no MySQL');
      return;
    }

    final sensorId = _sensores.first.id;
    int leiturasEnviadas = 0;

    print('📊 Total de leituras no Firebase: ${_leituras.length}');
    print('🚀 Enviando leituras...');

    for (final leitura in _leituras) {
      try {
        String dataFormatada = _formatarDataParaMySQL(leitura.timestamp);

        await dbConnection.connection!.query(
          '''INSERT INTO leitura 
           (timeStamp, tensao, corrente, potencia, consumokWh, custo, sensor_idSensor) 
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            dataFormatada,
            leitura.tensao,
            leitura.corrente,
            leitura.potencia,
            leitura.consumoKwh,
            leitura.custo,
            sensorId,
          ],
        );

        leiturasEnviadas++;
      } catch (e) {
        print('❌ Erro ao enviar leitura ${leitura.id}: $e');
      }
    }

    print('✅ $leiturasEnviadas leitura(s) enviada(s) para MySQL!');
  }

  String _formatarDataParaMySQL(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second';
  }

  // ========== MÉTODO PRINCIPAL ==========
  Future<void> executar() async {
    print("\n");
    print('╔══════════════════════════════════════════════╗');
    print('║           SISTEMA DE MONITORAMENTO           ║');
    print('║              ⚡ POWERKEEPER ⚡                ║');
    print('╚══════════════════════════════════════════════╝');

    if (_conectado) {
      print('✅ CONECTADO AO BANCO DE DADOS');
    } else {
      print('❌ SEM CONEXÃO COM BANCO - Dados apenas locais');
    }

    print('🔥 CONECTADO AO FIREBASE');
    print('📊 Leituras carregadas: ${_leituras.length}');

    bool executando = true;

    while (executando) {
      print('\n' + '═' * 60);
      print('🔧 MENU PRINCIPAL - POWERKEEPER');
      print('═' * 60);
      print('📋 CADASTROS:');
      print(' 1  - 🏢 Cadastrar Empresa');
      print(' 2  - 🏠 Cadastrar Local');
      print(' 3  - ⚙️  Cadastrar Dispositivo');
      print(' 4  - 📡 Cadastrar Sensor SCT-013');
      print(' 5  - 👤 Cadastrar Usuário');
      print('═' * 60);
      print('🔍 CONSULTAS:');
      print(' 6  - 📊 Listar Todas as Entidades');
      print(' 7  - 🏢 Listar Empresas');
      print(' 8  - 🏠 Listar Locais');
      print(' 9  - ⚙️  Listar Dispositivos');
      print('10  - 📡 Listar Sensores');
      print('11  - 👤 Listar Usuários');
      print('═' * 60);
      print('⚡ ENERGIA & MEDIÇÕES:');
      print('12 - 📊 Listar Todas as Leituras');
      print('13 - 💰 Calcular Economia');
      print('14 - 📤 Enviar Leituras para MySQL');
      print('15 - 🔄 Recarregar Dados do Firebase');
      print('═' * 60);

      stdout.write('👉 Escolha: ');
      final opcao = stdin.readLineSync();

      switch (opcao) {
        case '1':
          await _cadastrarEmpresa();
          break;
        case '2':
          await _cadastrarLocal();
          break;
        case '3':
          await _cadastrarDispositivo();
          break;
        case '4':
          await _cadastrarSensor();
          break;
        case '5':
          await _cadastrarUsuario();
          break;
        case '6':
          _listarTodasEntidades();
          break;
        case '7':
          _listarEmpresas();
          break;
        case '8':
          _listarLocais();
          break;
        case '9':
          _listarDispositivos();
          break;
        case '10':
          _listarSensores();
          break;
        case '11':
          _listarUsuarios();
          break;
        case '12':
          _listarLeituras();
          break;
        case '13':
          _calcularEconomia();
          break;
        case '14':
          await _enviarLeiturasParaMySQL();
          break;
        case '15':
          print('\n🔄 RECARREGANDO DADOS DO FIREBASE...');
          await _carregarLeiturasFirebase();
          break;
        case '0':
          await dbConnection.close();
          print('\n👋 Encerrando PowerKeeper...');
          executando = false;
          break;
        default:
          print('❌ Opção inválida!');
      }

      if (executando) {
        print('\n⏎ Pressione Enter para continuar...');
        stdin.readLineSync();
      }
    }

    print('\n⚡ PowerKeeper finalizado. Até logo!');
  }
}
