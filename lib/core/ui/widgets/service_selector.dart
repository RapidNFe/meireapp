import 'package:flutter/material.dart';
import 'package:meiri/core/constants/service_codes.dart';
import 'package:meiri/core/ui/theme.dart';

class ServiceSelector extends StatefulWidget {
  final Function(Map<String, String>) onServiceSelected;

  const ServiceSelector({
    super.key,
    required this.onServiceSelected,
  });

  @override
  State<ServiceSelector> createState() => _ServiceSelectorState();
}

class _ServiceSelectorState extends State<ServiceSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Filter based on 'tributacao_descricao'
  List<Map<String, String>> _getFilteredOptions(String query) {
    if (query.isEmpty) {
      // Retorna todos os itens estáticos para se comportar como Dropdown
      return ServiceCodeData.codes;
    }
    return ServiceCodeData.codes.where((service) {
      final lowercaseQuery = query.toLowerCase();
      final description = service['tributacao_descricao']!.toLowerCase();
      return description.contains(lowercaseQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Map<String, String>>(
      textEditingController: _searchController,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        return _getFilteredOptions(textEditingValue.text);
      },
      displayStringForOption: (Map<String, String> option) =>
          option['tributacao_descricao']!,
      onSelected: (Map<String, String> selection) {
        widget.onServiceSelected(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
          decoration: InputDecoration(
            labelText: 'Buscar Serviço (Ex: "Marketing", "Sistemas")',
            hintText: 'Digite para buscar um serviço da Receita Federal',
            prefixIcon:
                const Icon(Icons.search, color: MeiriTheme.primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      // Notify parent that selection is cleared if necessary
                      // However, typically the text changing isn't enough to deselect unless we handle it manually.
                      // For now, simple clear.
                    },
                  )
                : null,
          ),
          onChanged: (text) {
            // Trigger UI update for suffix icon
            setState(() {});
          },
          onTap: () {
            if (textEditingController.text.isEmpty) {
              textEditingController.value = const TextEditingValue(
                  text: '', selection: TextSelection.collapsed(offset: 0));
            }
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<Map<String, String>> onSelected,
        Iterable<Map<String, String>> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 800),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(12) : Radius.zero,
                      bottom: index == options.length - 1
                          ? const Radius.circular(12)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['tributacao_descricao']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CNAE: ${option['tributacao_codigo']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575), // Colors.grey[600]
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
