class Dispositivo {
  final int id;
  final String modelo;
  final String status;
  final int? localId;
  final int? sensorId;

  Dispositivo(this.id, this.modelo, this.status, {this.localId, this.sensorId});

  int get getId => id;
  String get getModelo => modelo;
  String get getStatus => status;
  int? get getLocalId => localId;
  int? get getSensorId => sensorId;

  void exibirDados() {
    print('⚙️  DADOS DO DISPOSITIVO');
    print('─' * 30);
    print('ID: $id');
    print('Modelo: $modelo');
    print('Status: $status');
    if (localId != null) print('Local ID: $localId');
    if (sensorId != null) print('Sensor ID: $sensorId');
    print('─' * 30);
  }

  void atualizarStatus(String novoStatus) {
    print('Status atualizado de $status para $novoStatus');
  }

  bool estaAtivo() {
    return status.toLowerCase() == 'ativo';
  }

  Map<String, dynamic> toMap() {
    return {
      'idDispositivo': id,
      'modelo': modelo,
      'status': status,
      'local_idLocal': localId,
      'sensor_idSensor': sensorId,
    };
  }

  @override
  String toString() {
    return 'Dispositivo{id: $id, modelo: $modelo, status: $status}';
  }
}
