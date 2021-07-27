# incremental
Cálculo de vazão incremental a partir das vazões naturais por posto.

## Arquivos necessários
- Arquivo csv com vazões diárias ou mensais por posto.
- Arquivo com dados de tempo de viagem, atualmente está em formato de planilha.
- Arquivo com os nomes dos reservatórios usados pelo Plexos e sua relação com a usina Newave por código.
- Arquivo com a informação de quais reservatórios estão a montante de cada usina.

Esse último arquivo é obtido a partir do arquivo confhd do Newave com o auxílio da planilha "cascata - PDE 20XX.ods" (salvar a aba "exportar como csv"). Possível melhoria: fazer essa rotina de listar usinas a montante no R em vez de planilha.

## Forma de cálculo
A vazão incremental é a vazão natural afluente do posto menos a vazão de cada posto a montante. No caso de haver tempo de viagem (dado em horas) entre um posto e outro, a vazão do posto a montante é dada pela ponderação entre o número de horas do dia que começa a contar o tempo de viagem e o número de horas restantes no dia seguinte. 

Assim, a fórmula é:

VMC = ((24 - TV mod 24) * VM[N-1] + (TV mod 24) * VM[N]) / 24))

Onde:

* VMC: Vazão a montante corrigida.
* TV: Tempo de viagem [h];
* N: Número de dias anteriores para começar a contar a vazão a montante. Dado por (int(TV/24) + 1).
* VM[N] = Vazão a montante ocorrida há N dias.
* mod: resto da divisão
* int: divisão inteira

## Como rodar
Na linha de comando:
* git clone https://github.com/tuberculo/incremental
* Rscript Principal.R "nome do arquivo com as vazões diárias"
