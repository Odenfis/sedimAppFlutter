import 'package:flutter/material.dart';
import 'package:sedim_app/models/product_model.dart';
import 'package:sedim_app/services/api_service.dart';
import 'package:sedim_app/widgets/widgets.dart';

class PriceScreen extends StatefulWidget {
   
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  //variables
  String? _selectedCompany;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, String> _companies = {
    '02':'Cocineria',
    '06':'Mar Picante', //cambiar por Mar Picante
    '04':'Abruzzo'
  };
  void _loadProducts(String code) async {
    setState(() {
    _isLoading = true;
    _selectedCompany = code;
    _searchCtrl.clear(); 
    });
    try{
      final data = await ApiService().getProducts(code);
      setState(() {
        _allProducts = data.map((json) => Product.fromJson(json)).toList();
        _filteredProducts = _allProducts;
      });
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando productos')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _filterProducts(String query){
    final lower = query.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) =>
      p.nombre.toLowerCase().contains(lower) || p.codPro.contains(lower)
      ).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0f1012),
      appBar: AppBar(
        title: Text('Gestion de Precios'),
        backgroundColor: Color(0xFF1e1e1e),
      ),
      body: Column(
        children: [
          //1. Seleccionador de Empresas
          Container(
            padding: EdgeInsets.all(15),
            color: Color(0xFF1e1e1e),
            child: DropdownButtonFormField(
              dropdownColor: Color(0xFF2c2c2c),
              style: TextStyle(color: Colors.white),
              initialValue: _selectedCompany,
              //value: _selectedCompany,
              decoration: InputDecoration(
                labelText: 'Seleccione una Empresa',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder()
              ),
              items: _companies.entries.map((e)=> DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), 
              onChanged: (val) => _loadProducts(val!)
              ),
          ),
          //2. Creo buscador
          if (_selectedCompany != null)
          Padding(
            padding: EdgeInsets.all(15),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Color(0xFF1e1e1e),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (ctx, i) {
                final prod = _filteredProducts[i];
                return ProductCard(
                  key: ValueKey(prod.codPro),
                  product: prod
                  );
              }
              )
            )
        ],
      ),
    );
  }
}