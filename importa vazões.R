VazDiariaExist <- read_xlsx(ArquivoVazoesDiarias, 1)
VazDiariaNovas <- read_xlsx(ArquivoVazoesDiarias, 2)
VazDiariaExist$Data <- parse_date_time(VazDiariaExist$Data, "dmY")

VazDiariaExist <- pivot_longer(VazDiariaExist, cols = -Data, names_to = "Usina", values_to = "Vazao")
VazDiariaExist <- separate(VazDiariaExist, Usina, into = c("Nome", "Posto"), sep = "\\((?=[:digit:]+\\))") # Separa nome do número do posto.
VazDiariaExist$Posto <- gsub("\\)", "", VazDiariaExist$Posto) # Retira o ")" do final do número do posto.
VazDiariaExist$Posto <- parse_integer(VazDiariaExist$Posto)

VazDiariaNovas <- pivot_longer(VazDiariaNovas, cols = -Data, names_to = "Usina", values_to = "Vazao")
VazDiariaNovas <- left_join(VazDiariaNovas, select(CodUsinasExp, Nome, Posto), by = c("Usina" = "Nome"))
colnames(VazDiariaNovas)[2] <- "Nome"
VazDiariaNovas$Data <- parse_date_time(VazDiariaNovas$Data, "dmY")


VazDiaria <- bind_rows("Existente" = VazDiariaExist, "Nova" = VazDiariaNovas, .id = "Tipo") %>% select(-Tipo, Tipo) # Junta existente e nova.
VazDiaria$Posto <- parse_integer(VazDiaria$Posto)
VazDiaria <- drop_na(VazDiaria)

