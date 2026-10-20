import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/models/product_model.dart';
import 'package:sedim_app/providers/company_provider.dart';
import 'package:sedim_app/services/api_service.dart';
import 'package:sedim_app/widgets/widgets.dart';

class PriceScreen extends StatefulWidget {

  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  //variables
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  //metadatos de zona horaria de la última carga (timezone-aware)
  String? _infoTimezone;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    //La empresa viene preseleccionada por el CompanyProvider (empresas del login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final seleccionada = companyProvider.codigoSeleccionado;
      if (seleccionada != null) {
        _loadProducts(seleccionada);
      }
    });
  }

  //agrego future para poder utilizar el refresh indicator nuevo para visualizar
  //nuevos productos
  Future<void> _loadProducts(String code) async {
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    //Filtro multi-empresa: solo empresas autorizadas en el login (403 del backend)
    if (!companyProvider.seleccionar(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No tiene acceso a la empresa ${companyProvider.nombreVisible(code)}')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _searchCtrl.clear();
      _infoTimezone = null;
    });
    try {
      //GET /api/mobile/prices/:empresa con X-Timezone-Offset (timezone adaptive)
      final priceModel = await ApiService().getPrices(code);
      if (!mounted) return;
      setState(() {
        _allProducts = priceModel.productos;
        _filteredProducts = _allProducts;
        if (priceModel.clientTime != null) {
          final hora = TimeOfDay.fromDateTime(priceModel.clientTime!).format(context);
          _infoTimezone = 'Hora cliente: $hora (${priceModel.etiquetaCliente})';
        }
        //si el usuario tiene algo escrito en el buscador, volvemos a filtrar
        if (_searchCtrl.text.isNotEmpty) {
          _filterProducts(_searchCtrl.text);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando productos')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _filterProducts(String query){
    final lower = query.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) =>
      p.nombre.toLowerCase().contains(lower) || p.codPro.toLowerCase().contains(lower)
      ).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    //nuevas variables del tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    //final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final inputFillColor = isDark ? Color(0xFF1e1e1e) : Colors.white;
    //Solo empresas autorizadas para el usuario (multi-empresa)
    final companyProvider = Provider.of<CompanyProvider>(context);
    final empresas = companyProvider.empresas;

    return Scaffold(
      //backgroundColor: Color(0xFF0f1012),
      //backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Gestion de Precios'),
        //backgroundColor: Color(0xFF1e1e1e),
      ),
      body: Column(
        children: [
          //1. Seleccionador de Empresas (basado en empresas[] del login)
          Container(
            padding: EdgeInsets.all(15),
            //color: Color(0xFF1e1e1e),
            color: isDark ? Colors.black12 : Colors.white,
            child: DropdownButtonFormField<String>(
              dropdownColor: cardColor,
              //dropdownColor: Color(0xFF2c2c2c),
              //style: TextStyle(color: Colors.white),
              style: TextStyle(color: textColor),
              initialValue: companyProvider.codigoSeleccionado,
              //value: _selectedCompany,
              decoration: InputDecoration(
                labelText: empresas.isEmpty
                    ? 'Sin empresas asignadas'
                    : 'Seleccione una Empresa',
                //labelStyle: TextStyle(color: Colors.grey),
                labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade700),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: inputFillColor
              ),
              items: empresas.map((empresa) => DropdownMenuItem(
                value: empresa.codigoProducto,
                child: Text(companyProvider.nombreVisible(empresa.codigoProducto)),
              )).toList(),
              onChanged: empresas.isEmpty
                  ? null
                  : (val) {
                      if (val != null) _loadProducts(val);
                    },
              ),
          ),
          //Info de zona horaria de la última carga (precios timezone-aware)
          if (_infoTimezone != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: isDark ? Colors.grey : Colors.grey.shade600),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _infoTimezone!,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          //2. Creo buscador
          if (companyProvider.codigoSeleccionado != null)
          Padding(
            padding: EdgeInsets.all(15),
            child: TextField(
              controller: _searchCtrl,
              //style: TextStyle(color: Colors.white),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                //hintStyle: TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                //fillColor: Color(0xFF1e1e1e),
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey)
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.transparent : Colors.grey.shade300
                    )
                  )
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              //color del circulo de carga
              color: Colors.white,
              backgroundColor: Colors.blueAccent,
              //funcion al deslizar hacia abajo
              onRefresh: () async {
                final seleccionada = companyProvider.codigoSeleccionado;
                if(seleccionada != null){
                  await _loadProducts(seleccionada);
                }
              },
              child: ListView.builder(
                //con esto funciona scroll, lest test
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: _filteredProducts.length,
                itemBuilder: (ctx, i) {
                  final prod = _filteredProducts[i];
                  return ProductCard(
                    key: ValueKey(prod.codPro),
                    product: prod
                    );
                }
                ),
            )
            )
        ],
      ),
    );
  }
}
