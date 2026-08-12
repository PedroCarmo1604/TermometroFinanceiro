-- Termômetro Financeiro — bucket de fotos de perfil (Supabase Storage)
-- Rodar uma vez em: Supabase Dashboard > SQL Editor > New query > colar tudo > Run.
-- Complementa o schema.sql (auth + dados); aqui é só o armazenamento das fotos de avatar.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Leitura pública (a foto de perfil aparece no header do app, sem precisar de token) —
-- mas escrita/troca/remoção só pelo dono, restrita ao próprio prefixo "{user_id}/..." no path.
create policy "avatar public read"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatar own insert"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "avatar own update"
  on storage.objects for update
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "avatar own delete"
  on storage.objects for delete
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
