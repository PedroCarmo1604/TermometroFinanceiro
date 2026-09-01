-- Termômetro Financeiro — tabela de itens de gasto categorizados (feature "categorização de gastos")
-- Rodar uma vez em: Supabase Dashboard > SQL Editor > New query > colar tudo > Run.
--
-- Só cria a tabela vazia + RLS — não migra dado nenhum. A migração dos valores antigos
-- de "diario"/"saida" (hoje dentro de user_data.months_data) fica num script separado
-- (transactions-migration.sql), que só deve rodar bem próximo do deploy do código novo
-- que passa a ler dessa tabela — combinado com o usuário pra não haver perda de dados
-- escritos no intervalo entre migração e deploy.

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  date date not null,
  tipo text not null check (tipo in ('diario', 'saida')),
  valor numeric(10,2) not null,
  categoria text not null,
  descricao text,
  created_at timestamptz not null default now()
);

create index transactions_user_date_idx on public.transactions (user_id, date);

alter table public.transactions enable row level security;

create policy "users manage own transactions"
  on public.transactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
