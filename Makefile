
modeling_data: modeling_data/PFASwells1.rds modeling_data/pfoapfhxa.rds 

clean:
	rm -rf raw_data/ modeling_data/ 

.PHONY: all clean raw_data modeling_data 

# Read csv's 
modeling_data/PFASwells1.rds: scripts/read_csv.R raw_data/PFAS_Ronly.csv
	Rscript $<
modeling_data/pfoapfhxa.rds: scripts/read_csv.R raw_data/PFOAPFHXA.csv
	Rscript $<
	
# Recode 
modeling_data/PFASwells.rds: scripts/recode.R modeling_data/PFASwells1.rds modeling_data/pfoapfhxa.rds
	Rscript $< 
	
# Soil data
modeling_data/final_soildata.rds: scripts/soildata.R raw_data/actual_unique.csv raw_data/GCS Raster 1/GCSraster1.bil
	Rscript $<
	
# Business 
modeling_data/new_finalind.rds: scripts/business.R raw_data/actual_unique.csv raw_data/NH_businesses_2016
	Rscript $<

# Industries
modeling_data/final_industries.rds: scripts/industries.R modeling_data/new_finalind.rds 
	Rscript $< 
	
# Final IV (Independent Variables)
modeling_data/merged_variables.rds: scripts/finalize_iv.R raw_data/bedrock_extraction.csv raw_data/recharge.csv raw_data/precip_PFAS.csv raw_data/recharge.csv modeling_data/final_industries.rds modeling_data/final_soildata.rds modeling_data/PFASwells.rds
	Rscript $<
modeling_data/unique_ivs.rds: scripts/finalize_iv.R raw_data/bedrock_extraction.csv raw_data/recharge.csv raw_data/precip_PFAS.csv raw_data/recharge.csv modeling_data/final_industries.rds modeling_data/final_soildata.rds modeling_data/PFASwells.rds
	Rscript $<
	
# Finalize Modeling Data
modeling_data/compounds_data.rds: scripts/finalize.R modeling_data/merged_variables.rds modeling_data/unique_ivs.rds 
	Rscript $<






	
	