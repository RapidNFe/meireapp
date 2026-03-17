import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';

class BuscadorTributarioAvancado extends StatefulWidget {
  // Lista que você vai carregar do seu JSON ou PocketBase
  final List<Map<String, String>> listaCnaes; 
  final Function(Map<String, String>) onSelected;
  
  const BuscadorTributarioAvancado({
    super.key, 
    required this.listaCnaes,
    required this.onSelected,
  });

  @override
  State<BuscadorTributarioAvancado> createState() => _BuscadorTributarioAvancadoState();
}

class _BuscadorTributarioAvancadoState extends State<BuscadorTributarioAvancado> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione a Classificação Tributária (CNAE) *',
          style: TextStyle(fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        
        // O Buscador Mágico
        Autocomplete<Map<String, String>>(
          // O que aparece quando a pessoa clica na opção
          displayStringForOption: (option) => "${option['codigo']} - ${option['descricao']}",
          
          // Lógica de Filtro Rápido
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, String>>.empty();
            }
            
            String busca = textEditingValue.text.toLowerCase();
            
            // Retorna apenas os CNAEs que batem com o código ou com o nome
            return widget.listaCnaes.where((cnae) {
              final codigo = cnae['codigo'] ?? '';
              final descricao = cnae['descricao'] ?? '';
              return codigo.contains(busca) || 
                     descricao.toLowerCase().contains(busca);
            }).take(50); // Limita a 50 resultados na tela para não travar o celular!
          },
          
          // Quando o usuário clica em uma opção da lista
          onSelected: (Map<String, String> selecao) {
            widget.onSelected(selecao);
            // CNAE selecionado com sucesso
          },
          
          // O Design igual ao seu print
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText: 'Buscar Serviço (Ex: "Marketing", "Sistemas")',
                prefixIcon: const Icon(Icons.search, color: MeireTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: MeireTheme.primaryColor, width: 2),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
