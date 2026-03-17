---
description: 🛡️ Escudo Meiri - Validador de Integridade do Emissor
---

# 🛡️ ESCUDO MEIRI — PROTOCOLO DE PROTEÇÃO DO EMISSOR

## ⚠️ REGRA DE OURO
**NUNCA faça alterações nos arquivos do emissor sem seguir TODOS os passos abaixo.**

## 📁 ARQUIVOS SAGRADOS (Zona de Risco Máximo)
Estes arquivos controlam a emissão de notas fiscais. Qualquer erro = perda de receita real do cliente.

| Arquivo | Função | Risco |
|---------|--------|-------|
| `backend_node/server.js` | Gateway principal, rotas, autenticação superuser | 🔴 CRÍTICO |
| `backend_node/gerador_dps.js` | Gera o XML da nota fiscal | 🔴 CRÍTICO |
| `backend_node/vortex_emissor_nacional.js` | Motor de emissão (assina + transmite) | 🔴 CRÍTICO |
| `backend_node/assinador_soberano.js` | Assinatura digital do XML | 🔴 CRÍTICO |
| `backend_node/enviador_adn.js` | Transmissão para o governo | 🔴 CRÍTICO |
| `backend_node/config.js` | URLs, credenciais superuser | 🟡 ALTO |
| `lib/features/nfse/services/notas_fiscais_service.dart` | Chamada do Flutter para emissão | 🟡 ALTO |
| `lib/features/nfse/ui/nfse_form_page.dart` | Formulário de emissão | 🟢 MÉDIO |

## 📋 CHECKLIST OBRIGATÓRIO (Antes de QUALQUER alteração nos arquivos acima)

### Passo 1: Rodar Sacred Guard (Validação XML)
// turbo
```
node backend_node/sacred_guard.js
```
Se falhar → **PARE IMEDIATAMENTE**. Não altere nada até o guard passar.

### Passo 2: Verificar Servidor Local
// turbo
```
powershell -Command "try { $r = Invoke-RestMethod -Uri 'http://127.0.0.1:3000/api/status' -TimeoutSec 5; Write-Host ('OK: ' + $r.motor + ' - ' + $r.status) } catch { Write-Host 'ERRO: Servidor local não responde'; exit 1 }"
```

### Passo 3: Testar Rota de Emissão Local
// turbo
```
powershell -Command "try { Invoke-RestMethod -Uri 'http://127.0.0.1:3000/api/nacional/emitir' -Method POST -ContentType 'application/json' -Body '{\"userId\":\"test\",\"payload\":{\"competencia\":\"2026-01-01\"}}' -TimeoutSec 5 } catch { $s = $_.Exception.Response.StatusCode.value__; if ($s -eq 500) { Write-Host 'OK: Rota /emitir respondeu (500 esperado sem user real)' } else { Write-Host ('ERRO: Status inesperado ' + $s); exit 1 } }"
```

### Passo 4: Testar Rota Alias /emit Local
// turbo
```
powershell -Command "try { Invoke-RestMethod -Uri 'http://127.0.0.1:3000/api/nacional/emit' -Method POST -ContentType 'application/json' -Body '{\"userId\":\"test\",\"payload\":{\"competencia\":\"2026-01-01\"}}' -TimeoutSec 5 } catch { $s = $_.Exception.Response.StatusCode.value__; if ($s -eq 500) { Write-Host 'OK: Rota /emit respondeu (500 esperado sem user real)' } else { Write-Host ('ERRO: Status inesperado ' + $s); exit 1 } }"
```

### Passo 5: Testar Produção (Após Deploy)
// turbo
```
powershell -Command "try { Invoke-RestMethod -Uri 'https://api.meireapp.com.br/api/nacional/emitir' -Method POST -ContentType 'application/json' -Body '{\"userId\":\"test\"}' -TimeoutSec 10 } catch { $s = $_.Exception.Response.StatusCode.value__; if ($s -eq 400 -or $s -eq 500) { Write-Host ('OK: Producao respondeu (Status ' + $s + ' esperado sem dados reais)') } elseif ($s -eq 404) { Write-Host 'ERRO CRITICO: Rota NAO EXISTE na producao! Deploy necessario!'; exit 1 } else { Write-Host ('ERRO: Status inesperado ' + $s); exit 1 } }"
```

## 🚫 PROIBIÇÕES ABSOLUTAS
1. **NUNCA** alterar o nome da rota `/api/nacional/emitir` sem atualizar AMBOS: server.js E notas_fiscais_service.dart
2. **NUNCA** remover `await assegurarAutenticacao()` de dentro das rotas que acessam PocketBase
3. **NUNCA** mexer na tag `<dCompet>` ou no formato da competência
4. **NUNCA** adicionar lógica de CPF no sistema (é 100% CNPJ)
5. **NUNCA** alterar a estrutura do XML sem rodar `sacred_guard.js`
6. **NUNCA** fazer require() direto sem try-catch para módulos opcionais

## 🚀 PROCEDIMENTO DE DEPLOY
```bash
# 1. Na máquina local (Windows):
scp -i "ssh-key-2026-03-12.key" backend_node/server.js ubuntu@137.131.155.89:~/backend_node/

# 2. No servidor (SSH):
ssh -i "ssh-key-2026-03-12.key" ubuntu@137.131.155.89 "pm2 restart meire-api && sleep 2 && pm2 logs meire-api --lines 5 --nostream"

# 3. Verificar que aparece nos logs:
# ✅ "🚀 Backend re-autenticado como SUPERUSER."
# ✅ "🟢 Servidor Meire App na porta 3000"
```

## 🔑 CREDENCIAIS SUPERUSER
- Ficam em `backend_node/.env` (NUNCA commitar no git!)
- Variáveis: `PB_ADMIN_EMAIL`, `PB_ADMIN_PASSWORD`, `PB_URL`
- O config.js lê essas variáveis. Se estiverem undefined = crash de autenticação.
