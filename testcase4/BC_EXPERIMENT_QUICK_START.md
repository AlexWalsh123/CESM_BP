# Quick Reference: BC Climate Experiment

## The Goal
Measure how much global temperature increases when you add black carbon (BC) emissions to the atmosphere.

## The Method: Control vs Perturbation

```
┌─────────────────┐         ┌─────────────────┐
│  Control Run    │         │ Perturbation Run│
│  (No extra BC)  │         │ (With BC added) │
└────────┬────────┘         └────────┬────────┘
         │                            │
         │ Run 10 years               │ Run 10 years
         │                            │
         ▼                            ▼
    ┌─────────┐                  ┌─────────┐
    │ T_ctrl  │                  │ T_pert  │
    └────┬────┘                  └────┬────┘
         │                            │
         └────────────┬───────────────┘
                      │
                      ▼
              ΔT = T_pert - T_ctrl
              (Temperature change)
```

## Timeline

### Quick Version (1 year)
- **Purpose**: Get radiative forcing only
- **What you get**: Estimate of equilibrium temperature change
- **Limitation**: Ocean hasn't responded yet
- **Formula**: ΔT_eq ≈ RF × 0.8 K/(W/m²)

### Recommended (10 years)
- **Purpose**: See actual temperature response
- **What you get**: Near-equilibrium global temperature change
- **Benefit**: Real climate system response including ocean
- **Expected signal**: 0.05 - 0.5 K depending on BC emission strength

### Full Equilibrium (20+ years)
- **Purpose**: Complete climate response
- **What you get**: Fully equilibrated temperature change
- **Benefit**: Most accurate, includes all feedbacks

## Files You Need

1. **EMISSIONS_GUIDE.md** - How to create BC emission files
2. **BC_CLIMATE_EXPERIMENT_GUIDE.md** - Full experimental design (this file)
3. **create_custom_emissions.py** - Script to generate emission NetCDF files
4. **analyze_BC_temperature.py** - Script to analyze results

## Quick Start Commands

### 1. Create Emission File
```bash
cd /user/home/xz20153/work
source /user/home/xz20153/CESM_postprocessing/cesm-env2/bin/activate
python create_custom_emissions.py
```

### 2. Create Two Cases
```bash
cd /user/home/xz20153/my_cesm_sandbox

# Control (no extra BC)
cime/scripts/create_newcase --case control_noBC --compset 2000_CAM60%WCSC_CLM50%SP_CICE%PRES_DOCN%DOM_MOSART_SGLC_SWAV --res f09_g17 --mach bluepebble --run-unsupported

# Perturbation (with BC)
cime/scripts/create_newcase --case perturb_BC --compset 2000_CAM60%WCSC_CLM50%SP_CICE%PRES_DOCN%DOM_MOSART_SGLC_SWAV --res f09_g17 --mach bluepebble --run-unsupported
```

### 3. Configure Both for 10-Year Runs
```bash
cd control_noBC
./case.setup
./xmlchange STOP_N=10,STOP_OPTION=nyears

cd ../perturb_BC
./case.setup
./xmlchange STOP_N=10,STOP_OPTION=nyears
```

### 4. Add BC Emissions (Perturbation Case ONLY)
Edit `perturb_BC/user_nl_cam`:
```fortran
ext_frc_specifier = 'BC -> /user/home/xz20153/work/CESM_Input/custom_emissions.nc'
ext_frc_type = 'INTERP_MISSING_MONTHS'

fincl1 = 'TREFHT', 'TS', 'BC', 'BURDENBC', 'FSNT', 'FLNT'
```

### 5. Build and Run
```bash
cd control_noBC
./case.build && ./case.submit

cd ../perturb_BC
./case.build && ./case.submit
```

### 6. Analyze Results
After both complete:
```bash
cd /user/home/xz20153/work
# Edit analyze_BC_temperature.py to set correct file paths
python analyze_BC_temperature.py
```

## What to Expect

### Small BC Addition (e.g., 1e-10 kg/m²/s over 10° × 10°)
- BC burden: +0.01 mg/m²
- Radiative forcing: +0.05 W/m²
- Global ΔT: +0.01 to +0.05 K (hard to detect in 10 years)
- **Verdict**: May need 20+ years or ensemble runs

### Moderate BC Addition (e.g., 1e-9 kg/m²/s over 10° × 10°)
- BC burden: +0.1 mg/m²
- Radiative forcing: +0.2 to +0.5 W/m²
- Global ΔT: +0.1 to +0.2 K
- **Verdict**: Detectable in 10-year run

### Large BC Addition (e.g., 1e-8 kg/m²/s over 10° × 10°)
- BC burden: +1.0 mg/m²
- Radiative forcing: +1 to +2 W/m²
- Global ΔT: +0.5 to +1.0 K
- **Verdict**: Clear signal even in 5 years

## Key Variables to Check

### Temperature
- **TREFHT**: 2m reference temperature (what thermometers measure)
- **TS**: Surface skin temperature (instant response)

### BC Amount
- **BURDENBC**: Column burden (kg/m² or mg/m²)
- **BC**: 3D concentration field

### Radiative Impact
- **FSNT - FLNT**: Net radiation at top of atmosphere
- **AODVIS**: Aerosol optical depth (how much sunlight BC blocks)

## Common Issues

**"No temperature signal detected"**
- BC emission too small → increase emission rate
- Run too short → extend to 15-20 years
- Check BURDENBC actually increased
- Try regional temperature instead of global

**"Signal is noisy"**
- Normal! Climate has natural variability
- Average over multiple years
- Check signal-to-noise ratio (should be > 2)
- Consider ensemble runs (3-5 members)

**"BURDENBC didn't increase"**
- Check emission file path in CaseDocs/atm_in
- Verify emission file has correct variable name
- Check atm.log for errors about emissions

## References

All documentation in:
- `/user/home/xz20153/my_cesm_sandbox/testcase4/BC_CLIMATE_EXPERIMENT_GUIDE.md`
- `/user/home/xz20153/my_cesm_sandbox/testcase4/EMISSIONS_GUIDE.md`

Analysis scripts in:
- `/user/home/xz20153/work/create_custom_emissions.py`
- `/user/home/xz20153/work/analyze_BC_temperature.py`
