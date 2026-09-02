# Termômetro Financeiro — Como o app calcula o que mostra

Este documento explica, em linguagem de negócio (não de código), as regras que o app usa pra chegar em cada número que aparece na tela. O objetivo é você conseguir validar "essa conta está certa?" sem precisar ler JavaScript. Onde ajuda, aponto a função correspondente no `termometro-financeiro.html` entre parênteses, só como referência.

## 1. Diário — saldo do dia e do mês

**A ideia central**: cada dia do mês tem três campos — Entrada, Saída, Diário (gastos do dia a dia) — e o app deriva o saldo a partir deles, célula por célula, acumulando ao longo do mês.

- **Saldo de um dia** = saldo de abertura do mês + soma de (Entrada − Saída − Diário) de todos os dias *até aquele dia, incluindo ele* (`computeSaldoForDay`). Ou seja, o saldo do dia 15 já embute tudo que aconteceu do dia 1 ao 15 — não é "o saldo daquele dia isolado", é o saldo acumulado.
- **Desde 01/09/2026, Saída e Diário não são mais um número digitado direto** — cada um é a **soma dos itens categorizados** daquele dia e daquele campo (`txSumForDay`), guardados numa tabela separada (`transactions`, ver [decisoes.md](decisoes.md)). Clicar na célula abre um modal onde você lista os itens (valor + categoria + descrição opcional): mercado, transporte, lazer, etc. `computeSaldoForDay` não mudou a fórmula, só passou a buscar Saída/Diário desse lugar novo em vez do número que ficava salvo junto com Entrada. Entrada continua sendo um número único, sem itemização — só os dois campos de gasto ganharam essa granularidade.
- **Saldo de abertura de um mês** nunca é digitado à mão (exceto no primeiro mês do histórico, a "âncora" fixada em setembro/2024) — é sempre igual ao saldo final do mês anterior, calculado recursivamente (`getOpeningBalance`). Se você editar um lançamento de março, abril/maio/junho... todos os meses seguintes recalculam a abertura automaticamente, em cascata, na próxima vez que forem abertos. Não existe um número "congelado" que pode ficar desatualizado.
- **Performance do mês** = Entradas − Saída Total, onde Saída Total = Saída + Diário. Ou seja, "Diário" (gastos do dia a dia) conta como saída pra fins de performance, mesmo aparecendo como um pill separado na tela.

### O campo aceita contas, não só números

Quando você digita algo como `50+30-10` num campo de Entrada/Saída/Diário, o app soma isso sozinho (`evalSum`) — não precisa calcular fora e digitar só o resultado. Ele reconhece `+`, `-`, vírgula ou ponto como separador decimal, e ignora espaços. Pedaços que não reconhece como número (`abc`, `R$100`, `12x`) são silenciosamente tratados como zero *na conta*, mas o app avisa via toast que aquele pedaço foi ignorado — pra você não achar que ele "somou tudo" quando na verdade descartou uma parte.

### O termômetro (medidor visual)

A barra vertical com gradiente (vermelho na base → azul no topo) é só uma representação visual do saldo do dia, numa escala fixa de R$0 a R$1.500 (`gaugeColorStop`): saldo ≤ R$0 pinta a barra toda na cor "quente" (vermelho), saldo ≥ R$1.500 pinta toda na cor "fria" (azul, cor de destaque do app), e valores no meio interpolam suavemente entre as duas. Não é uma meta nem um limite configurável — é uma escala de referência fixa, pensada pra dar uma leitura rápida de "tá indo bem ou mal", não um valor calculado a partir dos seus dados históricos.

## 2. Investimentos — posição, preço médio e rentabilidade

**A ideia central**: você não digita "quantidade atual" nem "preço médio atual" de um ativo — só registra cada compra/venda que fez, com data, quantidade e preço. O app reconstrói a posição atual a partir desse histórico, sempre do zero, toda vez que precisa mostrar algo (`recomputePosition`).

- **Quantidade atual** = soma de todas as compras menos soma de todas as vendas, na ordem cronológica das transações.
- **Preço médio (PM)** é recalculado a cada compra, com a fórmula clássica de custo médio ponderado: `PM novo = (quantidade antiga × PM antigo + quantidade comprada × preço pago) ÷ quantidade nova`. Uma venda **não muda o PM** — só reduz a quantidade (o custo médio do que resta continua o mesmo).
- Por que reconstruir do zero em vez de guardar "quantidade atual" direto? Porque assim, se você editar ou apagar uma transação antiga (corrigir um preço digitado errado, por exemplo), tudo recalcula certinho automaticamente — não existe risco de um valor "manual" ficar desalinhado do histórico real.

### Os quatro números do topo da aba Investimentos

- **Investido** = quantidade atual × preço médio, somado entre todos os ativos. É o custo de aquisição do que você tem *hoje* na carteira — não é a soma histórica de tudo que você já aportou (se você vendeu parte de um ativo, o custo daquela parte vendida sai da conta).
- **Valor atual** = quantidade atual × preço de mercado que você informou manualmente em cada ativo (o app não busca cotação sozinho — é você quem atualiza o preço de cada ativo).
- **Rentabilidade** = `(Valor atual − Investido) ÷ Investido`, em percentual. É uma rentabilidade **ponderada pela carteira inteira**, não a média das rentabilidades individuais de cada ativo — um ativo grande pesa mais no resultado do que um ativo pequeno.
- **Patrimônio em investimentos** = Valor atual + Reserva de emergência (turbo + normal). É o único dos quatro que inclui a reserva.

### Reserva de emergência: turbo e normal

A reserva é modelada como duas "caixinhas" independentes, espelhando como funciona de fato num banco tipo Nubank:

- **Caixinha turbo** — rende 115% do CDI, mas só até um limite (hoje R$5.000, `turboCap`). Se o valor guardado ali passar do limite, o excedente continua fisicamente na mesma caixinha, mas o app avisa visualmente que aquela parte específica rende só 100% CDI (não 115%).
- **Caixinha normal** — rende 100% do CDI, sem limite.

**Importante**: o app **não calcula o rendimento sozinho**. As taxas (115%/100% CDI) são só informativas, mostradas como texto explicativo — quem lança o rendimento de cada mês é você, manualmente, num histórico separado (`yieldLog`), somado em "Rendimentos" na tela. Não existe fórmula de juros compostos rodando por trás; é um registro manual de quanto cada caixinha efetivamente rendeu, mês a mês, segundo o extrato real do banco.

## 3. Dashboard — visão consolidada

- **Patrimônio total hoje** = saldo atual do Diário (conta corrente) + Valor atual dos investimentos + Reserva de emergência (turbo + normal). É a soma de "tudo que é seu", nas três frentes que o app acompanha.
- O medidor visual do Dashboard usa uma escala diferente da do Diário: em vez de um limite fixo (R$1.500), a escala se ajusta ao seu próprio patrimônio (30% acima do valor atual, arredondado pra cima em milhares) — porque aqui o objetivo é mostrar proporção dentro do seu próprio patrimônio, não uma referência absoluta de "saldo do dia saudável ou não".
- **Rentabilidade ponderada da carteira**, no Dashboard, é a mesma fórmula da aba Investimentos (`(Valor atual − Investido) ÷ Investido`), só reexibida num indicador dedicado.
- **"Para onde vai seu dinheiro"** (`getCategoryBreakdown`, desde 01/09/2026) — soma todos os itens categorizados de Saída **e** Diário juntos (pro usuário é o mesmo tipo de gasto, não importa qual das duas células ele veio), agrupados por categoria, dentro do período escolhido (Mês atual / Últimos 3 meses / Ano — sempre contando de hoje pra trás, não meses de calendário fechados). Cada linha do ranking mostra valor em R$ e % do total do período; categorias sem nenhum gasto no período não aparecem.

## Coisas que o app *não* faz (pra não assumir por engano)

- Não busca cotações de mercado automaticamente — todo preço de ativo é digitado por você.
- Não calcula juros/rendimento da reserva de emergência automaticamente — é lançamento manual mês a mês.
- Não projeta nem simula cenários futuros (ex: "quanto vou ter em 12 meses") — todos os números são sobre o que já aconteceu (histórico) ou o estado atual, nunca uma previsão.
- Não distingue "gasto planejado" de "gasto imprevisto" — Entrada/Saída/Diário são categorias neutras, a interpretação de "isso era esperado ou não" é sua, fora do app.
