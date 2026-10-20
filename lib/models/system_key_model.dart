class SystemKey{
  final int nNumero;
  final String descripcion;
  double conversion;

  SystemKey({
    required this.nNumero, 
    required this.descripcion,
    required this.conversion
    });

  factory SystemKey.fromJson(Map<String, dynamic> json){
    return SystemKey(
      nNumero: json['n_numero'] ?? 0,
      descripcion: json['c_describe'] ?? 'Sin Nombre',
      //aseguramos que se lea como double aunque venga como entero o string
      conversion: double.tryParse(json['conversion'].toString()) ?? 0.0
    );
  }

  
}