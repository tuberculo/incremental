PreparaTabelaCascata <- function(CascataEntrada) {
  cascataLonga <- pivot_longer(CascataEntrada, cols = c(`Posto montante 1`, `Posto montante 2`, `Posto montante 3`, `Posto montante 4`, `Posto montante 5`,`Posto montante 6`), values_to = "PostoMontante")
#  cascataLonga$PostoMontante <- parse_integer(gsub(999, NA, cascataLonga$PostoMontante))
#  cascataLonga <- drop_na(cascataLonga)
  cascataLonga <- cascataLonga[grep("FIC", cascataLonga$nome, invert = TRUE),] # Remove as fictícias
  cascataLonga <- distinct(left_join(cascataLonga, select(cascataLonga, UsinaMontante = num, posto), by = c("PostoMontante" = "posto"))) # Inclui o número da usina referente ao posto a montante.
  cascataLonga[cascataLonga$name == "Posto montante 1" & is.na(cascataLonga$UsinaMontante),]$UsinaMontante <- 999
  cascataLonga <- drop_na(cascataLonga)
  cascataLonga
}

CalcIncr <- function(Vazoes, Cascata) {
  #  Vazões à montante de cada posto, por posto à montante.
  VazMontante <- left_join(Cascata, Vazoes, by = c("PostoMontante" = "Posto")) %>% 
    select(Data, num, nome, posto, PostoMontante, VazãoMontante = Vazao, TempViag)
  # Total das vazões à montante de cada posto
  ## Cria lag de vazão montante
  VazMontporPosto <- group_by(drop_na(left_join(Vazoes, VazMontante, by = 
    c("Data" = "Data", "Posto" = "posto"))), Posto, PostoMontante) %>% 
    arrange(Posto, PostoMontante, Data) %>% 
    mutate(VazMontLag = lag(VazãoMontante, n = (TempViag[1] %/% 24 + 1), default = 0), 
           VazMontLagDiaSeg = lag(VazãoMontante, n = (TempViag[1] %/% 24), default = 0)) %>% 
    ungroup()
  # Faz o cálculo proporcional à quantidade de horas do dia que inicia o tempo de viagem mais o dia seguinte.
  VazMontporPosto <- group_by(VazMontporPosto, Data, Posto) %>% 
    mutate(VazMontcomTV = (((24 - TempViag %% 24) * VazMontLagDiaSeg + (TempViag %% 24) * VazMontLag) / 24)) %>% 
    summarise(VazMontTotal = sum(VazãoMontante), VazMontTotalcomTV = sum(VazMontcomTV))
  #  Junta o valor total à montante com a tabela de vazões do posto.
  Vazoes <- replace_na(left_join(Vazoes, VazMontporPosto), list(VazMontTotal = 0, VazMontTotalcomTV = 0))
  # Calcula incremental.
  Vazoes <- mutate(Vazoes, VazIncr = Vazao - VazMontTotal, VazIncrcomTV = Vazao - VazMontTotalcomTV)
  Vazoes
}

FormatoPlexos <- function(Vaz, cascata = casc2029longa, diario = FALSE) {
  Vaz <- mutate_if(Vaz, is.numeric, round, digits = 3)
  Vaz <- distinct(select(drop_na(left_join(Vaz, cascata, by = c("Posto" = "posto"))), Data, NomePlexos, VazIncrcomTV))
  Vaz <- mutate(Vaz, YEAR = year(Data), MONTH = month(Data))
  if (diario) {Vaz <- mutate(Vaz, DAY = day(Data))}
  Vaz <- pivot_wider(select(Vaz, -Data), values_from = VazIncrcomTV, names_from = NomePlexos)
}