import 'Sensor.dart';

class SensorSCT013 extends Sensor {
  final double _fatorCalibracao;
  final double _tensaoReferencia;

  SensorSCT013(
    int id,
    String tipo,
    String unidadeMedida,
    this._fatorCalibracao,
    this._tensaoReferencia,
  ) : super(id, tipo, unidadeMedida);

  double get fatorCalibracao => _fatorCalibracao;
  double get tensaoReferencia => _tensaoReferencia;

  @override
  double coletarDado() {
    // Simulação de coleta de dados do sensor SCT-013
    // Em um sistema real, isso se conectaria ao hardware
    double leituraBruta = _simularLeitura();
    return _calcularCorrente(leituraBruta);
  }

  double _simularLeitura() {
    // Simula uma leitura de tensão entre 0V e 5V
    return (DateTime.now().millisecond % 500) / 100.0;
  }

  double _calcularCorrente(double tensaoLida) {
    // Fórmula simplificada para cálculo de corrente baseada na tensão
    // SCT-013 typically outputs voltage proportional to current
    return (tensaoLida - _tensaoReferencia) * _fatorCalibracao;
  }

  double calcularPotencia(double corrente, double tensao) {
    return corrente * tensao;
  }

  double calcularConsumo(double potencia, double tempoHoras) {
    return potencia * tempoHoras / 1000; // kWh
  }

  double calcularCusto(double consumoKwh, double tarifa) {
    return consumoKwh * tarifa;
  }

  @override
  void exibirDados() {
    print('🔌 SENSOR SCT-013 - MEDIÇÃO DE CORRENTE');
    print('─' * 40);
    print('ID: $id');
    print('Tipo: $tipo');
    print('Unidade de Medida: $unidadeMedida');
    print('Fator de Calibração: $_fatorCalibracao');
    print('Tensão de Referência: ${_tensaoReferencia}V');
    print('─' * 40);
  }

  void realizarMedicaoCompleta(double tensaoRede, double tarifaKwh) {
    double corrente = coletarDado();
    double potencia = calcularPotencia(corrente, tensaoRede);
    double consumoHora = calcularConsumo(potencia, 1.0);
    double custoHora = calcularCusto(consumoHora, tarifaKwh);

    print('📊 MEDIÇÃO COMPLETA - SENSOR SCT-013');
    print('─' * 40);
    print('💡 Corrente: ${corrente.toStringAsFixed(2)} A');
    print('⚡ Tensão: ${tensaoRede.toStringAsFixed(1)} V');
    print('🔋 Potência: ${potencia.toStringAsFixed(2)} W');
    print('📈 Consumo/hora: ${consumoHora.toStringAsFixed(4)} kWh');
    print('💰 Custo/hora: R\$ ${custoHora.toStringAsFixed(4)}');
    print('─' * 40);
  }
}
