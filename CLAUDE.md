# Termômetro Financeiro

App de controle financeiro pessoal — arquivo único (`termometro-financeiro.html`), sem build, sem dependências externas. Roda direto abrindo no navegador. Login local com criptografia (AES-GCM), sem servidor.

Ver [melhorias.md](melhorias.md) pra histórico de melhorias, correções e backlog.

## Rotina de git

- **Commitar sempre que uma tarefa terminar e o app estiver funcionando** (uma feature, uma correção de bug, um ajuste visual — qualquer entrega completa). Não é preciso pedir permissão para esse commit especificamente — é uma autorização permanente do usuário.
- Mensagens de commit em português, curtas, focando no "porquê" quando fizer sentido (mesmo padrão do resto do projeto).
- Ações git além de commit (push, reset, rebase, force) continuam exigindo confirmação normal — a autorização é só para o commit em si.
- Os arquivos `termometro-financeiro.checkpoint-*.html` eram a forma manual de backup antes dessa rotina existir. Com commits de verdade, esse mecanismo fica redundante — considerar não criar novos checkpoints desse tipo pra mudanças cobertas por commit.
