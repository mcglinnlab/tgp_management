
dir.create('../results')
dir.create('./log_files')

## perpare datasets ------------------------------------------------------------

system('Rscript ./scripts/tgp_mesonet_download.R > ./scripts/log_files/mesonet_download.log 2>&1',
       wait=FALSE)

system('Rscript ./scripts/filter_enviornmental_data.R > ./scripts/log_files/filter_envio.log 2>&1',
       wait=FALSE)

system('Rscript ./scripts/merge_management_data.R > ./scripts/log_files/merge_mang.log 2>&1',
       wait=FALSE)

system('Rscript ./scripts/extract_management_data.R > ./scripts/log_files/extract_mang.log 2>&1',
       wait=FALSE)

system('Rscript ./scripts/create_site_by_sp_matrix.R > ./scripts/log_files/site_by_sp.log 2>&1',
       wait=FALSE)

## conduct analysis ------------------------------------------------------------
## variation partitioning 
## on grid plots
system('Rscript ./scripts/tgp_grid_varpart.R > ./scripts/log_files/grid_varpart.log 2>&1', 
       wait=FALSE)

## on repeat plots
system('Rscript ./scripts/tgp_repeat_varpart.R > ./scripts/log_files/repeat_varpart.log 2>&1', 
       wait=FALSE)

## test for significance of model terms and check for residual autocorrelation
## on grid plots
system('Rscript ./scripts/tgp_grid_testpart.R > ./scripts/log_files/grid_testpart.log 2>&1', 
       wait=FALSE)

## on repeat plots
system('Rscript ./scripts/tgp_repeat_testpart.R > ./scripts/log_files/repeat_testpart.log 2>&1', 
       wait=FALSE)

## make figures ----------------------------------------------------------------
system('Rscript ./scripts/make_maps.R')
system('Rscript ./scripts/tgp_bison_partial_effect.R')