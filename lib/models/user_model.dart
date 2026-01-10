class UserModel {
  final int id;
  final String usuario;
  final String nombre;
  final String rol;

  UserModel({
    required this.id, 
    required this.usuario, 
    required this.nombre, 
    required this.rol});

  //Usaremos factory para crear el usuario desde el JSON del servidor (azure)
  factory UserModel.fromJson(Map<String,dynamic> json){
   return UserModel(
    id: json['id'] ?? 0,
    usuario: json['usuario'] ?? '',
    nombre: json['nombre'] ?? 'Usuario del Sistema',
    //back devuelve rol
    rol: json['rol'] ?? 'Sin Rol'
   ); 
  }  
}