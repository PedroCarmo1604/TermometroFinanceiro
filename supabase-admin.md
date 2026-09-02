# Termômetro Financeiro — Administração do Supabase

Guia de referência pra quem administra o projeto Supabase por trás do Termômetro Financeiro (hoje, só você). Separado do [melhorias.md](melhorias.md) porque é sobre *operação* do backend, não sobre histórico de features do app — cresce com o tempo conforme surgirem novas situações.

Projeto: `cnlbbjntntplxexcihjx` (Supabase, plano free). Schema versionado em [supabase/schema.sql](supabase/schema.sql) (tabela `user_data`) e [supabase/transactions.sql](supabase/transactions.sql) (tabela `transactions`) — rodar os dois, nessa ordem, numa instalação nova.

## O que existe hoje

- **Auth**: e-mail + senha, gerenciado pelo Supabase Auth (`auth.users` — tabela que você não edita diretamente, só através do painel ou da API de Auth).
- **Dados de mês**: uma tabela, `public.user_data`, uma linha por usuário (`user_id` = `auth.users.id`), com duas colunas `jsonb` (`months_data`, `investments_data`) — o mesmo JSON que antes ficava no `localStorage`, agora na nuvem.
- **Itens de gasto categorizados** (desde 01/09/2026): tabela `public.transactions` — uma linha por item de Saída/Diário (`user_id`, `date`, `tipo` (`'diario'`/`'saida'`), `valor`, `categoria`, `descricao` opcional). Diferente de `user_data`, não é um blob regravado por inteiro: cada item é um `insert`/`delete` isolado. Ver [decisoes.md](decisoes.md) pro porquê dessa tabela ser separada em vez de mais uma coluna `jsonb`.
- **RLS (Row Level Security)**: cada usuário só consegue ler/escrever as próprias linhas — em `user_data` (`auth.uid() = user_id`) e em `transactions` (mesma regra, política `"users manage own transactions"`). É a *única* camada de proteção — não existe API própria nem verificação extra no servidor, é tudo PostgREST do Supabase liberado pela política de RLS.
- **Trigger `on_auth_user_created`**: toda vez que alguém completa o cadastro, uma linha vazia em `user_data` é criada automaticamente pra esse usuário. `transactions` não precisa de trigger equivalente — começa vazia por padrão (ausência de linhas, não uma linha vazia).

## Usos possíveis do painel Supabase (o que você pode fazer, e onde)

- **Authentication → Users**: ver a lista de contas criadas (e-mail, data de criação, último login), forçar reset de senha, banir ou deletar um usuário manualmente. Deletar um usuário aqui remove a linha correspondente em `user_data` automaticamente (por causa do `on delete cascade` no schema).
- **Table Editor → user_data / transactions**: ver/editar os dados de qualquer usuário diretamente, em formato de planilha. Útil pra depurar um problema específico sem precisar reproduzir no app — em `transactions`, cada linha é um item de gasto isolado, então dá pra filtrar por `user_id`/`date`/`categoria` direto na grade em vez de abrir um JSON.
- **SQL Editor**: consultas ad hoc (ex: "quantos usuários têm dados nos investimentos") ou mudanças de schema (nova coluna, novo índice). É onde o `schema.sql` original foi rodado.
- **Database → Backups**: no plano free, só existe backup diário com retenção curta (não é point-in-time recovery — isso é só nos planos pagos). Ver seção de cuidados abaixo.
- **Logs (API/Postgres)**: útil se algo no app começar a dar erro de autenticação/permissão e não ficar claro pelo console do navegador.

## Cuidados importantes

- **A `service_role` key nunca pode ir pro `termometro-financeiro.html` nem pra nenhum lugar público.** Ela ignora RLS completamente — é acesso de administrador total ao banco. A `anon` key (a que está no `.html`) é segura de expor porque só abre o que a RLS permite; a `service_role` não tem esse limite. Se algum dia precisar dela (ex: futura function de exclusão de conta de verdade), ela só pode existir do lado do servidor (Edge Function), nunca no client.
- **Editar dados pelo Table Editor bypassa a RLS** (você está logado como admin do projeto, não como um usuário comum) — o que é útil pra depurar, mas também significa que um erro de edição ali não tem a mesma rede de segurança que o app tem. Não existe "desfazer" nem lixeira — um `UPDATE`/`DELETE` errado no SQL Editor é definitivo. Prefira testar em `select` antes de rodar `update`/`delete`, e sempre com `where` explícito.
- **Mudança de schema deveria passar pelos arquivos `.sql` versionados** (`supabase/schema.sql` pra `user_data`, `supabase/transactions.sql` pra `transactions`) — se alterar uma tabela direto pelo painel (SQL Editor ou Table Editor) sem atualizar o arquivo correspondente depois, o schema versionado no git fica desatualizado e mentindo sobre o estado real do banco. Trate os arquivos como a fonte da verdade: mude neles primeiro (ou pelo menos replique a mudança logo em seguida), senão uma reinstalação futura (rodar os `.sql` do zero num projeto novo) não vai bater com o banco atual.
- **Migrações pontuais** (rodadas uma vez e não representam o schema atual) ficam em arquivos separados, com aviso no topo pra não rodar de novo por engano — ex: `supabase/transactions-migration.sql`, que moveu o histórico antigo de `diario`/`saida` (número dentro de `months_data`) pra dentro de `transactions` na virada de 01/09/2026. Não confundir com `schema.sql`/`transactions.sql`, que são a estrutura permanente.
- **Plano free pausa o projeto após ~1 semana sem uso.** Se você ficar um tempo sem abrir o app nem o painel, o projeto entra em pausa e o login/dados param de funcionar até você reativar manualmente pelo painel (é rápido, mas é surpresa desagradável se acontecer sem avisar ninguém).
- **Backup automático do Supabase no free tier é curto e não é uma garantia forte.** Continue usando o "Exportar backup" de dentro do próprio app de vez em quando — é a cópia que você controla, fora do Supabase, e é a única forma de recuperar dados se o projeto for excluído ou corrompido por engano.
- **Você tem acesso irrestrito aos dados financeiros reais de quem usa o app** (hoje, só você mesmo; se um dia outra pessoa usar, isso muda de figura). Diferente da versão anterior (criptografia local, "zero-knowledge" — nem o app conseguia ler sem a senha), agora os dados ficam em texto no Postgres, protegidos só por RLS + TLS + criptografia em repouso do provedor. Vale a pena ter isso em mente antes de considerar abrir o app pra mais alguém usar.
- **Limites do plano free** (verificar de vez em quando se ainda estão OK pro seu uso): 500MB de banco, 5GB de bandwidth/mês, projeto pausa por inatividade (ver acima). Pra um app pessoal de controle financeiro isso é folgado, mas se o projeto crescer (mais usuários, mais histórico), fica bom monitorar em Settings → Billing/Usage.

## Quando revisitar este documento

Atualize esse arquivo sempre que: mudar o schema, adicionar uma nova política de RLS, decidir sobre exclusão de conta de verdade (vai exigir uma Edge Function com `service_role`, ver backlog em [melhorias.md](melhorias.md)), ou tomar qualquer decisão operacional sobre o banco que não seja óbvia só de olhar o código.
