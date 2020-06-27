FatorPCH <- VazDiaria[VazDiaria$Posto %in% c(34, 94, 254, 277), ]
FatorPCH <- left_join(FatorPCH, tibble(Usina = unique(FatorPCH$Nome), Subsistema = c("Norte", "Sul", "Sudeste", "Nordeste")), by = c("Nome" = "Usina"))
FatorPCH <- mutate(FatorPCH, YEAR = year(Data), MONTH = month(Data), DAY = day(Data))
FatorPCH <- mutate(group_by(FatorPCH, Subsistema, MONTH), VazMedMens = mean(Vazao), fator = Vazao / VazMedMens)
FatorPCH <- pivot_wider(FatorPCH, names_from = Subsistema, values_from = fator, id_cols = c(YEAR, MONTH, DAY))
FatorPCH <- mutate(FatorPCH, across(where(is.double), round, 3))
write.table(FatorPCH, paste0("FatorPCH.tsv"), sep = "\t", dec = ",", row.names = FALSE)



FatorPCH <- mutate(group_by(FatorPCH, Subsistema), porMed = Vazao / mean(Vazao), FC = Vazao / max(Vazao))
summarise(group_by(FatorPCH, Subsistema, mes), média = mean(FC))
colMeans(FatorPCH[-1])
