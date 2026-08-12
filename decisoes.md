# Termômetro Financeiro — Registro de decisões técnicas

Consolida, num formato de consulta rápida, decisões de arquitetura já narradas (de forma mais espalhada, junto do histórico de features) no [melhorias.md](melhorias.md). Cada entrada segue o mesmo formato: contexto → o que foi decidido → o que se ganhou → o que se perdeu ou ficou pendente. Termos técnicos citados aqui estão explicados no [glossario.md](glossario.md).

Adicione uma entrada nova aqui sempre que uma decisão de arquitetura for tomada (não uma feature qualquer — algo que muda *como* o sistema funciona por trás, não só o que ele mostra).

---

## Autenticação: Supabase Auth padrão em vez de login local criptografado (zero-knowledge)

**Contexto**: a primeira versão do login (30/07/2026) era local — sem servidor. A senha digitada virava uma chave de criptografia (PBKDF2 + AES-GCM) que embaralhava os dados guardados no `localStorage` daquele navegador específico. Ninguém, nem o próprio app, conseguia ler os dados sem a senha certa.

**Decisão** (11/08/2026): trocar isso pelo Supabase Auth (e-mail + senha gerenciados por um serviço externo), com os dados passando a viver num banco Postgres na nuvem em vez do navegador.

**Ganhos**:
- Multi-dispositivo de verdade — os mesmos dados aparecem em qualquer navegador/computador, não só onde foram criados.
- Recuperação de senha possível (o Supabase Auth já suporta `resetPasswordForEmail`; falta só a UI, ver backlog em [melhorias.md](melhorias.md)).
- Deixa de existir o cenário "esqueceu a senha, perdeu os dados pra sempre" — que era uma consequência inerente e inegociável do modelo zero-knowledge anterior.

**Perdas / trade-offs**:
- Deixou de ser zero-knowledge: hoje os dados ficam em texto no Postgres do Supabase, protegidos por RLS + TLS + criptografia em repouso do provedor — não mais por uma chave derivada da senha do usuário. Quem administra o projeto Supabase (hoje, só você) tem acesso irrestrito aos dados financeiros reais de qualquer usuário via Table Editor.
- Ganhou uma dependência de terceiro (Supabase) que não existia antes — se o serviço cair ou o projeto free pausar por inatividade, o app para de funcionar até reativar.

**Por que valeu a pena**: pra um app de uso pessoal (hoje, você é o único usuário), a garantia zero-knowledge tinha um custo alto (perder tudo ao esquecer senha) pra um benefício que só importa se alguém além de você olhasse os dados — cenário que, mesmo migrando pro Supabase, continua só nas suas próprias mãos.

---

## Banco de dados: `jsonb` numa tabela única em vez de tabelas relacionais normalizadas

**Contexto**: ao desenhar o backend, o plano original considerava normalizar os dados em tabelas relacionais de verdade (`months_data`, `investments_transactions`, cada lançamento uma linha, com colunas tipadas e relações por ID).

**Decisão**: em vez disso, o mesmo JSON que já existia no código (`state.months` e `invState`) foi salvo direto em duas colunas `jsonb` de uma tabela única (`user_data`, uma linha por usuário) — ver `supabase/schema.sql`.

**Ganhos**:
- Risco de bug quase zero na migração: `recomputePosition`, `evalSum`, `computeSaldoForDay` (o "motor" de cálculo financeiro, ver [logica-financeira.md](logica-financeira.md)) continuaram exatamente iguais, rodando no navegador como sempre rodaram — só o lugar onde o JSON é lido/salvo mudou.
- Implementação rápida — não foi preciso desenhar um schema relacional novo nem reescrever a lógica de cálculo pra trabalhar com linhas de banco em vez de objetos JavaScript.

**Perdas / trade-offs**:
- Consultas agregadas direto no banco (ex: "somar todos os aportes de todos os usuários em julho") exigiriam "abrir" o JSON via SQL — mais lento e mais complicado do que seria com tabelas normalizadas. Hoje isso não é uma necessidade real (dashboards são só do próprio usuário, calculados no navegador), mas fica registrado como limite conhecido.
- Fica no backlog (ver [melhorias.md](melhorias.md)) como algo a revisitar *se* algum dia fizer sentido ter dashboards agregados no servidor.

**Por que valeu a pena**: reduzir o risco de introduzir um bug de cálculo financeiro durante uma migração de infraestrutura foi considerado mais importante do que ganhar uma capacidade de consulta que não tinha uso previsto.

---

## API: sem camada de API própria — cliente Supabase direto do navegador, autorizado por RLS

**Contexto**: o plano original cogitava construir uma API própria entre o app e o banco, pra centralizar regras de acesso.

**Decisão**: não construir nenhuma API própria — o navegador conversa direto com o Postgres via PostgREST (o serviço do Supabase que expõe o banco como API HTTP), e a única regra de acesso é a política de RLS (cada usuário só lê/escreve a própria linha, via `auth.uid() = user_id`).

**Ganhos**: zero código de servidor pra manter, hospedar ou dar patch de segurança — é basicamente a razão de o projeto continuar sendo "um arquivo `.html` só", mesmo tendo ganhado um backend real.

**Perdas / trade-offs**: qualquer regra de negócio que precise rodar "no servidor, fora do controle do usuário" (ex: apagar a conta de login de verdade, que exige a `service_role` key) não pode ser feita nesse modelo — precisa de uma Edge Function (ver próxima entrada).

**Por que valeu a pena**: pra um app de uso pessoal, sem múltiplos tipos de usuário ou regras de negócio complexas, a RLS sozinha cobre a única regra que realmente importa ("cada um só vê o próprio dado").

---

## Exclusão de conta: pendente — exige Edge Function com `service_role`

**Contexto**: "Excluir dados" hoje zera `months_data`/`investments_data` (a informação financeira), mas a conta de login em si (`auth.users`) continua existindo no Supabase Auth.

**Decisão** (ainda não implementada, backlog): apagar a conta de verdade vai exigir uma Supabase Edge Function — um código rodando no servidor do Supabase, autorizado com a `service_role` key, porque apagar um usuário do `auth.users` não é uma operação que a `anon` key (a que o navegador usa) tem permissão de fazer, por design.

**Por que ainda não foi feito**: não é puramente uma decisão técnica — é uma questão de prioridade/escopo (a funcionalidade central de "excluir seus dados" já existe e atende à exigência de LGPD; excluir a *conta de login* em si é uma camada adicional, sem urgência enquanto o app tem um usuário só).
