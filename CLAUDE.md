# Termômetro Financeiro

App de controle financeiro pessoal — arquivo único (`termometro-financeiro.html`), sem build. Roda direto abrindo no navegador. Login por e-mail/senha via Supabase Auth; dados sincronizam entre dispositivos através de um backend real (Postgres + RLS), não mais só localmente.

Ver [melhorias.md](melhorias.md) pra histórico de melhorias, correções e backlog. Pra documentação em tom leigo (pra retomar conhecimento sem reler código): [glossario.md](glossario.md) explica termos técnicos usados nos docs (RLS, JWT, jsonb, etc.), [logica-financeira.md](logica-financeira.md) explica como o app calcula saldo/rentabilidade/reserva, e [decisoes.md](decisoes.md) registra o porquê de escolhas de arquitetura (Supabase, jsonb vs. relacional, etc.). [supabase-admin.md](supabase-admin.md) cobre operação do backend.

## Rotina de git

- **Commitar sempre que uma tarefa terminar e o app estiver funcionando** (uma feature, uma correção de bug, um ajuste visual — qualquer entrega completa). Não é preciso pedir permissão para esse commit especificamente — é uma autorização permanente do usuário.
- Mensagens de commit em português, curtas, focando no "porquê" quando fizer sentido (mesmo padrão do resto do projeto).
- Ações git além de commit (push, reset, rebase, force) continuam exigindo confirmação normal — a autorização é só para o commit em si.
- Os arquivos `termometro-financeiro.checkpoint-*.html` eram a forma manual de backup antes dessa rotina existir. Com commits de verdade, esse mecanismo fica redundante — considerar não criar novos checkpoints desse tipo pra mudanças cobertas por commit.

## Arquitetura (pra retomar rápido numa sessão nova)

- **Arquivo único** (`termometro-financeiro.html`, ~2900 linhas): `<style>` + HTML estático (login/note-modal/toast) + `<script>` com uma IIFE só. Sem build, mas com duas dependências externas via CDN: fonte Inter (Google Fonts) e o cliente `supabase-js` (versão pinada + hash SRI, ver `<head>`) — inerente a ter virado um app com backend real.
- **Fluxo de telas**: `renderLanding()` → `renderLogin()` (abas Entrar/Criar conta) → depois de `doLogin()` bem-sucedido, `render()` despacha pra `renderDiario()` / `renderInvestimentos()` / `renderDashboard()` conforme `activeTab`. Cada `render*()` reescreve `#tf-app.innerHTML` inteiro e rewire os listeners — não há diffing, é reconstrução total a cada mudança de estado. `boot()` (chamada no final do script) checa `supabase.auth.getSession()` antes de decidir entre landing e app — login sobrevive a F5.
- **Backend (Supabase)**: autenticação por e-mail/senha via Supabase Auth (`doLogin`, `logout`), com recuperação de senha suportada pela plataforma (ainda sem UI própria). Dados ficam numa única tabela `user_data` (`supabase/schema.sql`) — uma linha por usuário, colunas `months_data`/`investments_data` em `jsonb` guardando exatamente a mesma estrutura que antes ia pro `localStorage`; RLS garante que cada usuário só lê/escreve a própria linha. `loadData`/`saveData`/`loadInvestments`/`saveInvestments` fazem essa leitura/escrita (as duas últimas com debounce de 600ms, pra não disparar uma requisição por tecla). Tema (`ui-theme`) continua em `localStorage` puro — preferência de dispositivo, não dado de conta. **Deixou de ser zero-knowledge**: a versão anterior (PBKDF2+AES-GCM local) garantia que nem o app conseguia ler os dados sem a senha; agora o Postgres do Supabase guarda em texto, protegido por RLS + TLS + criptografia em repouso do provedor, não mais por uma chave derivada da senha do usuário.
- **Sistema de design "Nocturne"**: veio de um projeto no claude.ai/design (`projectId 3079f77c-fd14-4ec7-89bb-6bd0c2adbe2e`, acessível via ferramenta `DesignSync`). Paleta e tokens estão nas variáveis CSS do `:root` (`--bg`, `--surface`, `--text`, `--cold` = acento único blurple, mais `--warm`/`--hot`/`--mid`/`--good` que são semânticos pra dinheiro/termômetro, não fazem parte da paleta do design system). Botões de ação primária são contornados, nunca preenchidos — regra do sistema original.

## Armadilhas conhecidas

- **O Grep tool às vezes exibe `//` como `\`** (e outras pequenas corrupções de escape) no `output_mode:"content"`. Isso já causou pelo menos uma tentativa de edição com `old_string` errado. **Sempre confirmar trechos exatos com `Read` antes de montar um `old_string` de `Edit`**, nunca confiar cegamente no texto que o Grep devolve.
- **Preview local de arquivos fora da pasta do projeto renderiza como snapshot estático** (sem JS rodando) na ferramenta de browser — só funciona de verdade pra arquivos dentro de `VibeCoding/`. Publicar como Artifact também não é testável ao vivo por essa ferramenta (Artifacts são privados, e o browser de teste não tem login no claude.ai do usuário).
- Todos os testes ao vivo feitos pela IA rodam num navegador de teste isolado, **sem acesso ao `localStorage` real do usuário** (que fica no Vivaldi dele) — bom pra testar fluxo sem risco, mas não serve pra inspecionar os dados reais.

## Pendências abertas

- `termometro-legacy-backup.json` (pasta do projeto) nunca foi commitado nem gitignorado — ainda em aberto se deve entrar no histórico do git (tem dado financeiro real, ainda que já superado pela versão criptografada) ou ficar só local.
- **`SUPABASE_URL`/`SUPABASE_ANON_KEY`** no topo do `<script>` já estão preenchidos com os valores reais do projeto criado no Supabase (`supabase/schema.sql` já rodado no SQL Editor).
- **`supabase/storage.sql` ainda não foi rodado** — cria o bucket `avatars` (público pra leitura, RLS restringindo escrita ao próprio usuário) usado pela foto de perfil no menu de conta. Sem rodar esse SQL uma vez no painel do Supabase (mesmo fluxo do `schema.sql`: SQL Editor → New query → colar → Run), o upload de foto falha; o resto do app (login, dados, alterar senha) funciona normalmente sem ele.
- Migração dos dados reais do modelo local antigo (perfil `pedropaulo`, PBKDF2+AES-GCM) pro Supabase é manual: login na versão antiga → "Exportar backup" → criar conta na versão nova → "Importar backup". Ainda não feita.
- Ver `melhorias.md` → seção Backlog pra lista completa de melhorias identificadas e ainda não implementadas (deploy do `.html` em algum host estático, exclusão de conta de verdade via Edge Function, recuperação de senha na UI, normalização relacional, testes automatizados, sincronização entre abas/dispositivos, teste mobile ao vivo).
