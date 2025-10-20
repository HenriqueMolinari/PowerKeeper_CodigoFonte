class Local {
  int _id;
  String _nome;
  String _referencia;
  int _empresaId;

  Local(this._id, this._nome, this._referencia, this._empresaId);

  int get id => _id;
  set id(int value) => _id = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;

  String get referencia => _referencia;
  set referencia(String value) => _referencia = value;

  int get empresaId => _empresaId;
  set empresaId(int value) => _empresaId = value;

  void exibirDados() {
    print('🏠 DADOS DO LOCAL');
    print('─' * 30);
    print('ID: $_id');
    print('Nome: $_nome');
    print('Referência: $_referencia');
    print('Empresa ID: $_empresaId');
    print('─' * 30);
  }
}
