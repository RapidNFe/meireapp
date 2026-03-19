import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/clients/models/tomador_model.dart';
import 'package:meire/features/clients/services/tomador_service.dart';
import 'package:meire/core/ui/widgets/cnae_validator_dialog.dart';
import 'package:flutter/services.dart';

/// Seletor de Tomadores (Clientes) com estilo Premium "Lux".
/// 
/// Realiza busca em tempo real no PocketBase conforme o usuário digita.
class TomadorSelectorLux extends ConsumerStatefulWidget {
  final Function(TomadorModel tomadorSelecionado) onSelected;
  final VoidCallback onNovoCliente;

  const TomadorSelectorLux({
    super.key,
    required this.onSelected,
    required this.onNovoCliente,
  });

  @override
  ConsumerState<TomadorSelectorLux> createState() => _TomadorSelectorLuxState();
}

class _TomadorSelectorLuxState extends ConsumerState<TomadorSelectorLux> {
  String _searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  TomadorModel? _selecionado;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selecionar(TomadorModel tomador) {
    _validarSelecao(tomador);
  }

  void _validarSelecao(TomadorModel tomador) {
    final service = ref.read(tomadorServiceProvider);
    
    // Se for um parceiro já salvo como salão ou tiver CNAE de beleza
    if (tomador.isSalaoParceiro || service.isCnaeBeleza(tomador.cnae)) {
      _confirmarSelecao(tomador);
    } else {
      // 🛡️ ALERTA DE SOBERANIA (CNAE Divergente)
      HapticFeedback.vibrate();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CnaeValidatorDialog(
          razaoSocial: tomador.razaoSocial,
          atividadePrincipal: tomador.cnaeDescricao ?? "Atividade não identificada",
          onConfirmarDireto: () => _confirmarSelecao(tomador.copyWith(isSalaoParceiro: false)),
          onForcarSalao: () => _confirmarSelecao(tomador.copyWith(isSalaoParceiro: true)),
        ),
      );
    }
  }

  void _confirmarSelecao(TomadorModel tomador) {
    setState(() {
      _selecionado = tomador;
      _searchQuery = '';
      _controller.text = tomador.displayName;
    });
    widget.onSelected(tomador);
    FocusScope.of(context).unfocus();
  }

  void _limpar() {
    setState(() {
      _selecionado = null;
      _searchQuery = '';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultadosAsync = ref.watch(buscarTomadoresProvider(_searchQuery));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input de Busca ──────────────────────────────────────────
        TextFormField(
          controller: _controller,
          readOnly: _selecionado != null,
          decoration: InputDecoration(
            labelText: "Para quem é esta nota?",
            hintText: "Nome, Apelido ou CNPJ/CPF...",
            prefixIcon: Icon(
              _selecionado != null ? Icons.check_circle : Icons.business_center,
              color: _selecionado != null ? Colors.green : MeireTheme.primaryColor,
            ),
            suffixIcon: _selecionado != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: _limpar,
                  )
                : IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: MeireTheme.accentColor),
                    tooltip: "Cadastrar Novo Cliente",
                    onPressed: widget.onNovoCliente,
                  ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),

        // ── Lista de Resultados (Dropdown Customizado) ────────────────
        if (_searchQuery.length >= 2 && _selecionado == null) ...[
          const SizedBox(height: 8),
          resultadosAsync.when(
            loading: () => const LinearProgressIndicator(color: MeireTheme.primaryColor),
            error: (err, st) => const Text("Erro ao buscar clientes.",
                style: TextStyle(color: Colors.red, fontSize: 12)),
            data: (resultados) {
              if (resultados.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: widget.onNovoCliente,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Cliente não encontrado. Cadastrar?", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MeireTheme.primaryColor,
                      side: const BorderSide(color: MeireTheme.iceGray),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }

              return Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF003326) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MeireTheme.iceGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: resultados.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: MeireTheme.iceGray),
                  itemBuilder: (context, index) {
                    final tomador = resultados[index];
                    return ListTile(
                      title: Text(
                        tomador.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text("Doc: ${tomador.cnpj}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: MeireTheme.primaryColor),
                      onTap: () => _selecionar(tomador),
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
}
