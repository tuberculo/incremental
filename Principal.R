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

source("Dados.R", encoding = "UTF-8") # Carrega dados e nome dos arquivos
source("calc_incr.R", encoding = "UTF-8") # Carrega funções.
# Lê vazões. --------------------------------------------------------------
VazDiaria <- read_csv2(ArquivoVazoesDiarias, 
                       locale = locale(encoding = guess_encoding(ArquivoVazoesDiarias)[[1]]))
VazDiaria$Data <- parse_date_time(VazDiaria$Data, c("mdy", "Ymd", "dmY"))

VazDiaria <- pivot_longer(VazDiaria, cols = -Data, names_to = "Usina", values_to = "Vazao") # De colunas para variável
VazDiaria <- separate(VazDiaria, Usina, into = c("Nome", "Posto"), 
                      sep = "\\((?=[[:digit:]]+\\))") # Separa nome do número do posto.
VazDiaria$Posto <- gsub("\\)", "", VazDiaria$Posto) # Retira o ")" do final do número do posto.
VazDiaria$Posto <- parse_integer(VazDiaria$Posto) # Transforma em número
VazDiaria <- drop_na(VazDiaria)

# Preparação de dados -----------------------------------------------------
# Lê arquivo com cascata
cascataPDE <- read_delim(ArquivoCascata, ";", 
                               escape_double = FALSE, 
                               locale = locale(date_names = "pt", decimal_mark = ",", grouping_mark = "."), 
                               trim_ws = TRUE)

# Insere São Domingos a montante de Porto Primavera -- Obs.: São Domingos não está no deck do PDE 2030, por isso esta parte foi comentada.
# cascataPDE[cascataPDE$num == 46, c("Quantos a montante?", "Posto montante 2")] <- list(2, 154) 
# cascataPDE <- add_row(cascataPDE, num = 153, nome = "São Domingos", 
#                             posto = 154, `Quantos a montante?` = 0, `Posto jusante` = 246, 
#                             `Posto montante 1` = 999, `Posto montante 2` = 999, `Posto montante 3` = 999, 
#                             `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
# Muda número de COMP-PAX-MOX (176) para número de Moxotó (173)
cascataPDE[cascataPDE$num == 176, "num"] <- list(173) 

SubstArtificiais <- TRUE ## Decide se usa vazões naturais ou artificiais
#  Muda os postos de artificiais para naturais de acordo com a listagem. Aplica em todas as colunas com posto no nome.
Nat_x_Art <- read_csv2("posto natural x artificial.csv")
Nat_x_Art <- mutate(Nat_x_Art, NovaNatural = ifelse(Usa_sempre | SubstArtificiais, Natural, Artificial))
cascataPDE <- mutate_at(cascataPDE, vars(contains("Posto")),
                              ~ ifelse(. %in% Nat_x_Art$Artificial, Nat_x_Art[match(., Nat_x_Art$Artificial),]$NovaNatural, .))
if (SubstArtificiais) source("InsereReservat.R")

#  Tempo de viagem
TempoViagem <- read_xlsx(ArqTV, 1, 
                         range = cell_cols("A:G"),
                         col_types = c("numeric", "text", "numeric", "text", "skip", "skip", "numeric"))
colnames(TempoViagem) <- c("Montante", "NomeMontante", "Jusante", "NomeJusante", "TempViag")
TempoViagem <- select(TempoViagem, Montante, Jusante, TempViag)
if (!UsaTV) TempoViagem$TempViag <- 0
# Lê nome das usinas usado no Plexos
NomesPlexos <- read_csv(ArqNomesReservat)
# Altera a tabela de cascata para o formato longo
CascataLonga <- PreparaTabelaCascata(cascataPDE)
#  Inclui nome do reservatório usado no Plexos
CascataLonga <- rename(left_join(CascataLonga, select(NomesPlexos, -Bacia), by = c("num" = "Num PDE")), NomePlexos = Reservatório)

# Cálculo com vazões mensais -----------------------------------------------
  
  # Carrega vazões do arquivo Newave
  VazoesMensal <- read_fwf(ArquivoVazoes, fwf_empty(ArquivoVazoes, 
    col_names = c("Posto", "Ano", 1:12), n = 10000L), col_types = cols(.default = "d"))
  
  # Muda para formato longo e adiciona coluna com data
  VazoesMensal <- pivot_longer(VazoesMensal, 
                                   cols = c(-Posto, -Ano), names_to = "Mes", values_to = "Vazao")
  VazoesMensal <- mutate(unite(VazoesMensal, Ano, Mes, 
                                   col = data, remove = FALSE), Data = parse_date_time(data, "Ym"), data = NULL)
  VazoesMensal$Mes <- parse_double(VazoesMensal$Mes)
  
  # Calcula incremental
  VazMensalIncr <- CalcIncr(VazoesMensal, 
                                mutate(CascataLonga, TempViag = 0)) # Insere coluna de tempo de viagem com valor 0 para não considerar isso no cálculo mensal.
  # Muda para formato de tabela
  VazMensalIncrTabela <- select(mutate(VazMensalIncr, 
                                           Mes = month(Data), 
                                           Ano = year(Data)), 
                                    Ano, Mes, Posto, VazIncr) %>% 
    pivot_wider(names_from = Mes, values_from = VazIncr, values_fn = list(VazIncr = sum))

# Cálculo com vazões diárias ----------------------------------------------

# Adiciona informação do tempo de viagem na tabela de cascata
CascataLonga <- left_join(CascataLonga, TempoViagem, by = c("UsinaMontante" = "Montante", "num" = "Jusante"))
# Substitui NA por 0 quando não há informação do tempo de viagem.
CascataLonga$TempViag <- replace_na(CascataLonga$TempViag, 0)

VazDiariaIncr <- CalcIncr(VazDiaria, CascataLonga)
VazDiariaIncr <- drop_na(VazDiariaIncr)
# Valores mensais a partir da média das vazões diárias.
VazMensalIncrMedia <- group_by(mutate(VazDiariaIncr, 
                                          Ano = year(Data), Mes = month(Data)), 
                                   Ano, Mes, Nome, Posto) %>% 
  summarize(VazIncrcomTV = mean(VazIncrcomTV))
VazMensalIncrMedia <-  mutate(ungroup(VazMensalIncrMedia), 
                                  Data = make_date(Ano, Mes)) 

# Muda para um posto por coluna
VazIncrMesPlexos <- FormatoPlexos(VazMensalIncr, CascataLonga, FALSE) # Valores mensais a partir do arquivo vazoes.txt.
VazIncrDiaPlexos <- FormatoPlexos(VazDiariaIncr, CascataLonga, TRUE)
VazIncrMesPlexosMedia <- FormatoPlexos(VazMensalIncrMedia, CascataLonga, FALSE)

# Cria arquivos csv
if (SubstArtificiais) NomeArq <- "Naturais" else NomeArq <- "Artificiais"
  
write_csv2(VazIncrMesPlexos, paste0("VazIncrMesPlexos_PDE", NomeArq, ".csv"))
write_csv2(VazIncrMesPlexosMedia, paste0("VazIncrMesMediaPlexos", NomeArq, ".csv"))
write_csv2(VazIncrDiaPlexos, paste0("VazIncrDiaPlexos", NomeArq, ".csv"))

# boxplot geral
VazIncrDiaPlexos %>% 
  pivot_longer(-c(YEAR, MONTH, DAY), names_to = "Reservatório", values_to = "Vazão") %>% 
  ggplot() + geom_boxplot(aes(x = Reservatório, y = Vazão)) + theme_minimal() + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
