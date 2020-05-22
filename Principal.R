source("calc_incr.R")
source("importa vazões.R")

# Preparação de dados -----------------------------------------------------
# Lê arquivo com cascata
cascata_PDE_2029 <- read_delim("cascata - PDE 2029.csv", ";", escape_double = FALSE, locale = locale(date_names = "pt", decimal_mark = ",", grouping_mark = "."), trim_ws = TRUE)
#  Substitui Ilha Solteira equivalente por Ilha Solteira e Três Irmãos.
cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 43, nome = "Tres Irmãos", 
        posto = 243, `Quantos a montante?` = 1, `Posto jusante` = 245, 
        `Posto montante 1` = 242, `Posto montante 2` = 999, `Posto montante 3` = 999, 
        `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 34, nome = "Ilha Solteira", 
        posto = 34, `Quantos a montante?` = 5, `Posto jusante` = 245, 
        `Posto montante 1` = 18, `Posto montante 2` = 33, `Posto montante 3` = 241, 
        `Posto montante 4` = 99, `Posto montante 5` = 261, `Posto montante 6` = 999,)
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

VazIncrMesPlexos <- FormatoPlexos(Vaz2029MensalIncr, casc2029longa, FALSE) # Valores mensais a partir do arquivo vazoes.txt.
VazIncrDiaPlexos <- FormatoPlexos(Vaz2029DiariaIncr, casc2029longa, TRUE)
# Valores mensais a partir da média das vazões diárias.
Vaz2029MensalIncrMedia <- group_by(mutate(Vaz2029DiariaIncr, Ano = year(Data), Mes = month(Data)), Ano, Mes, Nome, Posto) %>% summarize(VazIncrcomTV = mean(VazIncrcomTV))
Vaz2029MensalIncrMedia <-  mutate(ungroup(Vaz2029MensalIncrMedia), Data = make_date(Ano, Mes)) 
VazIncrMesPlexosMedia <- FormatoPlexos(Vaz2029MensalIncrMedia, casc2029longa, FALSE)

# Cria arquivos tsv
if (SubstArtificiais) NomeArq <- "Naturais" else NomeArq <- "Artificiais"
  
write.table(VazIncrMesPlexos, paste0("VazIncrMesPlexos_PDE", NomeArq, ".tsv"), sep = "\t", dec = ",", row.names = FALSE)
write.table(VazIncrMesPlexosMedia, paste0("VazIncrMesMediaPlexos", NomeArq, ".tsv"), sep = "\t", dec = ",", row.names = FALSE)
write.table(VazIncrDiaPlexos, paste0("VazIncrDiaPlexos", NomeArq, ".tsv"), sep = "\t", dec = ",", row.names = FALSE)

ggplot(filter(Vaz2029DiariaIncr, Posto == 169, Data < as_date("1985/01/01"), Data > as_date("1983/01/01"))) + geom_line(aes(x = Data, y = VazIncrcomTV), colour = "blue") + geom_line(aes(x = Data, y = VazIncr), colour = "red") + geom_line(aes(x = Data, y = Vazao)) + geom_line(aes(x = Data, y = VazMontTotal), colour = "orange") + geom_line(aes(x = Data, y = VazMontTotalcomTV), colour = "green")
left_join(Vaz2029DiariaIncr, select(casc2029longa, posto, NomePlexos), by = c("Posto" = "posto")) %>% filter(is.na(NomePlexos)) %>% distinct(Nome) %>%  print(n = 40)

group_by(Vaz2029DiariaIncr, Nome) %>% summarise(n(), min(VazIncrcomTV), max(VazIncrcomTV), qneg = sum(VazIncrcomTV < 0), prop = min(VazIncrcomTV) / max(VazIncrcomTV)) %>% arrange(prop) %>% print(n = 200)
left_join(Vaz2029DiariaIncr, select(casc2029longa, posto, NomePlexos), by = c("Posto" = "posto")) %>% filter(is.na(NomePlexos)) %>% filter(VazMontTotal != 0) %>% distinct(Nome)

left_join(group_by(mutate(VazDiaria, mes = month(Data), ano = year(Data)), Posto, ano, mes) %>% summarise(mean(Vazao)), filter(Vazoes2029Mensal, Ano >= 1982), by = c("ano" = "Ano", "mes" = "Mes"))
#  Calcula diferença entre vazões mensal e diária
left_join(group_by(mutate(VazDiaria, mes = month(Data), ano = year(Data)), Posto, ano, mes) %>% summarise(VazD = mean(Vazao)), filter(Vazoes2029Mensal, Ano >= 1982), by = c("ano" = "Ano", "mes" = "Mes", "Posto" = "Posto")) %>% mutate(diff = VazD - Vazao) %>% write_csv("Diferença entre vazões mensal e diária")

VazDiaria[VazDiaria$Posto == 339 & VazDiaria$Data >= as_date("1990/05/01") & VazDiaria$Data <= as_date("1990/05/31"), ]

