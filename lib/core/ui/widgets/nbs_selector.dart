import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meiri/core/ui/theme.dart';
import 'package:meiri/features/nfse/provider/nbs_provider.dart';

class NbsSelector extends ConsumerStatefulWidget {
  final Function(NbsModel) onNbsSelected;

  const NbsSelector({
    super.key,
    required this.onNbsSelected,
  });

  @override
  ConsumerState<NbsSelector> createState() => _NbsSelectorState();
}

class _NbsSelectorState extends ConsumerState<NbsSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Filter based on 'nome' against cached data
  List<NbsModel> _getFilteredOptions(String query, List<NbsModel> cachedData) {
    if (query.isEmpty) {
      // Retorna todos os itens para se comportar como Dropdown quando vazio
      return cachedData;
    }
    return cachedData.where((nbs) {
      final lowercaseQuery = query.toLowerCase();
      final description = nbs.nome.toLowerCase();
      return description.contains(lowercaseQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the FutureProvider for the cached data
    final nbsDataAsync = ref.watch(nbsProvider);

    return nbsDataAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(color: MeiriTheme.primaryColor),
        ),
      ),
      error: (error, stack) => const Text('Erro ao carregar lista de NBS',
          style: TextStyle(color: Colors.red)),
      data: (cachedData) {
        if (cachedData.isEmpty) {
          return const Text('Nenhum dado IBS disponível.');
        }

        return RawAutocomplete<NbsModel>(
          textEditingController: _searchController,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _getFilteredOptions(textEditingValue.text, cachedData);
          },
          displayStringForOption: (NbsModel option) => option.nome,
          onSelected: (NbsModel selection) {
            widget.onNbsSelected(selection);
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
                labelText: 'Buscar NBS do IBGE (Ex: "Publicidade")',
                hintText: 'Digite para buscar um código NBS',
                prefixIcon:
                    const Icon(Icons.search, color: MeiriTheme.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (text) {
                setState(() {});
              },
              onTap: () {
                // Ao clicar no campo (ganhar foco), força o RawAutocomplete a
                // exibir as opções mesmo sem texto recriando uma busca manual
                if (textEditingController.text.isEmpty) {
                  // Um pequeno truque para forçar a renderização das opções (hack padrão do Flutter para esse widget)
                  textEditingController.value = const TextEditingValue(
                      text: '', selection: TextSelection.collapsed(offset: 0));
                }
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<NbsModel> onSelected,
            Iterable<NbsModel> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 250, maxWidth: 800),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        borderRadius: BorderRadius.vertical(
                          top: index == 0
                              ? const Radius.circular(12)
                              : Radius.zero,
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
                                option.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Código NBS: ${option.id}',
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
      },
    );
  }
}
