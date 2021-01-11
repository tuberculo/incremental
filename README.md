# incremental
Cálculo de vazão incremental a partir das vazões naturais por posto.

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
* Rscript "nome do arquivo com as vazões diárias"
