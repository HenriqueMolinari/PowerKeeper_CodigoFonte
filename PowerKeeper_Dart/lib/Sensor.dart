abstract class Sensor {
  final int _id;
  final String _tipo;
  final String _unidadeMedida;

  Sensor(this._id, this._tipo, this._unidadeMedida);

  int get id => _id;
  String get tipo => _tipo;
  String get unidadeMedida => _unidadeMedida;

  double coletarDado();

  void exibirDados() {
    print('---- Dados do Sensor ---');
    print('ID: $_id');
    print('Tipo: $_tipo');
    print('Unidade de Medida: $_unidadeMedida');
  }

  @override
  String toString() {
    return 'Sensor{id: $_id, tipo: $_tipo, unidadeMedida: $_unidadeMedida}';
  }
}
