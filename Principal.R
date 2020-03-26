source("calc_incr.R")
source("importa vazões.R")

# Lê arquivo com cascata
cascata_PDE_2029 <- read_delim("cascata - PDE 2029.csv", ";", escape_double = FALSE, locale = locale(date_names = "pt", decimal_mark = ",", grouping_mark = "."), trim_ws = TRUE)
cascata_PDE_2022 <- read_delim("cascata - PDE 2022.csv", ";", escape_double = FALSE, locale = locale(date_names = "pt", decimal_mark = ",", grouping_mark = "."), trim_ws = TRUE)

ArquivoVazoes2022 <- "vazao-pde2022.txt" # Arquivo vazões no formato Newave
ArquivoVazoes2029 <- "vazoes2029.txt"

# Carrega vazões do arquivo Newave
Vazoes2022Mensal <- read_fwf(ArquivoVazoes2022, fwf_empty(ArquivoVazoes2022, 
  col_names = c("Posto", "Ano", 1:12), n = 10000L), col_types = cols(.default = "d"))
Vazoes2029Mensal <- read_fwf(ArquivoVazoes2029, fwf_empty(ArquivoVazoes2029, 
  col_names = c("Posto", "Ano", 1:12), n = 10000L), col_types = cols(.default = "d"))

# Muda para formato longo e adiciona coluna com data
Vazoes2022Mensal <- pivot_longer(Vazoes2022Mensal, cols = c(-Posto, -Ano), names_to = "Mes", values_to = "Vazao")
Vazoes2022Mensal <- mutate(unite(Vazoes2022Mensal, Ano, Mes, col = data, remove = FALSE), Data = parse_date_time(data, "Ym"), data = NULL)

Vazoes2029Mensal <- pivot_longer(Vazoes2029Mensal, cols = c(-Posto, -Ano), names_to = "Mes", values_to = "Vazao")
Vazoes2029Mensal <- mutate(unite(Vazoes2029Mensal, Ano, Mes, col = data, remove = FALSE), Data = parse_date_time(data, "Ym"), data = NULL)

# Altera a tabela de cascata para o formato longo
casc2022longa <- PreparaTabelaCascata(cascata_PDE_2022)
casc2029longa <- PreparaTabelaCascata(cascata_PDE_2029)
casc2029longa <- casc2029longa[grep("FIC", casc2029longa$nome, invert = TRUE),] # Remove as fictícias

casc2029longa <- mutate(casc2029longa, TempViag = 3) # Preencher certo depois

# Calcula incremental
Vaz2022MensalIncr <- CalcIncr(Vazoes2022Mensal, casc2022longa)
Vaz2029MensalIncr <- CalcIncr(Vazoes2029Mensal, casc2029longa)
# Muda para formato de tabela
Vaz2022MensalIncrTabela <- select(mutate(Vaz2022MensalIncr, Mes = month(Data), Ano = year(Data)), Ano, Mes, Posto, VazIncr) %>% 
  pivot_wider(names_from = Mes, values_from = VazIncr, values_fn = list(VazIncr = sum))
Vaz2029MensalIncrTabela <- select(mutate(Vaz2029MensalIncr, Mes = month(Data), Ano = year(Data)), Ano, Mes, Posto, VazIncr) %>% 
  pivot_wider(names_from = Mes, values_from = VazIncr, values_fn = list(VazIncr = sum))

write_csv(Vaz2022MensalIncrTabela, "VazIncr2022porMes.csv")
write_csv(Vaz2029MensalIncrTabela, "VazIncr2029porMes.csv")

Vaz2029DiariaIncr <- CalcIncr(VazDiaria, casc2029longa)
Vaz2029DiariaIncr <- drop_na(Vaz2029DiariaIncr)
write_csv(Vaz2029DiariaIncr, "VazIncr2029porDia.csv")
