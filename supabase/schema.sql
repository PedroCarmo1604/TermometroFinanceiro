-- Termômetro Financeiro — schema do Supabase
-- Rodar uma vez em: Supabase Dashboard > SQL Editor > New query > colar tudo > Run.
-- Sem servidor próprio: a API é o próprio PostgREST do Supabase, protegida por RLS abaixo.

create table public.user_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  months_data jsonb not null default '{}'::jsonb,
  investments_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_data enable row level security;

-- Cada usuário só enxerga/edita a própria linha — é isso que faz o token de sessão
-- (gerenciado pelo Supabase Auth) valer como autenticação de cada chamada.
create policy "select own data"
  on public.user_data for select
  using (auth.uid() = user_id);

create policy "update own data"
  on public.user_data for update
  using (auth.uid() = user_id);

-- Cria a linha automaticamente quando alguém se cadastra (signUp), pra não depender
-- do cliente conseguir fazer um insert antes de existir sessão/RLS liberada.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_data (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Mantém updated_at em dia a cada UPDATE (útil pra debug/auditoria, não usado pelo app ainda).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger user_data_set_updated_at
  before update on public.user_data
  for each row execute function public.set_updated_at();
