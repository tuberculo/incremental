
#Cria coluna com datas
Vazoes2022 <- mutate(unite(Vazoes2022, Ano, Mês, col = data, remove = FALSE), Data = parse_date_time(data, "Ym"), data = NULL)

PreparaTabelaCascata <- function(CascataEntrada) {
  cascataLonga <- pivot_longer(CascataEntrada, cols = c(`Posto montante 1`, `Posto montante 2`, `Posto montante 3`, `Posto montante 4`, `Posto montante 5`,`Posto montante 6`), values_to = "PostoMontante")
  cascataLonga$PostoMontante <- parse_integer(gsub(999, NA, cascataLonga$PostoMontante))
  cascataLonga <- drop_na(cascataLonga)
  cascataLonga
}

# Adicionar aqui função com tempo de viagem.

CalcIncr <- function(Vazoes, Cascata) {
  #  Vazões à montante de cada posto, por posto à montante.
  VazMontante <- left_join(Cascata, Vazoes, by = c("PostoMontante" = "Posto")) %>% 
    select(Data, num, nome, posto, PostoMontante, VazãoMontante = Vazao, TempViag)
  # Total das vazões à montante de cada posto
  ## Cria lag de vazão montante
  VazMontporPosto <- group_by(drop_na(left_join(Vazoes, VazMontante, by = 
    c("Data" = "Data", "Posto" = "posto"))), Posto, PostoMontante) %>% 
    arrange(Posto, PostoMontante, Data) %>% mutate(VazMontLag = lag(VazãoMontante, default = 0)) %>% ungroup()
  # Faz o cálculo proporcional
  VazMontporPosto <- group_by(VazMontporPosto, Data, Posto) %>% 
    mutate(VazMontcomTV = (((24 - TempViag) * VazãoMontante + TempViag * VazMontLag) / 24)) %>% 
    summarise(VazMontTotal = sum(VazãoMontante), VazMontTotalcomTV = sum(VazMontcomTV))
  #  Junta o valor total à montante com a tabela de vazões do posto.
  Vazoes <- replace_na(left_join(Vazoes, VazMontporPosto), list(VazMontTotal = 0))
  # Calcula incremental.
  Vazoes <- mutate(Vazoes, VazIncr = Vazao - VazMontTotal, VazIncrcomTV = Vazao - VazMontTotalcomTV)
  Vazoes
}

# Formato do vazões.dat
select(mutate(VazDiaria, Mes = month(Data), Ano = year(Data)), Ano, Mes, Posto, VazIncr) %>% 
  pivot_wider(names_from = Mes, values_from = VazIncr, values_fn = list(VazIncr = sum))




CalcIncr_velho <- function(ArquivoVazoes, Cascata){
  Vazoes <- read_fwf(ArquivoVazoes, fwf_empty(ArquivoVazoes, col_names = c("Posto", "Ano", 1:12), n = 10000L), col_types = cols(.default = "d"))
  Vazoes <- pivot_longer(Vazoes, cols = c(-Posto, -Ano), names_to = "Mes", values_to = "Vazao")
  VazJoin <- left_join(Vazoes, Cascata, by = c("Posto" = "posto"))
  
  VazComp <- Vazoes
  for (j in 1:6) {
    VazComp <- left_join(Vazoes, select(VazJoin, Ano, Mes, Posto, paste0("Posto montante ", j)), by = c("Posto" = paste0("Posto montante ", j), "Mes" = "Mes", "Ano" = "Ano")) %>% right_join(VazComp, by = c("Posto.y" = "Posto", "Mes" = "Mes", "Ano" = "Ano"))
    colnames(VazComp)[colnames(VazComp) == c("Posto", "Vazao.x")] <- c(paste0("PostoMont",j), paste0("VazaoMont",j))
    colnames(VazComp)[colnames(VazComp) == c("Posto.y", "Vazao.y")] <- c("Posto", "Vazao")
    #VazComp2022 <- left_join(VazComp2022, select(VazJoin2022, Ano, Mês, Posto, paste0("Posto montante ", j)), by = c("Posto" = paste0("Posto montante ", j), "Mês" = "Mês", "Ano" = "Ano"), suffix=c(".x",paste0(".Jus", j)))
  }
  
  VazComp <- select(VazComp, Ano, Mes, Posto, Vazao, everything()) # Reorganiza colunas
  VazComp[is.na(VazComp)] <- 0 # Troca NA por 0.
  
  VazComp$TotalMontante <- rowSums((select(VazComp, starts_with("VazaoM")))) # Soma das vazões à montante
  VazComp <- mutate(VazComp, VazIncr = Vazao - TotalMontante) # Cálculo da incremental sem considerar tempo de viagem
  VazComp
}

vaz2022 <- mutate(vaz2022, TempViagem1 = 5) # Criando tempo de viagem fictício
vaz2022 <- group_by(vaz2022, Posto)

TempoViagem1 <- distinct(select(vaz2022, Posto, TempViagem1))
filter(vaz2022, Posto == 2) %>% mutate(VazMontTV1 = lag(VazaoMont1, 5))


# Lag diferente por posto.
# Falta fazer: Para outros montantes (2 a 6). Deixar como função. Retirar coluna TempViagem1 do tibble de vazões.

temp1 <- NULL
for (p in unique(Testevaz2022$Posto)) {
  temp <- mutate(filter(Testevaz2022, Posto == p), VazaoMontTV1 = lag(VazaoMont1, filter(TempoViagem1, Posto == p)[[2]]))
  temp1 <- bind_rows(temp1, temp)
}
Testevaz2022 <- left_join(Testevaz2022, temp1)


mutate(vaz2022, VazaoMontTV1 = lag(VazaoMont1, 5)) %>% select(Ano, Mes, Posto, Vazao, VazIncr, VazaoMontTV1) %>% filter(Posto == 3)
mutate(vaz2022, VazaoMontTV1 = lag(VazaoMont1, TempViagem1))


# Formato do vazões.dat
select(VazComp, Ano, Mes, Posto, VazIncr) %>% pivot_wider(names_from = Mes, values_from = VazIncr)
