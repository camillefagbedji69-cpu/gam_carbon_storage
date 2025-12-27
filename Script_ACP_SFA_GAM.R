library(terra)
library(landscapemetrics)
library(sf)
library(raster)
library(spdep)
library(tidyr)
library(dplyr)
library(exactextractr)
library(FactoMineR)
library(factoextra)

##importation des données 

raster_lulc <- rast("~/Mémoire Master 2025-2026/Data_folder/Rasters/Reproject_raster.tif")

raster_carbon <- rast("~/Mémoire Master 2025-2026/Data_folder/Workflow_test/c_storage_bas.tif")


raster_variable <- rast("~/Mémoire Master 2025-2026/Data_folder/Rasters/Multiband_reproject.tif")

region <- st_read("~/L2 AGRN 2022/Vecteurs/SitePK/site_Parakou.shp")

##grille 

grille <- st_make_grid(region, cellsize = 2000, square = TRUE)

grille <- st_sf(plot_id = 1:length(grille), geometry = grille)

##sample lsm 

extraction <- sample_lsm(raster_lulc, grille, 
                         what = c('lsm_l_shdi','lsm_c_pland'))


##filtre 

data_proportion <- extraction %>% 
  select(metric, value, plot_id, class) %>% 
  filter(metric == "pland") %>% 
  pivot_wider(id_cols = plot_id, names_from = class, 
              values_from = value) %>%
  unnest(cols = everything()) ##Proportion des LULC 


data_unique <- extraction %>%
  select(metric,value, plot_id) %>% 
  filter(metric == "shdi") %>%
  pivot_wider(id_cols = plot_id, names_from = metric, 
              values_from = value) %>% 
  unnest(cols = everything())


##extraction des variables 

data_variables <- exact_extract(raster_variable,grille, fun = 'mean',
                                progress = TRUE, append_cols = "plot_id")


data_carbone <- exact_extract(raster_carbon, grille, 
                              fun = "sum",progress =TRUE, append_cols = "plot_id")

data_carbone <- as.data.frame(data_carbone)


##jointure 

data_final <- data_carbone %>% 
  left_join(data_unique, by = "plot_id") %>% 
  left_join(data_proportion, by = "plot_id") %>% 
  left_join(data_variables, by = "plot_id")


data_final <- data_final %>% 
  select(plot_id, sum, shdi, `10`, `50`,`40`, mean.Multiband_reproject_1,
         mean.Multiband_reproject_2, mean.Multiband_reproject_3,mean.Multiband_reproject_15)


##renommeer 

data_final <- data_final %>% 
  rename(tree_prop = `10`, built_prop = `50`, 
         crop_prop = `40`, NDVI = mean.Multiband_reproject_1, 
         NDWI = mean.Multiband_reproject_2, 
         LST = mean.Multiband_reproject_3,
         precip = mean.Multiband_reproject_15, 
         Carbon = sum
  )


##remplacement des NA par zéro 

df <- data_final %>% 
  mutate(across(everything(), 
                ~replace_na(.x, 0)))

##mettre les variables en log

df$lnCarbon <-log(df$Carbon)

log_vars <- c("LST", "precip")

for(v in log_vars) df[[paste0("ln", v)]] <- log(df[[v]])



df_use <- df[, c(3:8, 10, 12:13)]



pca <- PCA(df_use, scale.unit = TRUE, graph = FALSE)


summary(pca)

fviz_pca_var(pca)

##extraction des coordonnées 

pc_scores <- as.data.frame(pca$ind$coord)

carbon <- df$lnCarbon

data_pca <- cbind(carbon, pc_scores)

##OLS 


ols_pc <- lm(carbon~ ., data = data_pca)

vif(ols_pc)

##matrice de contiguité et test de Moran

nb <- poly2nb(grille) ##VOISINS 

lw <- nb2listw(nb, style = "W", zero.policy = TRUE) ##PROXIMITE MATRICE

lw_ssfa <- listw2mat(lw) ##matrice carré 

moran.test(data_pca$carbon, lw, zero.policy = TRUE) ##test de Moran

ssfa_c <- ssfa(carbon ~., data = data_pca, data_w = lw_ssfa) ##ssfa 

##
grille$efficience <- eff.ssfa(ssfa_c) ##colonne grille

plot(grille["efficience"]) ##graphique d'efficience

## SFA 

sfa_acp  <- sfa(carbon ~., data = data_pca)

summary(sfa_acp)

## efficience 

data_pca$efficience  <- efficiencies(sfa_acp)


##histogramme 

hist(data_pca$efficience)

##GAM 

gam1 <- gam(carbon ~ 
              s(Dim.1, k = 10, bs = "tp") +
              s(Dim.2, k = 8,  bs = "tp") +
              s(Dim.3, k = 8,  bs = "tp") +
              s(Dim.4, k = 6,  bs = "tp") +
              s(Dim.5, k = 6,  bs = "tp"),
            data = data_pca,
            method = "REML",
            select = TRUE) 
summary(gam1)

##graphique

p1 <- draw(gam1, select = 1) + ggtitle("Effet du gradient hydro-thermique (Dim.1)")
p2 <- draw(gam1, select = 2) + ggtitle("Structure du paysage (Dim.2)")
p3 <- draw(gam1, select = 3) + ggtitle("Pression anthropique (Dim.3)")
p4 <- draw(gam1, select = 4) + ggtitle("Gradient topographique (Dim.4)")
p5 <- draw(gam1, select = 5) + ggtitle("Variabilité locale (Dim.5)")
