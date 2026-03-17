# Arquitetura MEIRE v1.0 - Stack Contábil Soberana

**Camada 1 (App): Flutter (Riverpod + Realtime)**
- UI Quiet Luxury focada em Fricção Zero (Haptic Feedback, Animações Suaves, Termômetro Tributário em tempo real).

**Camada 2 (Database): PocketBase (Go/SQLite)**
- Persistência ultrarrápida com auditoria de status em tempo real. O cofre local da SAID.

**Camada 3 (Backend): Node.js Enterprise**
- Integrador mTLS com 3 Pilares de Resiliência:
  1. **Cofre de Autenticação**: Cache em RAM para evitar sobretaxa de tokens (SAPI), garantido até a expiração.
  2. **Catraca de Fluxo (Fila)**: Enfileiramento de requisições para evitar Rate Limit e gargalos na Receita.
  3. **Fortaleza de Contingência**: Retry automático com Backoff Exponencial (2s -> 4s -> 8s).

**Camada 4 (Integrador): Serpro (Integra Contador)**
- Conexão direta via API Nacional (NFS-e v1.0). "Sua carteira no governo."
