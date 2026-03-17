# 🚀 Receita de Deploy Ultra-Leve (Sovereign Build)

Para reduzir o tempo de build no Vercel/Cloudflare de 4 min para o mínimo possível, utilize estas configurações:

### ⚙️ Comando de Build Otimizado
```bash
flutter build web --release --web-renderer html --tree-shake-icons --no-source-maps
```

### 🎯 Por que estas flags?
1. **--web-renderer html**: Reduz o tamanho do bundle inicial em ~3MB (evita o download do CanvasKit WASM). É ideal para apps de gestão como a Meiri.
2. **--tree-shake-icons**: Remove ícones não utilizados das fontes, diminuindo o peso final.
3. **--no-source-maps**: Evita a geração de arquivos de debug que não são necessários em produção, acelerando a finalização do build.

### 🛡️ Otimizações de Contexto Realizadas:
* **.vercelignore**: Configurado para ignorar a pasta `backend_node` (Node.js), `windows/`, e caches. Isso faz com que o builder do Vercel não perca tempo analisando arquivos que não pertencem ao Frontend.
* **.gitignore**: Refinado para evitar o upload de arquivos temporários e logs para o GitHub.

### 📦 Dica de Ouro (Cache):
Se o seu builder permitir (Vercel Build Cache), certifique-se de que a pasta `.pub-cache` e `.dart_tool` sejam mantidas entre builds. Isso pode cortar até 2 minutos de download de dependências.
