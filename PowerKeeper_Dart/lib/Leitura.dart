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

    try {
      final timestampData = data['timestamp'];

      if (timestampData == null) {
        timestamp = DateTime.now().toUtc();
      } else if (timestampData is String && timestampData.contains('T')) {
        try {
          timestamp = DateTime.parse(timestampData).toUtc();
        } catch (e) {
          timestamp = DateTime.now().toUtc();
        }
      } else if (timestampData is String && timestampData.contains('/')) {
        try {
          final parts = timestampData.split(' ');
          final dateParts = parts[0].split('/');
          final timeParts = parts[1].split(':');

          timestamp = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            int.parse(timeParts[2]),
          ).toUtc();
        } catch (e) {
          timestamp = DateTime.now().toUtc();
        }
      } else if (timestampData is int || timestampData is double) {
        try {
          timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData.toInt(),
              isUtc: true);
        } catch (e) {
          timestamp = DateTime.now().toUtc();
        }
      } else {
        timestamp = DateTime.now().toUtc();
      }
    } catch (e) {
      timestamp = DateTime.now().toUtc();
    }

    return Leitura(
      int.tryParse(id) ?? DateTime.now().millisecondsSinceEpoch,
      timestamp,
      (data['tensao'] ?? 0.0).toDouble(),
      (data['corrente'] ?? 0.0).toDouble(),
      (data['potencia'] ?? 0.0).toDouble(),
      (data['consumokWh'] ?? 0.0).toDouble(),
      (data['custo'] ?? 0.0).toDouble(),
      (data['sensor_idSensor'] ?? 1).toInt(),
    );
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
    print('Tensão: ${_tensao.toStringAsFixed(2)} V');
    print('Corrente: ${_corrente.toStringAsFixed(2)} A');
    print('Potência: ${_potencia.toStringAsFixed(2)} W');
    print('Consumo: ${_consumoKwh.toStringAsFixed(4)} kWh');
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
    return 'Leitura $id - ${_formatarData(_timestamp)} - ${_potencia.toStringAsFixed(1)}W - ${_consumoKwh.toStringAsFixed(3)}kWh - R\$${_custo.toStringAsFixed(2)}';
  }
}
