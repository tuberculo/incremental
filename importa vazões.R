library(lubridate)
library(tidyverse)
library(readxl)
VazDiariaExist <- read_xlsx("../Vazões_Diárias_1982_ONS+Exp.xlsx", 1)
VazDiariaNovas <- read_xlsx("../Vazões_Diárias_1982_ONS+Exp.xlsx", 2)
VazDiariaExist$Data <- parse_date_time(VazDiariaExist$Data, "dmY")

VazDiariaExist <- pivot_longer(VazDiariaExist, cols = -Data, names_to = "Usina", values_to = "Vazão")
VazDiariaNovas <- pivot_longer(VazDiariaNovas, cols = -Data, names_to = "Usina", values_to = "Vazão")
VazDiaria <- bind_rows("Existente" = VazDiariaExist, "Nova" = VazDiariaNovas, .id = "Tipo") %>% select(-Tipo, Tipo) # Junta existente e nova.

VazDiaria <- separate(VazDiaria, Usina, into = c("Nome", "Posto"), sep = "\\((?=[:digit:]+\\))") # Separa nome do número do posto.
VazDiaria$Posto <- gsub("\\)", "", VazDiaria$Posto) # Retira o ")" do final do número do posto.
VazDiaria$Posto <- parse_integer(VazDiaria$Posto)
