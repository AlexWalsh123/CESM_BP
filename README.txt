Guide on setting up CESM2 on the BluePebble system

############################################################

Setup config and checkout external files:

1. Clone this repo to your user area on BluePebble

2. Run the script update_cime_preserve_configs.sh (./update_cime_preserve_configs.sh)

############################################################

Generate a new run:

1. Load python (module load languages/python/3.8.20)

1. Run create_newcase with your project code  (./cime/scripts/create_newcase --case ../CESM_cases/newtest --compset FWsc2000climo --res f09_f09_mg17 --project XXXXXXXXX)

2. Navigate to the new case file 

3. Run ./case.setup

4. Run ./case.build

5. Run ./case.submit
