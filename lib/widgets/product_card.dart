//Widget Tarjeta de Producto Expandible
//Test 1

import 'package:flutter/material.dart';
import 'package:sedim_app/models/product_model.dart';
import 'package:sedim_app/services/api_service.dart';

class ProductCard extends StatefulWidget {

  final Product product;
   
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {

  //variables
  bool _isSaving = false;
  late List<TextEditingController> _controllers;

  @override
  void initState(){
    super.initState();
    _controllers = [
      TextEditingController(text: widget.product.p1.toString()),
      TextEditingController(text: widget.product.p2.toString()),
      TextEditingController(text: widget.product.p3.toString()),
      TextEditingController(text: widget.product.p4.toString()),
      TextEditingController(text: widget.product.p5.toString()),
      TextEditingController(text: widget.product.p6.toString()),
    ];
  }

  void _save() async {
    setState(()=> _isSaving = true);
    final data = {
      'p1' : double.tryParse(_controllers[0].text) ?? 0,
      'p2' : double.tryParse(_controllers[1].text) ?? 0,
      'p3' : double.tryParse(_controllers[2].text) ?? 0,
      'p4' : double.tryParse(_controllers[3].text) ?? 0,
      'p5' : double.tryParse(_controllers[4].text) ?? 0,
      'p6' : double.tryParse(_controllers[5].text) ?? 0,
    };
    
    final success = await ApiService().updatePrices(widget.product.codPro, data);
    setState(()=> _isSaving = false);

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? "Precios actualizados" : "Error al guardar"),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 1),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {

    //variable de los colores de los temas
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.grey : Colors.grey.shade600;


    return Card(
      //color: Color(0xFF1e1e1e),
      color: cardColor, //cambio de fondo dinámico
      elevation: isDark ? 0 : 2,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ExpansionTile(
        title: Text(
          widget.product.nombre, 
          style: TextStyle(
            color: textColor,
            //color: Colors.white, 
            fontWeight: FontWeight.bold
            )),
        subtitle: Text(
          "COD: ${widget.product.codPro} | P1: ${widget.product.p1}", 
          style: TextStyle(
            color: subtitleColor
            //color: Colors.grey
            )),
        iconColor: Colors.blueAccent,
        collapsedIconColor: isDark ? Colors.grey : Colors.grey.shade400,
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 2.5, //ajuste de los inpunts a 2.2
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: List.generate(6, (index) => _buildPriceInput(index, isDark, textColor!)),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(Icons.save, size: 18, color: Colors.white),                       
                      label: Text(_isSaving ? "Guardando..." : "GUARDAR CAMBIOS", style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _isSaving ? null : _save,
                      ),
                  )
              ],
            ),
            )
        ],
        ),
    );
  }

  Widget _buildPriceInput(int index, bool isDark, Color textColor){
    return TextField(
      controller: _controllers[index],
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: textColor,
        //color: Colors.white, 
        fontSize: 13),
      decoration: InputDecoration(
        labelText: 'P${index + 1}',
        labelStyle: TextStyle(
          color: isDark ? Colors.grey : Colors.grey.shade600,
          //color: Colors.grey, 
          fontSize: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
        //fillColor: Colors.black12,
        contentPadding: EdgeInsets.symmetric(horizontal: 10)
      ),
    );
  }
}



