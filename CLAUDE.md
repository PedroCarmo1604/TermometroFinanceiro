# Termômetro Financeiro

App de controle financeiro pessoal — arquivo único (`termometro-financeiro.html`), sem build, sem dependências externas. Roda direto abrindo no navegador. Login local com criptografia (AES-GCM), sem servidor.

Ver [melhorias.md](melhorias.md) pra histórico de melhorias, correções e backlog.

## Rotina de git

- **Commitar sempre que uma tarefa terminar e o app estiver funcionando** (uma feature, uma correção de bug, um ajuste visual — qualquer entrega completa). Não é preciso pedir permissão para esse commit especificamente — é uma autorização permanente do usuário.
- Mensagens de commit em português, curtas, focando no "porquê" quando fizer sentido (mesmo padrão do resto do projeto).
- Ações git além de commit (push, reset, rebase, force) continuam exigindo confirmação normal — a autorização é só para o commit em si.
- Os arquivos `termometro-financeiro.checkpoint-*.html` eram a forma manual de backup antes dessa rotina existir. Com commits de verdade, esse mecanismo fica redundante — considerar não criar novos checkpoints desse tipo pra mudanças cobertas por commit.

## Arquitetura (pra retomar rápido numa sessão nova)

- **Arquivo único** (`termometro-financeiro.html`, ~2900 linhas): `<style>` + HTML estático (login/note-modal/toast) + `<script>` com uma IIFE só. Sem build, sem dependências além da fonte Inter via Google Fonts (`<link>` no topo).
- **Fluxo de telas**: `renderLanding()` → `renderLogin()` (abas Entrar/Criar conta) → depois de `doLogin()` bem-sucedido, `render()` despacha pra `renderDiario()` / `renderInvestimentos()` / `renderDashboard()` conforme `activeTab`. Cada `render*()` reescreve `#tf-app.innerHTML` inteiro e rewire os listeners — não há diffing, é reconstrução total a cada mudança de estado.
- **Login/criptografia**: sem servidor. Usuário+senha → PBKDF2 (210k iterações) → chave AES-GCM. Cada perfil vira duas chaves no `localStorage` (via `window.storage`, com fallback pra `localStorage` puro quando o host não injeta essa API): `months-data:<usuario>` e `investments-data:<usuario>`, mais um índice `tf-profiles` (usuário → salt). Ver `deriveKey`/`encryptJSON`/`decryptJSON`/`doLogin` no código. **Não existe "esqueci minha senha"** — é criptografia de verdade, perdeu a senha, perdeu os dados (por isso o backup export/import existe).
- **Sistema de design "Nocturne"**: veio de um projeto no claude.ai/design (`projectId 3079f77c-fd14-4ec7-89bb-6bd0c2adbe2e`, acessível via ferramenta `DesignSync`). Paleta e tokens estão nas variáveis CSS do `:root` (`--bg`, `--surface`, `--text`, `--cold` = acento único blurple, mais `--warm`/`--hot`/`--mid`/`--good` que são semânticos pra dinheiro/termômetro, não fazem parte da paleta do design system). Botões de ação primária são contornados, nunca preenchidos — regra do sistema original.

## Armadilhas conhecidas

- **O Grep tool às vezes exibe `//` como `\`** (e outras pequenas corrupções de escape) no `output_mode:"content"`. Isso já causou pelo menos uma tentativa de edição com `old_string` errado. **Sempre confirmar trechos exatos com `Read` antes de montar um `old_string` de `Edit`**, nunca confiar cegamente no texto que o Grep devolve.
- **Preview local de arquivos fora da pasta do projeto renderiza como snapshot estático** (sem JS rodando) na ferramenta de browser — só funciona de verdade pra arquivos dentro de `VibeCoding/`. Publicar como Artifact também não é testável ao vivo por essa ferramenta (Artifacts são privados, e o browser de teste não tem login no claude.ai do usuário).
- Todos os testes ao vivo feitos pela IA rodam num navegador de teste isolado, **sem acesso ao `localStorage` real do usuário** (que fica no Vivaldi dele) — bom pra testar fluxo sem risco, mas não serve pra inspecionar os dados reais.

## Pendências abertas

- `termometro-legacy-backup.json` (pasta do projeto) nunca foi commitado nem gitignorado — ainda em aberto se deve entrar no histórico do git (tem dado financeiro real, ainda que já superado pela versão criptografada) ou ficar só local.
- Ver `melhorias.md` → seção Backlog pra lista completa de melhorias identificadas e ainda não implementadas (inclui: revisar os "Big Numbers" da aba Investimentos, testes automatizados, validação de entrada numérica, acessibilidade, teste mobile ao vivo, sincronização entre abas).
