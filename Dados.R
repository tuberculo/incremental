# Dados -------------------------------------------------------------------
ArquivoVazoesDiarias <- "../Vazões_Diarias_ajuste_mensal_1982_nat+art_ONS+Exp_r09.csv"
if (length(commandArgs(trailingOnly = TRUE)) != 0) ArquivoVazoesDiarias <- commandArgs(trailingOnly = TRUE)
ArqTV <- "P_tempo de viagem.xlsx"
ArqNomesReservat <- "NomesReservat.csv"
ArquivoVazoes <- "vazoes2029.txt" # Arquivo de vazões mensais (PDE)
ArquivoCascata <- "cascata - PDE 2029.csv"
UsaTV <- TRUE # Usa tempo de viagem?