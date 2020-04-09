source("calc_incr.R")
source("importa vazões.R")


# Preparação de dados -----------------------------------------------------

# Lê arquivo com cascata
cascata_PDE_2029 <- read_delim("cascata - PDE 2029.csv", ";", escape_double = FALSE, locale = locale(date_names = "pt", decimal_mark = ",", grouping_mark = "."), trim_ws = TRUE)
#cascata_PDE_2022 <- read_delim("cascata - PDE 2022.csv", ";", escape_double = FALSE, locale = locale(date_names = "pt", decimal_mark = ",", grouping_mark = "."), trim_ws = TRUE)


#  Tempo de viagem
# Do arquivo texto:
TempoViagem <- read_fwf("tempo de viagem.txt", fwf_widths(c(6, 3, 4, 3, 6, 3), col_names = c("cod", "Montante", "Jusante", "tp", "TempViag", "tpTVIAG")), skip = 2)
# Da planilha:
TempoViagem <- read_xlsx("Tempo-de-Viagem-Plexos.xlsx", 1, col_types = c("numeric", "text", "numeric", "text", "skip", "skip", "numeric", "skip", "skip", "skip", "skip", "skip", "skip", "skip", "skip", "skip"), col_names = c("Montante", "NomeMontante", "Jusante", "NomeJusante", "TempViag"), skip = 4)
TempoViagem <- select(TempoViagem, Montante, Jusante, TempViag)

NomesPlexos <- read_xlsx("Tempo-de-Viagem-Plexos.xlsx", 2)

# Altera a tabela de cascata para o formato longo
#casc2022longa <- PreparaTabelaCascata(cascata_PDE_2022)
casc2029longa <- PreparaTabelaCascata(cascata_PDE_2029)
#  Inclui nome do reservatório usado no Plexos
casc2029longa <- rename(left_join(casc2029longa, select(NomesPlexos, -Bacia), by = c("num" = "Num PDE")), NomePlexos = Reservatório)

# Cálculo com vazões mensais -----------------------------------------------
  #ArquivoVazoes2022 <- "vazao-pde2022.txt" # Arquivo vazões no formato Newave
  ArquivoVazoes2029 <- "vazoes2029.txt"
  # Carrega vazões do arquivo Newave
  #Vazoes2022Mensal <- read_fwf(ArquivoVazoes2022, fwf_empty(ArquivoVazoes2022, 
  #  col_names = c("Posto", "Ano", 1:12), n = 10000L), col_types = cols(.default = "d"))
  Vazoes2029Mensal <- read_fwf(ArquivoVazoes2029, fwf_empty(ArquivoVazoes2029, 
    col_names = c("Posto", "Ano", 1:12), n = 10000L), col_types = cols(.default = "d"))
  
  # Muda para formato longo e adiciona coluna com data
  #Vazoes2022Mensal <- pivot_longer(Vazoes2022Mensal, cols = c(-Posto, -Ano), names_to = "Mes", values_to = "Vazao")
  #Vazoes2022Mensal <- mutate(unite(Vazoes2022Mensal, Ano, Mes, col = data, remove = FALSE), Data = parse_date_time(data, "Ym"), data = NULL)
  
  Vazoes2029Mensal <- pivot_longer(Vazoes2029Mensal, cols = c(-Posto, -Ano), names_to = "Mes", values_to = "Vazao")
  Vazoes2029Mensal <- mutate(unite(Vazoes2029Mensal, Ano, Mes, col = data, remove = FALSE), Data = parse_date_time(data, "Ym"), data = NULL)
  
  # Calcula incremental
  #Vaz2022MensalIncr <- CalcIncr(Vazoes2022Mensal, casc2022longa)
  Vaz2029MensalIncr <- CalcIncr(Vazoes2029Mensal, casc2029longa)
  # Muda para formato de tabela
  #Vaz2022MensalIncrTabela <- select(mutate(Vaz2022MensalIncr, Mes = month(Data), Ano = year(Data)), Ano, Mes, Posto, VazIncr) %>% 
  #  pivot_wider(names_from = Mes, values_from = VazIncr, values_fn = list(VazIncr = sum))
  Vaz2029MensalIncrTabela <- select(mutate(Vaz2029MensalIncr, Mes = month(Data), Ano = year(Data)), Ano, Mes, Posto, VazIncr) %>% 
    pivot_wider(names_from = Mes, values_from = VazIncr, values_fn = list(VazIncr = sum))
  
  #write_csv(Vaz2022MensalIncrTabela, "VazIncr2022porMes.csv")
  write_csv(Vaz2029MensalIncrTabela, "VazIncr2029porMes.csv")

# Cálculo com vazões diárias ----------------------------------------------

# Adiciona informação do tempo de viagem na tabela de cascata
casc2029longa <- left_join(casc2029longa, TempoViagem, by = c("UsinaMontante" = "Montante", "num" = "Jusante"))
# Substitui NA por 0 quando não há informação do tempo de viagem.
casc2029longa$TempViag <- replace_na(casc2029longa$TempViag, 0)
#  casc2029longa <- mutate(casc2029longa, TempViag = 3) # Preencher certo depois

Vaz2029DiariaIncr <- CalcIncr(VazDiaria, casc2029longa)
Vaz2029DiariaIncr <- drop_na(Vaz2029DiariaIncr)
write_csv(Vaz2029DiariaIncr, "VazIncr2029porDia.csv")

ggplot(filter(Vaz2029DiariaIncr, Posto == 169, Data < as_date("1985/01/01"), Data > as_date("1983/01/01"))) + geom_line(aes(x = Data, y = VazIncrcomTV), colour = "blue") + geom_line(aes(x = Data, y = VazIncr), colour = "red") + geom_line(aes(x = Data, y = Vazao)) + geom_line(aes(x = Data, y = VazMontTotal), colour = "orange") + geom_line(aes(x = Data, y = VazMontTotalcomTV), colour = "green")

group_by(Vaz2029DiariaIncr, Nome) %>% summarise(n(), min(VazIncrcomTV), max(VazIncrcomTV), qneg = sum(VazIncrcomTV < 0), prop = min(VazIncrcomTV) / max(VazIncrcomTV)) %>% arrange(prop) %>% print(n = 200)


left_join(Vaz2029DiariaIncr, select(casc2029longa, posto, NomePlexos), by = c("Posto" = "posto")) %>% filter(is.na(NomePlexos)) %>% filter(VazMontTotal != 0) %>% distinct(Nome)
left_join(Vaz2029DiariaIncr, select(casc2029longa, posto, NomePlexos), by = c("Posto" = "posto")) %>% filter(is.na(NomePlexos)) %>% distinct(Nome) %>%  print(n = 40)