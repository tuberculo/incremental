library(lubridate)
library(tidyverse)
library(readxl)

CodUsinasExp <- read_csv2("código usinas expansão.csv")

VazDiariaExist <- read_xlsx("../Vazões_Diárias_1982_ONS+Exp_r01.xlsx", 1)
VazDiariaNovas <- read_xlsx("../Vazões_Diárias_1982_ONS+Exp_r01.xlsx", 2)
VazDiariaExist$Data <- parse_date_time(VazDiariaExist$Data, "dmY")

VazDiariaExist <- pivot_longer(VazDiariaExist, cols = -Data, names_to = "Usina", values_to = "Vazao")
VazDiariaExist <- separate(VazDiariaExist, Usina, into = c("Nome", "Posto"), sep = "\\((?=[:digit:]+\\))") # Separa nome do número do posto.
VazDiariaExist$Posto <- gsub("\\)", "", VazDiariaExist$Posto) # Retira o ")" do final do número do posto.
VazDiariaExist$Posto <- parse_integer(VazDiariaExist$Posto)

VazDiariaNovas <- pivot_longer(VazDiariaNovas, cols = -Data, names_to = "Usina", values_to = "Vazao")
VazDiariaNovas <- left_join(VazDiariaNovas, select(CodUsinasExp, Nome, Posto), by = c("Usina" = "Nome"))
colnames(VazDiariaNovas)[2] <- "Nome"

VazDiaria <- bind_rows("Existente" = VazDiariaExist, "Nova" = VazDiariaNovas, .id = "Tipo") %>% select(-Tipo, Tipo) # Junta existente e nova.
VazDiaria$Posto <- parse_integer(VazDiaria$Posto)

