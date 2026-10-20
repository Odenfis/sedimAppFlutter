class Product{
  final String codPro;
  final String nombre;
  double p1, p2, p3, p4, p5, p6;

  Product({
    required this.codPro, 
    required this.nombre,
    this.p1 = 0.0,
    this.p2 = 0.0,
    this.p3 = 0.0,
    this.p4 = 0.0,
    this.p5 = 0.0,
    this.p6 = 0.0,
    });

  factory Product.fromJson(Map<String, dynamic> json){
    return Product(
      codPro: json['CodPro'] ?? '',
      nombre: json['Nombre'] ?? 'Sin Nombre',
      p1: (json['PreTema1'] ?? 0).toDouble(),
      p2: (json['PreTema2'] ?? 0).toDouble(),
      p3: (json['PreTema3'] ?? 0).toDouble(),
      p4: (json['PreTema4'] ?? 0).toDouble(),
      p5: (json['PreTema5'] ?? 0).toDouble(),
      p6: (json['PreTema6'] ?? 0).toDouble(),
    );
  }  
}