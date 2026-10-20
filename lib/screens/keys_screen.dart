import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/models/system_key_model.dart';
import 'package:sedim_app/providers/user_provider.dart';
import 'package:sedim_app/services/api_service.dart';

class KeysScreen extends StatefulWidget {
   
  const KeysScreen({super.key});

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  //variables
  List<SystemKey> _keys = [];
  bool _isLoading = true;
  bool _hasAccess = false;
  @override
  void initState(){
    super.initState();
    //validación de rol antes de montar la widget (build)
    WidgetsBinding.instance.addPostFrameCallback((_){
      _checkPermissionAndLoad();
    });
  }
  void _checkPermissionAndLoad(){
    //Filtro por rol usando el UserProvider (contrato: claves solo Administrador,
    //el backend ahora responde 403 'Acceso no autorizado' al resto)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isAdmin){
      setState(() => _hasAccess = true);
      _loadKeys();      
    } else {
      setState(() {
        _hasAccess = false;
        _isLoading = false;
      });
    }
  }
  Future<void> _loadKeys() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService().getSystemKeys();
      if (!mounted) return;
      setState(() {
        _keys = data.map((json) => SystemKey.fromJson(json)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error cargando claves, verificar')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  //working con dialogs
  //primero
  void _showOptionsDialog(SystemKey keyItem){
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text(keyItem.descripcion.toUpperCase()),
        content: Text('Seleccione una acción para este registro'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: (){
              Navigator.pop(ctx);
              _showConfirmationDialog(keyItem);              
            }, 
            child: Text('Modificar')
          )
        ],
      )
    );
  }
  //segundo
  void _showConfirmationDialog(SystemKey keyItem){
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text('¿Está seguro de proceder?'),
        content: Text('Va a editar el valor de: ${keyItem.descripcion}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('No')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed:() {
              Navigator.pop(ctx);
              _showEditDialog(keyItem);
            }, 
            child: Text('Sí, continuar', style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }
  //tercero y ultimo
  void _showEditDialog(SystemKey keyItem){
    final ctrl = TextEditingController(
      text: keyItem.conversion.toString()
    );
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text('Editar: ${keyItem.descripcion}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingrese el nuevo valor:'),
            SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Valor (Password)'
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Cancelar')
          ),
          ElevatedButton(
            onPressed:() async {
              final newVal = double.tryParse(ctrl.text);
              if (newVal == null){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Número Inválido')
                    )
                  );
                return;
              }
              Navigator.pop(ctx);
              await _updateValue(keyItem, newVal);
            }, 
            child: Text('Actualizar')
            )
        ],
      )
    );
  }

  Future<void> _updateValue(SystemKey keyItem, double newValue) async {
    //mostrar carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Actualizando...'),
        duration: Duration(milliseconds: 500),
      ),
    );
    final success = await ApiService().updateSystemKey(
      keyItem.nNumero,
      newValue,
    );

    if (!mounted) return;
    if (success) {
      await _loadKeys(); //volver a carga lista
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Actualizado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_hasAccess && !_isLoading){
      return Scaffold(
        appBar: AppBar(
          title: Text('Gestión de Claves'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person, size: 80, color: Colors.grey.shade400),
              SizedBox(height: 20),
              Text('Acceso Restringido', style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Solo administradores pueden ver esto', style: TextStyle(color: Colors.grey))
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Claves'),
      ),
      body: _isLoading 
      ? Center(child: CircularProgressIndicator())
      : ListView.separated(
        itemCount: _keys.length,
        separatorBuilder: (_,_) => Divider(height: 1),
        itemBuilder: (ctx,i){
          final item = _keys[i];
          return ListTile(
            tileColor: isDark ? null : Colors.white,
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.vpn_key, color: Colors.white, size: 18),              
            ),
            title: Text(item.descripcion, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Valor Actual: ${item.conversion}', style: TextStyle(color: isDark
             ? Colors.grey
            : Colors.grey.shade700)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _showOptionsDialog(item),
          );
        }
        
        
        )
    );
  }
}