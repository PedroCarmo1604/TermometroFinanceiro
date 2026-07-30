# Termômetro Financeiro — Rastreio de melhorias

Documento simples pra acompanhar o que já foi feito e o que ainda falta no app, já que não temos um repositório git aqui pra servir de histórico.

## Concluído

- **Notas do Diário não salvavam** — causa raiz era a ausência de `window.storage` fora do host original; adicionado fallback automático para `localStorage`.
- **Limpeza de código morto** — CSS não usado (`.inv-*`, `.tf-tab` duplicada) e função `updateAssetPrice` duplicada removidos.
- **Hardening de XSS** — ticker de novo ativo sanitizado na origem (`addNewAsset`), aceitando só `[A-Z0-9]`.
- **Dados pessoais removidos do código-fonte** — `SEED_DATA` (histórico real desde set/2024) e `SEED_INVESTMENTS.assets` (posições reais) zerados; app agora começa vazio em instalações novas.
- **Backup manual** — botões "Exportar backup" / "Importar backup" na aba Diário, baixam/restauram um `.json` com tudo (diário + investimentos).
- **Responsividade** — container principal deixou de ter `max-width` fixo pequeno (760px → 1800px, com padding em `clamp`); breakpoint mobile (≤640px) ajusta o termômetro, tabela do diário (scroll horizontal), grid dos cards de investimento e indicadores do dashboard.
- **Título dinâmico e favicon** — aba do navegador mostra "Termômetro Financeiro - {aba ativa}" e usa um favicon 🌡️ embutido (SVG inline, sem arquivo externo).
- **UX da Reserva de Emergência** — trocado o campo único "valor total" (que dividia automaticamente por um limite) por dois campos independentes: "Valor na caixinha turbo (115% CDI)" e "Valor na caixinha (100% CDI)", refletindo como o Nubank realmente funciona. Migração automática preserva o total já salvo.
- **Confirmação antes de excluir transação/provento** — `deleteTx`/`deleteProv` agora pedem "sim/não" inline na própria linha do histórico, em vez de apagar na hora.
- **Estado de erro visível** — `loadData`/`loadInvestments` diferenciam "sem dados ainda" de "falha real ao carregar" (inclusive JSON corrompido); no segundo caso, mostra uma tela de erro com botão "Tentar novamente" em vez de aparentar que os dados sumiram.
- **Botão de remover ativo de investimento** — cada card agora tem "Remover ativo" (com confirmação), que apaga o card, histórico de aportes/vendas e proventos do ticker.
- **Indício visual para notas** — texto de dica explicando o clique direito/toque longo, mais um ícone sutil (📝) que aparece ao passar o mouse em qualquer célula do diário sem nota, sinalizando que dá pra adicionar uma ali.
- **Navegação de mês mais rápida** — clicar no rótulo do mês (ex. "Julho de 2026") abre um seletor nativo de mês/ano pra pular direto; e um botão "Hoje" aparece sempre que você não estiver no mês atual, voltando num clique.

## Correções de bugs

- **"›" às vezes voltava pro mês atual em vez de avançar** — regressão introduzida pelo botão "Hoje": ele ficava posicionado *depois* do "›", então sua aparição/desaparição empurrava o "›" (mudança de layout no flexbox), e um segundo clique rápido na mesma posição da tela acabava caindo em cima do "Hoje" em vez do "›". Corrigido movendo o botão "Hoje" para o início da barra, antes do "‹" — como o rótulo do mês tem `flex:1` entre "‹" e "›", qualquer elemento adicionado antes dele não afeta a posição do "›" (só a do "‹", que é onde faz sentido o botão morar, já que "voltar" também fica à esquerda).

## Backlog (identificado, não priorizado ainda)

**Viabilidade para testes assistidos**
- Testes automatizados para as funções de cálculo (`evalSum`, `recomputePosition`, `computeSaldoForDay`) e para as migrações de schema já existentes.
- Sincronização entre abas (hoje, duas abas abertas podem se sobrescrever silenciosamente via `localStorage`).
- Lembrete de backup (nenhum aviso de "faz tempo que você não exporta").

**Experiência do usuário**
- Validação perceptível de entrada numérica (`evalSum` converte texto inválido em `0` silenciosamente).
- Acessibilidade básica (`aria-label` só existe no botão de tema; resto dos botões/ícones não tem texto alternativo).
- Validar responsividade mobile num navegador/dispositivo real (mudanças de CSS feitas mas nunca testadas ao vivo).
