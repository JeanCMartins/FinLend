# FinLend Analytics - Teste Técnico (Analytics Engineer)

Fala pessoal, tudo bem? 
Neste repositório deixo a minha resolução para o case da FinLend. Abaixo detalho um pouco da minha linha de raciocínio, o diagnóstico que fiz do projeto legado e as decisões que tomei na refatoração.

## Diagnóstico do legado (O que encontrei)

Quando peguei o código, o que mais me chamou a atenção (e que explica a dor do CFO com a conta do BigQuery) foi o join com `UNNEST` no modelo `revenue_report`. Fazer isso antes de agregar os dados gera um produto cartesiano absurdo. Esse foi o problema mais crítico.

O segundo ponto crítico foi a regra de negócio do faturamento. O código estava literalmente somando `chargeback` e `refund` como se fossem receita positiva. É por isso que os números não batiam na ponta.

Por fim, no `merchant_summary`, tinha alguns erros chatos de sintaxe: um `CASE` sem o fechamento adequado e um risco claro de erro de divisão por zero no cálculo da taxa de chargeback.

## O que refatorei e por quê

Decidi focar nesses 3 pontos que citei acima, reescrevendo os modelos `revenue_report` e `merchant_summary`. 
Foi onde vi que a refatoração traria o maior retorno imediato tanto em custo quanto em confiabilidade.

* **No revenue_report:** Isolei a tabela de settlements em uma CTE separada, fiz o unnest e usei um `QUALIFY` pra garantir que a relação ficasse 1:1 antes do join principal. Também corrigi a lógica financeira: agora os refunds e chargebacks são multiplicados por -1 para refletir a saída de caixa na coluna `revenue_impact`.
* **No merchant_summary:** Troquei aquele case quebrado por um `COUNTIF` (que roda bem melhor no BQ) e coloquei um `SAFE_DIVIDE` na taxa de chargeback pra evitar que o pipeline quebre se aplicarmos algum filtro onde o lojista não tenha transações.

## Uso de IA no processo

Usei IA (LLMs) mais como um apoio de "pair programming" para agilizar a formatação da documentação e debater sobre algumas funções nativas mais limpas do BigQuery (como o SAFE_DIVIDE). 

Porém, na parte de corrigir a regra de negócio (negativar os estornos), precisei fazer a intervenção manual. A IA estava sugerindo apenas excluir as linhas com status de refund da tabela, o que daria furo na nossa auditoria e faria a gente perder o rastro da transação. 

## Próximos passos

Meu plano de ação seria:
1.  Melhorar a governança adicionando o pacote `dbt-expectations` para criar testes de anomalia nas tabelas (o schema atual está só com o básico de unique/not_null).
2.  Desenhar a orquestração via Airflow, configurando os jobs para rodar de forma incremental usando o `transaction_date`, ao invés de full refresh.
3.  Criar algumas macros em Jinja para padronizar as conversões de centavos para BRL direto na camada staging.