CalcSumario <- function(VazDiaria, CascataLonga, t92 = 1, t94 = 1) {
  TempoViagem[TempoViagem$Jusante == 103 & TempoViagem$Montante == 92, "TempViag"] <- t92
  TempoViagem[TempoViagem$Jusante == 103 & TempoViagem$Montante == 94, "TempViag"] <- t94
  # Adiciona informação do tempo de viagem na tabela de cascata
  CascataLonga <- left_join(CascataLonga %>% select(!any_of("TempViag")), 
                            TempoViagem, by = c("UsinaMontante" = "Montante", "num" = "Jusante"))
  # Substitui NA por 0 quando não há informação do tempo de viagem.
  CascataLonga$TempViag <- replace_na(CascataLonga$TempViag, 0)
  
  CalcIncr(VazDiaria %>% filter(Posto %in% c(94, 92, 220)), CascataLonga) %>% 
    filter(Nome == "FOZ CHAPECO ") %>% 
    summarise(PercNeg = mean(VazIncrcomTV < 0), 
              MediaNeg = sum((VazIncrcomTV < 0) * 
                               VazIncrcomTV) / sum((VazIncrcomTV < 0)),
              Min = min(VazIncrcomTV))
}

opc <- expand_grid(tIta = 0:30, tMonj = 0:30)
saida <- bind_cols(opc, pmap_dfr(opc, ~CalcSumario(VazDiaria, CascataLonga, .x, .y))) 

pivot_longer(saida, c(PercNeg, MediaNeg, Min), names_to = "Medida", values_to = "Valor") %>% 
  ggplot() + geom_line(aes( x = tIta, y = Valor, color = factor(tMonj))) + 
  facet_wrap(~Medida, ncol = 1, scales = "free_y")

pivot_longer(saida, c(PercNeg, MediaNeg, Min), names_to = "Medida", values_to = "Valor") %>% 
  group_by(Medida) %>% summarise(min(Valor), max(Valor), which.min(Valor), which.max(Valor))
saida %>% slice(c(267, 437, 466))

saveRDS(saida, "Opções de tempo de viagem a montante de Foz do Chapecó.rds")
