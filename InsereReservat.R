

# Bacia do Tietê -------------------------------------------------------------------

# "Barra Bonita" <- "Edgard de Souza" <- "Alto Tietê"
#                   "Edgard de Souza" <- "Traição" <- "Billings + Pedreira"
#                                        'Traição" <- "Guarapiranga"

## Edgard de Souza a montante de Barra Bonita.("EDGARD DE SOUZA+TRIBUT " – posto 161)
cascata_PDE_2029[cascata_PDE_2029$nome == "BARRA BONITA", c("Quantos a montante?", "Posto montante 1")] <- list(1, 161) # Muda usinas a montante
cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 107, nome = "Edgard de Souza", 
        posto = 161, `Quantos a montante?` = 2, `Posto jusante` = 37, # Jusante: Barra Bonita (37). Montante: Alto Tietê/Ponte Nova (160) e Traição (104)
        `Posto montante 1` = 160, `Posto montante 2` = 104, `Posto montante 3` = 999, 
        `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)

cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 105, nome = "Alto Tietê", #Também chamado de Ponte Nova
                   posto = 160, `Quantos a montante?` = 0, `Posto jusante` = 161, # Jusante: Edgard de Souza (161). Montante: nada
                   `Posto montante 1` = 999, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                   `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)

cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 108, nome = "Traição", 
                   posto = 104, `Quantos a montante?` = 2, `Posto jusante` = 161, # Jusante: Edgard de Souza (161). Montante: Guarapiranga (117) e Billings+Pedras (119)
                   `Posto montante 1` = 117, `Posto montante 2` = 119, `Posto montante 3` = 999, 
                   `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)

cascata_PDE_2029[cascata_PDE_2029$num == 117, c("Posto jusante")] <- list(104) # Muda jusante de Guarapiranga para Traição
# Muda posto de Billings para 119 ("BILLINGS+PEDRAS "), jusante para Traição (104) e montante para nada.
cascata_PDE_2029[cascata_PDE_2029$num == 118, c("posto", "Quantos a montante?", "Posto montante 1", "Posto jusante")] <- list(119, 0, 999, 104) 


# Bacia do Paraíba do Sul ----------------------------------------------------------
# (Pereira Passos) <- (Fontes) <- Lajes (202)  //~~ Ribeirão das Lajes
# (Pereira Passos) <- (Nilo Peçanha) <- (Vigário)
# Ilha dos Pombos (130) <- Simplício/Anta (129) <- Sobragi <- Picada  
#                          Simplício/Anta <- Santa Cecília (125) <- Funil < Santa Branca  //~~ Rio Paraíba do Sul
#                                            Santa Cecília (125) <- Santana (203) <- Tócos (201)  //~~ Rio Piraí
## Obs.: Não colocar nenhuma vazão para Nilo Peçanha, Fontes e Pereira Passos no Plexos.

cascata_PDE_2029[cascata_PDE_2029$num == 129, c("Quantos a montante?", "Posto montante 2")] <- list(2, 125) # Adiciona Santa Cecília a montante de Simplício.
cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 125, nome = "Santa Cecília", 
                            posto = 125, `Quantos a montante?` = 2, `Posto jusante` = 129, # Jusante: Simplício (129). Montante: Funil (123) e Santana (203)
                            `Posto montante 1` = 123, `Posto montante 2` = 203, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 181, nome = "Santana", 
                            posto = 203, `Quantos a montante?` = 1, `Posto jusante` = 125, # Jusante: Santa Cecília (125). Montante: Tócos (201)
                            `Posto montante 1` = 201, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
cascata_PDE_2029 <- add_row(cascata_PDE_2029, num = 180, nome = "Tócos", 
                            posto = 201, `Quantos a montante?` = 0, `Posto jusante` = 203, # Jusante: Santana (203). 
                            `Posto montante 1` = 999, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
