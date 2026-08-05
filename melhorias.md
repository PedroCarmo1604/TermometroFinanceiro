# Termômetro Financeiro — Rastreio de melhorias

Documento simples pra acompanhar o que já foi feito e o que ainda falta no app, já que não temos um repositório git aqui pra servir de histórico.

> **Sobre as datas abaixo**: como nunca commitamos nada no git ao longo do projeto, as datas foram reconstruídas a partir dos checkpoints (`termometro-financeiro.checkpoint-*.html`) salvos antes de cada mudança maior — comparando o que cada um já continha. Pra período sem checkpoint entre duas mudanças, a data é uma estimativa (marcada como intervalo).

## Concluído

- **Notas do Diário não salvavam** *(até 06/07/2026)* — causa raiz era a ausência de `window.storage` fora do host original; adicionado fallback automático para `localStorage`.
- **Limpeza de código morto** *(até 06/07/2026)* — CSS não usado (`.inv-*`, `.tf-tab` duplicada) e função `updateAssetPrice` duplicada removidos.
- **Hardening de XSS** *(até 06/07/2026)* — ticker de novo ativo sanitizado na origem (`addNewAsset`), aceitando só `[A-Z0-9]`.
- **Dados pessoais removidos do código-fonte** *(até 06/07/2026)* — `SEED_DATA` (histórico real desde set/2024) e `SEED_INVESTMENTS.assets` (posições reais) zerados; app agora começa vazio em instalações novas.
- **Backup manual** *(até 06/07/2026)* — botões "Exportar backup" / "Importar backup" na aba Diário, baixam/restauram um `.json` com tudo (diário + investimentos).
- **Responsividade** *(até 06/07/2026)* — container principal deixou de ter `max-width` fixo pequeno (760px → 1800px, com padding em `clamp`); breakpoint mobile (≤640px) ajusta o termômetro, tabela do diário (scroll horizontal), grid dos cards de investimento e indicadores do dashboard.
- **Título dinâmico e favicon** *(até 06/07/2026)* — aba do navegador mostra "Termômetro Financeiro - {aba ativa}" e usa um favicon 🌡️ embutido (SVG inline, sem arquivo externo).
- **UX da Reserva de Emergência** *(06/07/2026)* — trocado o campo único "valor total" (que dividia automaticamente por um limite) por dois campos independentes: "Valor na caixinha turbo (115% CDI)" e "Valor na caixinha (100% CDI)", refletindo como o Nubank realmente funciona. Migração automática preserva o total já salvo.
- **Confirmação antes de excluir transação/provento** *(entre 06/07 e 28/07/2026)* — `deleteTx`/`deleteProv` agora pedem "sim/não" inline na própria linha do histórico, em vez de apagar na hora.
- **Estado de erro visível** *(entre 06/07 e 28/07/2026)* — `loadData`/`loadInvestments` diferenciam "sem dados ainda" de "falha real ao carregar" (inclusive JSON corrompido); no segundo caso, mostra uma tela de erro com botão "Tentar novamente" em vez de aparentar que os dados sumiram.
- **Botão de remover ativo de investimento** *(entre 06/07 e 28/07/2026)* — cada card agora tem "Remover ativo" (com confirmação), que apaga o card, histórico de aportes/vendas e proventos do ticker.
- **Indício visual para notas** *(28/07/2026)* — texto de dica explicando o clique direito/toque longo, mais um ícone sutil (📝) que aparece ao passar o mouse em qualquer célula do diário sem nota, sinalizando que dá pra adicionar uma ali.
- **Navegação de mês mais rápida** *(28/07/2026)* — clicar no rótulo do mês (ex. "Julho de 2026") abre um seletor nativo de mês/ano pra pular direto; e um botão "Hoje" aparece sempre que você não estiver no mês atual, voltando num clique.
- **Login local com criptografia (multi-perfil)** *(30/07/2026)* — tela de login (usuário+senha) antes do app carregar. Sem servidor: a senha vira uma chave (PBKDF2-SHA256, 210 mil iterações) que criptografa os dados (AES-GCM 256) salvos neste navegador. Cada perfil é isolado; a mesma senha sempre recupera os mesmos dados no mesmo navegador; senha errada não descriptografa (e não tem como recuperar se esquecer — é criptografia de verdade, não um cadeado decorativo). Dados que já existiam antes dessa mudança foram migrados automaticamente pro primeiro perfil criado. Só funciona no mesmo navegador/dispositivo onde os dados foram salvos — não sincroniza entre aparelhos (ver backlog abaixo).
- **Redesign visual "Nocturne"** *(31/07/2026)* — aplicada a linguagem visual de um projeto de design feito no claude.ai/design (paleta azul-escura + acento único blurple `#9184D9`, tipografia Inter em todo o app no lugar de IBM Plex Sans/Mono + Fraunces, títulos em peso 500, botões de ação primária contornados em vez de preenchidos — regra explícita do sistema "nunca flood de cor sólida"). Verde/vermelho foram mantidos pra ganho/perda financeira e o gradiente do termômetro, por decisão consciente de manter a legibilidade semântica do dinheiro (o próprio mockup de referência fez a mesma escolha). Aplicado trocando os *valores* das variáveis CSS já centralizadas no `:root`, sem reescrever a estrutura — baixo risco de quebrar layout/responsividade.
- **Refinamento da tabela do Diário pra bater com o mockup** *(31/07/2026)* — as bordas entre as linhas ganharam o efeito de esmaecer nas pontas (assinatura visual do Nocturne, em vez de uma linha sólida de ponta a ponta), o número do dia passou a usar a cor de destaque em vez de cinza, e o saldo do dia ficou em negrito com a cor de texto principal em vez de cinza. De brinde, corrigidos dois tons cinza-azulados que tinham ficado hardcoded da paleta antiga (bordas do histórico de transações e o destaque da linha "hoje") e escaparam da troca de variáveis.

## Correções de bugs

- **"›" às vezes voltava pro mês atual em vez de avançar** *(30/07/2026)* — regressão introduzida pelo botão "Hoje": ele ficava posicionado *depois* do "›", então sua aparição/desaparição empurrava o "›" (mudança de layout no flexbox), e um segundo clique rápido na mesma posição da tela acabava caindo em cima do "Hoje" em vez do "›". Corrigido movendo o botão "Hoje" para o início da barra, antes do "‹" — como o rótulo do mês tem `flex:1` entre "‹" e "›", qualquer elemento adicionado antes dele não afeta a posição do "›" (só a do "‹", que é onde faz sentido o botão morar, já que "voltar" também fica à esquerda).
- **Login "perdia" dados ao digitar o mesmo usuário de formas diferentes** *(30/07/2026)* — a normalização de usuário só tirava espaços das pontas e colocava em minúsculo, então "pedropaulo", "pedro paulo" e "pedrocarmo" viravam três perfis distintos (cada um vazio, exceto o primeiro digitado, que recebeu a migração dos dados antigos). Nenhum dado foi apagado — ficaram "esquecidos" em perfis diferentes. Corrigido: normalização agora remove todos os espaços (não só das pontas), centralizada numa única função usada em login e num aviso ao vivo no formulário que mostra "perfil já existe" ou "vai criar um perfil novo" antes de você confirmar. Também parei de engolir silenciosamente erros na migração de dados antigos — se falhar, agora avisa em vez de deixar a conta parecer vazia sem explicação.

## Limpeza de dados no navegador *(30/07/2026)*

Depois de confirmar que o perfil `pedropaulo` estava com os dados corretos (migração bem-sucedida), removemos do `localStorage` os resíduos deixados pelo bug de normalização e pela migração:
- **3 perfis vazios** criados por variações de digitação do mesmo usuário (`pedro carmo`, `pedrocarmo`, `pedro paulo`) — removidos, sem conter dado real algum.
- **Dados antigos em texto puro** (`months-data` e `investments-data` sem prefixo de usuário, de antes do login existir) — já estavam migrados/criptografados no perfil `pedropaulo`, então essa cópia sem senha era redundante e reduzia o propósito da criptografia. Backup salvo em [termometro-legacy-backup.json](termometro-legacy-backup.json) antes de remover, verificado byte a byte (comparação de tamanho ao vivo no navegador vs. arquivo baixado) pra garantir que nada se perdeu.

## Backlog (identificado, não priorizado ainda)

**Viabilidade para testes assistidos**
- Testes automatizados para as funções de cálculo (`evalSum`, `recomputePosition`, `computeSaldoForDay`) e para as migrações de schema já existentes.
- Sincronização entre abas (hoje, duas abas abertas podem se sobrescrever silenciosamente via `localStorage`).
- Lembrete de backup (nenhum aviso de "faz tempo que você não exporta").

**Ideia futura: acesso de qualquer dispositivo**
- Login "de verdade" com os mesmos dados aparecendo em qualquer computador/celular após autenticar — exige sair do formato de arquivo único e construir um backend (servidor + banco de dados + senha com hash seguro no servidor, tipo bcrypt/argon2) com hospedagem própria. Mudança grande de arquitetura, decidimos adiar e ficar por enquanto só com o login local criptografado (item acima).

**Experiência do usuário**
- Validação perceptível de entrada numérica (`evalSum` converte texto inválido em `0` silenciosamente).
- Acessibilidade básica (`aria-label` só existe no botão de tema; resto dos botões/ícones não tem texto alternativo).
- Validar responsividade mobile num navegador/dispositivo real (mudanças de CSS feitas mas nunca testadas ao vivo).
- **Revisar os "Big Numbers" da aba Investimentos** *(identificado em 31/07/2026)* — hoje são 4 pills: "Investido" (custo de aquisição = qtd atual × preço médio), "Valor atual" (qtd × preço de mercado), "Rentabilidade" (retorno % ponderado pelo valor da carteira) e "+ Reserva" (na verdade mostra `Valor atual + Reserva`, mas o rótulo parece uma instrução de soma em vez de nomear a métrica — é o pill confuso). Rever pelo menos o rótulo/apresentação do 4º pill (ex: renomear pra "Patrimônio em investimentos"), e considerar deixar mais explícita a fórmula de cada número (ex: via subtítulo ou tooltip), já que "Investido" também pode confundir quem espera ver o total histórico aportado em vez do custo do que ainda está na carteira.