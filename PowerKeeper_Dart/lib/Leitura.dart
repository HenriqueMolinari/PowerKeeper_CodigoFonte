class Leitura {
  final int _id;
  final DateTime _timestamp;
  final double _tensao;
  final double _corrente;
  final double _potencia;
  final double _consumoKwh;
  final double _custo;
  final int _sensorId;

  Leitura(
    this._id,
    this._timestamp,
    this._tensao,
    this._corrente,
    this._potencia,
    this._consumoKwh,
    this._custo,
    this._sensorId,
  );

  factory Leitura.fromFirebase(Map<String, dynamic> data, String id) {
    DateTime timestamp;
    double tensao = 0.0;
    double corrente = 0.0;
    double potencia = 0.0;
    double consumoKwh = 0.0;
    double custo = 0.0;

    try {
      // 🔥 REMOVA ESTES DOIS PRINTS:
      // print('🔍 Processando leitura $id: $data'); // DEBUG
      // print('✅ Leitura $id processada: $corrente A, $potencia W, $consumoKwh kWh'); // DEBUG

      // Processar timestamp
      final timestampData = data['timestamp'];
      if (timestampData != null) {
        if (timestampData is int) {
          timestamp =
              DateTime.fromMillisecondsSinceEpoch(timestampData, isUtc: true);
        } else if (timestampData is String) {
          timestamp = DateTime.parse(timestampData).toUtc();
        } else {
          timestamp = DateTime.now().toUtc();
        }
      } else {
        timestamp = DateTime.now().toUtc();
      }

      // Processar valores numéricos (que podem vir como strings)
      tensao = _parseDouble(data['tensao']);
      corrente = _parseDouble(data['corrente']);
      potencia = _parseDouble(data['potencia']);

      // Consumo pode vir como consumo_total_Wh (Watts-hora) - converter para kWh
      final consumoWh =
          _parseDouble(data['consumo_total_Wh'] ?? data['consumokWh']);
      consumoKwh = consumoWh / 1000.0; // Converter Wh para kWh

      custo = _parseDouble(data['custo_total_reais'] ?? data['custo']);
    } catch (e) {
      print('❌ Erro ao processar dados da leitura $id: $e');
      print('📋 Dados problemáticos: $data');
      timestamp = DateTime.now().toUtc();
    }

    return Leitura(
      int.tryParse(id) ?? DateTime.now().millisecondsSinceEpoch,
      timestamp,
      tensao,
      corrente,
      potencia,
      consumoKwh,
      custo,
      1, // sensor_id padrão
    );
  }

  // Método auxiliar para parsear double de strings
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove aspas e converte
      final cleanValue = value.replaceAll('"', '').trim();
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  int get id => _id;
  DateTime get timestamp => _timestamp;
  double get tensao => _tensao;
  double get corrente => _corrente;
  double get potencia => _potencia;
  double get consumoKwh => _consumoKwh;
  double get custo => _custo;
  int get sensorId => _sensorId;

  DateTime get dataHora => _timestamp;

  void exibirDados() {
    print('📊 DADOS DA LEITURA ENERGÉTICA');
    print('─' * 40);
    print('ID: $_id');
    print('Timestamp: ${_formatarData(_timestamp)}');
    print('Tensão: ${_tensao.toStringAsFixed(1)} V');
    print('Corrente: ${_corrente.toStringAsFixed(3)} A');
    print('Potência: ${_potencia.toStringAsFixed(2)} W');
    print('Consumo: ${_consumoKwh.toStringAsFixed(6)} kWh');
    print('Custo: R\$ ${_custo.toStringAsFixed(4)}');
    print('Sensor ID: $_sensorId');
    print('─' * 40);
  }

  String _formatarData(DateTime data) {
    final localTime = data.toLocal();
    return '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year} '
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Leitura $id - ${_formatarData(_timestamp)} - ${_corrente.toStringAsFixed(3)}A - ${_potencia.toStringAsFixed(1)}W - ${_consumoKwh.toStringAsFixed(6)}kWh';
  }
}
