import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/nfse/provider/nbs_provider.dart';

/// Seletor de serviço inteligente com busca no PocketBase (CNAE ou NBS).
/// 
/// Agora busca em 2.700 registros mapppeados de Goiânia.
class NbsSelector extends ConsumerStatefulWidget {
  final Function(ServicoTributario servico) onNbsSelected;

  const NbsSelector({super.key, required this.onNbsSelected});

  @override
  ConsumerState<NbsSelector> createState() => _NbsSelectorState();
}

class _NbsSelectorState extends ConsumerState<NbsSelector> {
  final _controller = TextEditingController();
  String _query = '';
  ServicoTributario? _selecionado;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selecionar(ServicoTributario servico) {
    setState(() {
      _selecionado = servico;
      _query = '';
      _controller.clear();
    });
    widget.onNbsSelected(servico);
    FocusScope.of(context).unfocus();
  }

  void _limpar() {
    setState(() {
      _selecionado = null;
      _query = '';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se selecionou, mostra card de confirmação Quiet Luxury
    if (_selecionado != null) {
      return _buildSelecionado(_selecionado!);
    }

    final resultadosAsync = ref.watch(buscarServicosProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input de Busca ──────────────────────────────────────────
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Qual atividade você realizou?',
            hintText: 'Ex: manutenção, consultoria, software...',
            prefixIcon: const Icon(Icons.search, color: MeireTheme.primaryColor),
            suffixIcon: _query.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: _limpar)
                : null,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),

        // ── Resultados da Busca ─────────────────────────────────────
        if (_query.length >= 3) ...[
          const SizedBox(height: 8),
          resultadosAsync.when(
            loading: () => const LinearProgressIndicator(color: MeireTheme.primaryColor),
            error: (_, __) => const Text('Erro ao buscar atividades.', style: TextStyle(color: Colors.red, fontSize: 13)),
            data: (resultados) {
              if (resultados.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nada encontrado. tente outros termos (Ex: atividade econômica).', style: TextStyle(color: Colors.grey, fontSize: 13)),
                );
              }

              return Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MeireTheme.iceGray),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: resultados.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final item = resultados[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.descricaoBusca, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      subtitle: Text('Cód. Goiânia: ${item.codigoLc116}', style: const TextStyle(color: MeireTheme.primaryColor, fontSize: 11)),
                      trailing: const Icon(Icons.add_circle_outline, size: 20, color: MeireTheme.primaryColor),
                      onTap: () => _selecionar(item),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSelecionado(ServicoTributario servico) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MeireTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MeireTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: MeireTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servico.descricaoBusca, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Atividade: ${servico.codigoLc116}', style: const TextStyle(color: MeireTheme.primaryColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey), onPressed: _limpar),
        ],
      ),
    );
  }
}
