if (!require(readxl)) {
  install.packages("readxl")
  library(readxl)
}
if (!require(lubridate)) {
  install.packages("lubridate")
  library(lubridate)
}
if (!require(tidyverse)) {
  install.packages("tidyverse")
  library(tidyverse)
}

ArquivoVazoesDiarias <- commandArgs(trailingOnly = TRUE)
#ArquivoVazoesDiarias <- "../Vazões_Diarias_ajuste_mensal_1982_nat+art_ONS+Exp_r02.csv"
source("calc_incr.R", encoding = "UTF-8") # Carrega funções.

# Lê vazões. --------------------------------------------------------------
VazDiaria <- read_csv2(ArquivoVazoesDiarias, locale = locale(encoding = guess_encoding(ArquivoVazoesDiarias)[[1]]))
VazDiaria$Data <- parse_date_time(VazDiaria$Data, c("Ymd", "dmY"))
#VazDiaria$Data <- parse_date_time(VazDiaria$Data, c("mdY"))

VazDiaria <- pivot_longer(VazDiaria, cols = -Data, names_to = "Usina", values_to = "Vazao") # De colunas para variável
VazDiaria <- separate(VazDiaria, Usina, into = c("Nome", "Posto"), sep = "\\((?=[[:digit:]]+\\))") # Separa nome do número do posto.
VazDiaria$Posto <- gsub("\\)", "", VazDiaria$Posto) # Retira o ")" do final do número do posto.
VazDiaria$Posto <- parse_integer(VazDiaria$Posto) # Transforma em número

VazDiaria <- drop_na(VazDiaria)

# Preparação de dados -----------------------------------------------------
# Lê arquivo com cascata
cascata_PDE_2029 <- read_delim("cascata - PDE 2029.csv", ";", escape_double = FALSE, locale = locale(date_names = "pt", decimal_mark = ",", grouping_mark = "."), trim_ws = TRUE)

# Insere São Domingos a montante de Porto Primavera
cascata_PDE_2029[cascata_PDE_2029$num == 46, c("Quantos a montante?", "Posto montante 2")] <- list(2, 154) 
cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 153, nome = "São Domingos", 
                            posto = 154, `Quantos a montante?` = 0, `Posto jusante` = 246, 
                            `Posto montante 1` = 999, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
# Muda número de COMP-PAX-MOX (176) para número de Moxotó (173)
cascata_PDE_2029[cascata_PDE_2029$num == 176, "num"] <- list(173) 

SubstArtificiais <- TRUE ## Decide se usa vazões naturais ou artificiais
#  Muda os postos de artificiais para naturais de acordo com a listagem. Aplica em todas as colunas com posto no nome.
Nat_x_Art <- read_csv2("posto natural x artificial.csv")
Nat_x_Art <- mutate(Nat_x_Art, NovaNatural = ifelse(Usa_sempre | SubstArtificiais, Natural, Artificial))
cascata_PDE_2029 <- mutate_at(cascata_PDE_2029, vars(contains("Posto")), ~ ifelse(. %in% Nat_x_Art$Artificial, Nat_x_Art[match(., Nat_x_Art$Artificial),]$NovaNatural, .))
if (SubstArtificiais) source("InsereReservat.R")

#  Tempo de viagem
# Do arquivo texto:
#TempoViagem <- read_fwf("tempo de viagem.txt", fwf_widths(c(6, 3, 4, 3, 6, 3), col_names = c("cod", "Montante", "Jusante", "tp", "TempViag", "tpTVIAG")), skip = 2)
# Da planilha:
TempoViagem <- read_xlsx("Tempo-de-Viagem-Plexos.xlsx", 1, col_types = c("numeric", "text", "numeric", "text", "skip", "skip", "numeric", "skip", "skip", "skip", "skip", "skip", "skip", "skip", "skip", "skip"), col_names = c("Montante", "NomeMontante", "Jusante", "NomeJusante", "TempViag"), skip = 4)
TempoViagem <- select(TempoViagem, Montante, Jusante, TempViag)
# Lê nome das usinas usado no Plexos
NomesPlexos <- read_xlsx("Tempo-de-Viagem-Plexos.xlsx", 2)
# Altera a tabela de cascata para o formato longo
casc2029longa <- PreparaTabelaCascata(cascata_PDE_2029)
#  Inclui nome do reservatório usado no Plexos
casc2029longa <- rename(left_join(casc2029longa, select(NomesPlexos, -Bacia), by = c("num" = "Num PDE")), NomePlexos = Reservatório)

# Cálculo com vazões mensais -----------------------------------------------
  ArquivoVazoes2029 <- "vazoes2029.txt"
  # Carrega vazões do arquivo Newave
  Vazoes2029Mensal <- read_fwf(ArquivoVazoes2029, fwf_empty(ArquivoVazoes2029, 
    col_names = c("Posto", "Ano", 1:12), n = 10000L), col_types = cols(.default = "d"))
  
  # Muda para formato longo e adiciona coluna com data
  Vazoes2029Mensal <- pivot_longer(Vazoes2029Mensal, cols = c(-Posto, -Ano), names_to = "Mes", values_to = "Vazao")
  Vazoes2029Mensal <- mutate(unite(Vazoes2029Mensal, Ano, Mes, col = data, remove = FALSE), Data = parse_date_time(data, "Ym"), data = NULL)
  Vazoes2029Mensal$Mes <- parse_double(Vazoes2029Mensal$Mes)
  
  # Calcula incremental
  Vaz2029MensalIncr <- CalcIncr(Vazoes2029Mensal, mutate(casc2029longa, TempViag = 0)) # Insere coluna de tempo de viagem com valor 0 para não considerar isso no cálculo mensal.
  # Muda para formato de tabela
  Vaz2029MensalIncrTabela <- select(mutate(Vaz2029MensalIncr, Mes = month(Data), Ano = year(Data)), Ano, Mes, Posto, VazIncr) %>% 
    pivot_wider(names_from = Mes, values_from = VazIncr, values_fn = list(VazIncr = sum))

# Cálculo com vazões diárias ----------------------------------------------

# Adiciona informação do tempo de viagem na tabela de cascata
casc2029longa <- left_join(casc2029longa, TempoViagem, by = c("UsinaMontante" = "Montante", "num" = "Jusante"))
# Substitui NA por 0 quando não há informação do tempo de viagem.
casc2029longa$TempViag <- replace_na(casc2029longa$TempViag, 0)

Vaz2029DiariaIncr <- CalcIncr(VazDiaria, casc2029longa)
Vaz2029DiariaIncr <- drop_na(Vaz2029DiariaIncr)
# Valores mensais a partir da média das vazões diárias.
Vaz2029MensalIncrMedia <- group_by(mutate(Vaz2029DiariaIncr, Ano = year(Data), Mes = month(Data)), Ano, Mes, Nome, Posto) %>% summarize(VazIncrcomTV = mean(VazIncrcomTV))
Vaz2029MensalIncrMedia <-  mutate(ungroup(Vaz2029MensalIncrMedia), Data = make_date(Ano, Mes)) 

# Muda para um posto por coluna
VazIncrMesPlexos <- FormatoPlexos(Vaz2029MensalIncr, casc2029longa, FALSE) # Valores mensais a partir do arquivo vazoes.txt.
VazIncrDiaPlexos <- FormatoPlexos(Vaz2029DiariaIncr, casc2029longa, TRUE)
VazIncrMesPlexosMedia <- FormatoPlexos(Vaz2029MensalIncrMedia, casc2029longa, FALSE)

# Cria arquivos tsv
if (SubstArtificiais) NomeArq <- "Naturais" else NomeArq <- "Artificiais"
  
write_csv2(VazIncrMesPlexos, paste0("VazIncrMesPlexos_PDE", NomeArq, ".csv"))
write_csv2(VazIncrMesPlexosMedia, paste0("VazIncrMesMediaPlexos", NomeArq, ".csv"))
write_csv2(VazIncrDiaPlexos, paste0("VazIncrDiaPlexos", NomeArq, ".csv"))
