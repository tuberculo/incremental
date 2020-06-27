FatorPCH <- VazDiaria[VazDiaria$Posto %in% c(34, 94, 254, 277), ]
FatorPCH <- left_join(FatorPCH, tibble(Usina = unique(FatorPCH$Nome), Subsistema = c("Norte", "Sul", "Sudeste", "Nordeste")), by = c("Nome" = "Usina"))
FatorPCH <- mutate(FatorPCH, YEAR = year(Data), MONTH = month(Data), DAY = day(Data))
FatorPCH <- mutate(group_by(FatorPCH, Subsistema, MONTH), VazMedMens = mean(Vazao), fator = Vazao / VazMedMens)
FatorPCH <- pivot_wider(FatorPCH, names_from = Subsistema, values_from = fator, id_cols = c(YEAR, MONTH, DAY))
FatorPCH <- mutate(FatorPCH, across(where(is.double), round, 3))
write.table(FatorPCH, paste0("FatorPCH.tsv"), sep = "\t", dec = ",", row.names = FALSE, quote = FALSE)

Arquivo <- "C:/Users/malta/AppData/Local/Temp/~PLEXOS/0b9c23e3-de92-43ff-a02f-e17c98e4a6c4/Entradas/Vazoes/FatorPCH - Copia.tsv"
dados <- read_tsv(Arquivo, locale = locale(decimal_mark = ","))

novoFator <- bind_rows(dados, mutate(dados, YEAR = YEAR + (2018 - 1982) + 1))
#Remove os dias bissextos nos anos errados.
novoFator <- drop_na(mutate(novoFator, Data = ymd(paste0(YEAR, "/", MONTH, "/", DAY))))
novoFator <- select(novoFator, -Data)
write.table(novoFator, paste0("FatorPCH.tsv"), sep = "\t", dec = ",", row.names = FALSE, quote = FALSE)


FatorPCH <- mutate(group_by(FatorPCH, Subsistema), porMed = Vazao / mean(Vazao), FC = Vazao / max(Vazao))
summarise(group_by(FatorPCH, Subsistema, mes), média = mean(FC))
colMeans(FatorPCH[-1])
