

# Bacia do Tietê -------------------------------------------------------------------

# "Barra Bonita" <- "Edgard de Souza" <- "Alto Tietê"
#                   "Edgard de Souza" <- "Traição" <- "Billings + Pedreira"
#                                        'Traição" <- "Guarapiranga"

## Edgard de Souza a montante de Barra Bonita.("EDGARD DE SOUZA+TRIBUT " – posto 164)
cascataPDE[cascataPDE$nome == "BARRA BONITA", c("Quantos a montante?", "Posto montante 1")] <- list(1, 164) # Muda usinas a montante
cascataPDE <- add_row(cascataPDE, num = 107, nome = "Edgard de Souza", 
                      posto = 164, `Quantos a montante?` = 0, `Posto jusante` = 37, # Jusante: Barra Bonita (37). Montante: Alto Tietê/Ponte Nova (160) e Traição (104)
                      #`Posto montante 1` = 160, `Posto montante 2` = 104, `Posto montante 3` = 999, 
                      `Posto montante 1` = 999, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                      `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
# 
# cascataPDE <- add_row(cascataPDE, num = 105, nome = "Alto Tietê", #Também chamado de Ponte Nova
#                    posto = 160, `Quantos a montante?` = 0, `Posto jusante` = 161, # Jusante: Edgard de Souza (161). Montante: nada
#                    `Posto montante 1` = 999, `Posto montante 2` = 999, `Posto montante 3` = 999, 
#                    `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
# 
# cascataPDE <- add_row(cascataPDE, num = 108, nome = "Traição", 
#                    posto = 104, `Quantos a montante?` = 2, `Posto jusante` = 161, # Jusante: Edgard de Souza (161). Montante: Guarapiranga (117) e Pedreira (109)
#                    `Posto montante 1` = 117, `Posto montante 2` = 109, `Posto montante 3` = 999, 
#                    `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
# cascataPDE <- add_row(cascataPDE, num = 109, nome = "Pedreira", 
#                     posto = 109, `Quantos a montante?` = 1, `Posto jusante` = 104, # Jusante: Traição (104). Montante: Billings (118)
#                     `Posto montante 1` = 118, `Posto montante 2` = 999, `Posto montante 3` = 999, 
#                     `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
# cascataPDE[cascataPDE$num == 117, c("Posto jusante")] <- list(104) # Muda jusante de Guarapiranga para Traição
# # Muda posto de Billings para 118 ("BILLINGS "), jusante para Pedreira (109) e montante para nada.
# cascataPDE[cascataPDE$num == 118, c("posto", "Quantos a montante?", "Posto montante 1", "Posto jusante")] <- list(118, 0, 999, 109) 


# Bacia do Paraíba do Sul ----------------------------------------------------------
# (Pereira Passos) <- (Fontes) <- Lajes (202)  //~~ Ribeirão das Lajes
# (Pereira Passos) <- (Nilo Peçanha) <- (Vigário)
# Ilha dos Pombos (130) <- Simplício/Anta (129) <- Sobragi <- Picada  
#                          Simplício/Anta <- Santa Cecília (125) <- Funil < Santa Branca  //~~ Rio Paraíba do Sul
#                                            Santa Cecília (125) <- Santana (203) <- Tócos (201)  //~~ Rio Piraí
## Obs.: Não colocar nenhuma vazão para Nilo Peçanha, Fontes e Pereira Passos no Plexos.

cascataPDE[cascataPDE$num == 129, c("Quantos a montante?", "Posto montante 2")] <- list(2, 125) # Adiciona Santa Cecília a montante de Simplício.
cascataPDE <- add_row(cascataPDE, num = 125, nome = "Santa Cecília", 
                            posto = 125, `Quantos a montante?` = 2, `Posto jusante` = 129, # Jusante: Simplício (129). Montante: Funil (123) e Santana (203)
                            `Posto montante 1` = 123, `Posto montante 2` = 203, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
cascataPDE <- add_row(cascataPDE, num = 181, nome = "Santana", 
                            posto = 203, `Quantos a montante?` = 1, `Posto jusante` = 125, # Jusante: Santa Cecília (125). Montante: Tócos (201)
                            `Posto montante 1` = 201, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
cascataPDE <- add_row(cascataPDE, num = 180, nome = "Tócos", 
                            posto = 201, `Quantos a montante?` = 0, `Posto jusante` = 203, # Jusante: Santana (203). 
                            `Posto montante 1` = 999, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)

#  Substitui Ilha Solteira equivalente por Ilha Solteira e Três Irmãos. -------

cascataPDE <- add_row(cascataPDE, num = 43, nome = "Tres Irmãos", 
                            posto = 243, `Quantos a montante?` = 1, `Posto jusante` = 245, 
                            `Posto montante 1` = 242, `Posto montante 2` = 999, `Posto montante 3` = 999, 
                            `Posto montante 4` = 999, `Posto montante 5` = 999, `Posto montante 6` = 999,)
cascataPDE <- add_row(cascataPDE, num = 34, nome = "Ilha Solteira", 
                            posto = 34, `Quantos a montante?` = 5, `Posto jusante` = 245, 
                            `Posto montante 1` = 18, `Posto montante 2` = 33, `Posto montante 3` = 241, 
                            `Posto montante 4` = 99, `Posto montante 5` = 261, `Posto montante 6` = 999,)
# Muda montante de Jupiá.
cascataPDE[cascataPDE$num == 45, c("Quantos a montante?", "Posto montante 1", "Posto montante 3")] <- list(3, 243, 34)

# Inclui Apertados (Rio Piquiri) como montante de Itaipu, pois não está no Newave.
cascataPDE[cascataPDE$num == 66, c("Quantos a montante?", "Posto montante 3")] <- list(3, 578)
cascataPDE[cascataPDE$num == 578, c("Posto jusante")] <- 66 # Atualiza jusante de Apertados (não influencia no cálculo)
