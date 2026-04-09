# Notas para o consumo via IA

Deixei os modelos preparados para que o time de produto consiga plugar nas ferramentas de IA via linguagem natural.

### O que já dá pra responder de cara:
Com a modelagem atual, o agente de IA consegue responder facilmente perguntas como:
* "Qual o volume de transações Pix do lojista X no último mês?" (Puxando do `revenue_report`).
* "Quais merchants passaram da taxa de 2% de chargeback esse trimestre?" (Puxando do `merchant_summary`).
* "Quanto a FinLend faturou em taxas na última semana?" 

### Armadilhas (Como evitei que a IA tenha alucinações)
O maior risco aqui era a IA tentar calcular o faturamento somando a coluna bruta (`amount_brl`) e esquecendo de descontar os estornos. Para evitar isso, criei a coluna `revenue_impact`, que já traz o valor líquido correto mastigado. Documentei isso no `schema.yml` nas meta tags para o LLM ler.

Outro ponto: deixei a tabela `revenue_report` na granularidade de transação e consolidei as chaves de settlement. A ideia é evitar que a IA tente fazer joins complexos com a tabela raw por conta própria (o que faria a conta do BigQuery estourar de novo).

### O que falta para ficar ideal
Para termos uma camada semântica 100% à prova de balas, o ideal seria implementarmos o MetricFlow (dbt Semantic Layer). Assim a gente crava a definição das métricas (ex: o que exatamente compõe a "receita total") e a IA só consome a métrica pronta, sem precisar ficar tentando adivinhar o SQL por trás.