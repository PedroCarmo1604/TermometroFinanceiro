-- Termômetro Financeiro — migração dos valores antigos de "diario"/"saida" pra transactions
--
-- NÃO RODAR AINDA. Só rodar quando o Claude avisar que é a hora certa (junto do deploy do
-- código novo que passa a ler diario/saida de `transactions` em vez de `months_data`).
-- Rodar bem próximo (minutos, não dias) do deploy — lançamentos feitos no intervalo entre
-- esta migração e o deploy do código novo seriam perdidos.
--
-- Pré-requisito: supabase/transactions.sql já rodado (tabela `transactions` existe).

-- 1) Conferência: quantas linhas seriam migradas (diario + saida)
select
  count(*) filter (where jsonb_typeof(dval->'diario') = 'number' and (dval->>'diario')::numeric > 0) as qtd_diario,
  count(*) filter (where jsonb_typeof(dval->'saida') = 'number' and (dval->>'saida')::numeric > 0) as qtd_saida
from user_data ud
cross join lateral jsonb_each(ud.months_data) as month_kv(mkey, mval)
cross join lateral jsonb_each(mval->'days') as day_kv(dkey, dval);

-- 2) Migração de fato — diario e saida, cada um com seu tipo, categoria "outros"
--    (não há como saber a categoria real de gasto passado; o usuário pode recategorizar
--    manualmente depois pelo popover, se quiser)
insert into transactions (user_id, date, tipo, valor, categoria, descricao)
select
  ud.user_id,
  to_date(month_kv.mkey || '-' || lpad(day_kv.dkey, 2, '0'), 'YYYY-MM-DD') as date,
  'diario' as tipo,
  (day_kv.dval->>'diario')::numeric as valor,
  'outros' as categoria,
  null as descricao
from user_data ud
cross join lateral jsonb_each(ud.months_data) as month_kv(mkey, mval)
cross join lateral jsonb_each(mval->'days') as day_kv(dkey, dval)
where jsonb_typeof(dval->'diario') = 'number'
  and (dval->>'diario')::numeric > 0

union all

select
  ud.user_id,
  to_date(month_kv.mkey || '-' || lpad(day_kv.dkey, 2, '0'), 'YYYY-MM-DD') as date,
  'saida' as tipo,
  (day_kv.dval->>'saida')::numeric as valor,
  'outros' as categoria,
  null as descricao
from user_data ud
cross join lateral jsonb_each(ud.months_data) as month_kv(mkey, mval)
cross join lateral jsonb_each(mval->'days') as day_kv(dkey, dval)
where jsonb_typeof(dval->'saida') = 'number'
  and (dval->>'saida')::numeric > 0;

-- 3) Conferência pós-migração: soma migrada de cada tipo deve bater com a soma que
--    estava no JSON pra aquele campo (compare manualmente com o total mostrado no app antigo)
select tipo, sum(valor) from transactions group by tipo;
