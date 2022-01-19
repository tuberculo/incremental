# Dados -------------------------------------------------------------------
ArquivoVazoesDiarias <- "../Vazões_Diárias_1982_2019_tripa_Completo+Exp_ADJ_r05.csv"
if (length(commandArgs(trailingOnly = TRUE)) != 0) ArquivoVazoesDiarias <- commandArgs(trailingOnly = TRUE)
ArqTV <- "P_tempo de viagem.xlsx"
ArqNomesReservat <- "NomesReservat.csv"
ArquivoVazoes <- "vazoes2030.txt" # Arquivo de vazões mensais (PDE)
ArquivoCascata <- "cascata - PDE 2030.csv"
UsaTV <- TRUE # Usa tempo de viagem?