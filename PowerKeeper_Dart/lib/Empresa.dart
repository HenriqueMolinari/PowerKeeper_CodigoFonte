class Empresa {
  int _idEmpresa;
  String _nome;
  String _cnpj;

  Empresa(this._idEmpresa, this._nome, this._cnpj);

  int get idEmpresa => _idEmpresa;
  set idEmpresa(int value) => _idEmpresa = value;

  String get nome => _nome;
  set nome(String value) => _nome = value;

  String get cnpj => _cnpj;
  set cnpj(String value) => _cnpj = value;

  void exibirDados() {
    print('🏢 DADOS DA EMPRESA');
    print('─' * 30);
    print('ID: $_idEmpresa');
    print('Nome: $_nome');
    print('CNPJ: $_cnpj');
    print('─' * 30);
  }
}
