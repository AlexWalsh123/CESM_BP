# Measuring Climate Response to Black Carbon Emissions

## Overview: Control vs. Perturbation Experiment

To measure the temperature change from BC emissions, you need:
1. **Control run**: Baseline with no/standard BC emissions
2. **Perturbation run**: Same setup + your BC emissions
3. **Comparison**: Temperature difference between the two

## Important Timing Considerations

### BC Emissions → Temperature Response Timeline

Black carbon affects temperature through two main mechanisms:

1. **Fast response (days to weeks)**:
   - Direct aerosol radiative forcing
   - BC absorbs solar radiation → local warming
   - Changes in atmospheric heating rates

2. **Slow response (months to years)**:
   - Ocean heat uptake
   - Sea ice changes
   - Full climate system equilibration

**For global temperature change, you need AT LEAST:**
- **1-2 years** to see initial response
- **5-10 years** to approach equilibrium
- **20-30 years** for full equilibration

## Step-by-Step Experimental Design

### Step 1: Create Two Cases

#### Case 1: Control (Baseline)
```bash
cd /user/home/xz20153/my_cesm_sandbox

# Already have testcase4, but for a proper control:
/user/home/xz20153/my_cesm_sandbox/cime/scripts/create_newcase \
  --case /user/home/xz20153/my_cesm_sandbox/control_noBC \
  --compset 2000_CAM60%WCSC_CLM50%SP_CICE%PRES_DOCN%DOM_MOSART_SGLC_SWAV \
  --res f09_g17 \
  --mach bluepebble \
  --run-unsupported

cd control_noBC
./case.setup
```

#### Case 2: Perturbation (With BC)
```bash
cd /user/home/xz20153/my_cesm_sandbox

/user/home/xz20153/my_cesm_sandbox/cime/scripts/create_newcase \
  --case /user/home/xz20153/my_cesm_sandbox/perturb_BC \
  --compset 2000_CAM60%WCSC_CLM50%SP_CICE%PRES_DOCN%DOM_MOSART_SGLC_SWAV \
  --res f09_g17 \
  --mach bluepebble \
  --run-unsupported

cd perturb_BC
./case.setup
```

### Step 2: Configure Runtime

For both cases, set run length:
```bash
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=10           # 10 year run (minimum for climate signal)
./xmlchange RESUBMIT=0           # Or higher for automatic continuation

# Important: Use the same initial conditions!
./xmlchange RUN_TYPE=hybrid      # Start from same initial state
./xmlchange RUN_REFCASE=your_spinup_case  # Reference case for initial conditions
./xmlchange RUN_REFDATE=0001-01-01
```

### Step 3: Add BC Emissions to Perturbation Case ONLY

In **perturb_BC only**, edit `user_nl_cam`:

```fortran
!========================================================================
! BC Emission Experiment
!========================================================================

! Add your custom BC emissions
ext_frc_specifier = 'BC -> /user/home/xz20153/work/CESM_Input/custom_emissions.nc'
ext_frc_type = 'INTERP_MISSING_MONTHS'

! Critical: Output variables for temperature and radiative forcing
!========================================================================

! Temperature variables
fincl1 = 'T',           ! 3D temperature
         'TS',          ! Surface temperature
         'TREFHT',      ! 2m reference temperature
         'TREFHTMN',    ! Min 2m temperature
         'TREFHTMX',    ! Max 2m temperature
         
! Global mean temperature (very useful!)
         'TGCLDLWP',    ! For cloud diagnostics
         
! BC-related variables
         'BC',          ! BC concentration (3D)
         'BURDENBC',    ! BC column burden (kg/m2)
         'AEROD_v',     ! Aerosol optical depth (visible)
         'AODVIS',      ! Total aerosol optical depth
         
! Radiative forcing components
         'FLNT',        ! Net LW flux at top
         'FSNT',        ! Net SW flux at top
         'FLNTC',       ! Clear-sky net LW flux at top
         'FSNTC',       ! Clear-sky net SW flux at top
         'FLNS',        ! Net LW flux at surface
         'FSNS',        ! Net SW flux at surface
         
! Energy balance
         'FSNT-FLNT',   ! Net radiative flux at TOA
         'RESTOM',      ! TOA net radiation (if available)
         
! Precipitation (climate impact)
         'PRECT',       ! Total precipitation
         'PRECC',       ! Convective precip
         'PRECL',       ! Large-scale precip
         
! Clouds (BC affects these)
         'CLDTOT',      ! Total cloud fraction
         'CLOUD',       ! 3D cloud fraction
         'LWCF',        ! Longwave cloud forcing
         'SWCF'         ! Shortwave cloud forcing
```

### Step 4: Build and Run

For **both cases**:
```bash
cd /user/home/xz20153/my_cesm_sandbox/control_noBC
./case.build
./case.submit

cd /user/home/xz20153/my_cesm_sandbox/perturb_BC  
./case.build
./case.submit
```

---

## Analysis: Calculate Temperature Change

### Quick Method: Use CESM Postprocessing

After both runs complete:

```bash
cd /user/home/xz20153/CESM_postprocessing

# Generate time series for both cases
cd timeseries
./timeseries --caseroot /user/home/xz20153/my_cesm_sandbox/control_noBC
./timeseries --caseroot /user/home/xz20153/my_cesm_sandbox/perturb_BC

# Compare using diagnostics
cd ../diagnostics
./diagnostics --caseroot /user/home/xz20153/my_cesm_sandbox/perturb_BC \
              --control-case control_noBC
```

### Manual Analysis with Python

Create this analysis script:

```python
#!/usr/bin/env python
"""
Calculate global mean temperature difference between control and BC perturbation
"""
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt

# Load data
control_file = '/user/home/xz20153/work/archive/control_noBC/atm/hist/control_noBC.cam.h0.*.nc'
perturb_file = '/user/home/xz20153/work/archive/perturb_BC/atm/hist/perturb_BC.cam.h0.*.nc'

ds_control = xr.open_mfdataset(control_file, combine='by_coords')
ds_perturb = xr.open_mfdataset(perturb_file, combine='by_coords')

# Calculate global mean temperature
# Need to weight by grid cell area (cosine of latitude)
weights = np.cos(np.deg2rad(ds_control.lat))
weights = weights / weights.sum()

def global_mean(data, weights):
    """Calculate area-weighted global mean"""
    # Weight by latitude (approximate)
    weighted = data.weighted(weights)
    return weighted.mean(dim=['lat', 'lon'])

# Global mean surface temperature time series
temp_control = global_mean(ds_control['TS'], weights)
temp_perturb = global_mean(ds_perturb['TS'], weights)

# Temperature difference
temp_diff = temp_perturb - temp_control

# Print results
print("=" * 60)
print("Global Mean Temperature Change from BC Emissions")
print("=" * 60)
print(f"Control mean:      {temp_control.mean().values:.2f} K")
print(f"Perturbation mean: {temp_perturb.mean().values:.2f} K")
print(f"Temperature change: {temp_diff.mean().values:.3f} K")
print(f"Temperature change: {temp_diff.mean().values * 1000:.1f} mK")
print(f"Std deviation:     {temp_diff.std().values:.3f} K")
print("=" * 60)

# Plot time series
fig, axes = plt.subplots(2, 1, figsize=(12, 8))

# Panel 1: Both time series
axes[0].plot(temp_control.time, temp_control, label='Control', linewidth=2)
axes[0].plot(temp_perturb.time, temp_perturb, label='BC Perturbation', linewidth=2)
axes[0].set_ylabel('Global Mean Surface Temperature (K)', fontweight='bold')
axes[0].set_title('Temperature Response to BC Emissions', fontweight='bold', fontsize=14)
axes[0].legend()
axes[0].grid(True, alpha=0.3)

# Panel 2: Difference
axes[1].plot(temp_diff.time, temp_diff, color='red', linewidth=2)
axes[1].axhline(y=0, color='black', linestyle='--', linewidth=1)
axes[1].set_xlabel('Time', fontweight='bold')
axes[1].set_ylabel('Temperature Difference (K)', fontweight='bold')
axes[1].set_title('ΔT = Perturbation - Control', fontweight='bold')
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('/user/home/xz20153/work/BC_temperature_response.png', dpi=150)
print("\nPlot saved to: /user/home/xz20153/work/BC_temperature_response.png")
```

Save as: `/user/home/xz20153/work/analyze_BC_temperature.py`

Run it:
```bash
cd /user/home/xz20153/work
source /user/home/xz20153/CESM_postprocessing/cesm-env2/bin/activate
python analyze_BC_temperature.py
```

---

## What to Expect: Typical BC Climate Response

### Direct Effects (Fast Response - Days to Weeks)
- **Atmospheric warming**: +0.5 to +2 K locally where BC is concentrated
- **Surface dimming**: Reduced solar radiation at surface (-5 to -20 W/m²)
- **Atmospheric heating rate**: +0.1 to +0.5 K/day in BC layer

### Global Mean Temperature Change (After Equilibration)
For typical BC emission scenarios:

| BC Burden Increase | Global ΔT (K) | Regional ΔT (K) |
|-------------------|---------------|-----------------|
| Small (0.01 mg/m²) | +0.01 to +0.05 | +0.1 to +0.3 |
| Moderate (0.1 mg/m²) | +0.1 to +0.2 | +0.5 to +1.0 |
| Large (1.0 mg/m²) | +0.5 to +1.0 | +2.0 to +5.0 |

**Note**: These are rough estimates. Actual response depends on:
- Where BC is emitted (latitude, altitude)
- Season
- Co-located clouds and albedo
- Ocean/land surface below

---

## Key Output Variables to Monitor

### Temperature Metrics
1. **TS**: Skin temperature (instant response)
2. **TREFHT**: 2m temperature (what we measure)
3. **T**: 3D atmospheric temperature (vertical structure)

### Radiative Forcing
```
Radiative Forcing = (FSNT - FLNT)_perturb - (FSNT - FLNT)_control
```

Or specifically:
```
Clear-sky RF = (FSNTC - FLNTC)_perturb - (FSNTC - FLNTC)_control
```

### BC Distribution
1. **BURDENBC**: Column burden (kg/m² or mg/m²)
2. **BC**: 3D concentration
3. **AODVIS**: Aerosol optical depth (how much BC blocks sunlight)

---

## Statistical Significance

Climate noise is large! To determine if your signal is real:

### Signal-to-Noise Ratio
```
SNR = ΔT_mean / σ_control

Where:
  ΔT_mean = mean temperature difference
  σ_control = standard deviation of control run
  
Significant if SNR > 2 (roughly 95% confidence)
```

### Run Length Requirements
- **1 year**: Only see fast atmospheric response
- **5 years**: Initial ocean response
- **10 years**: Good signal for moderate-to-large BC forcing
- **20+ years**: Needed for small forcing or regional analysis

---

## Practical Example: Expected Timeline

Let's say you emit BC at 1e-9 kg/m²/s over a 10° × 10° region:

**Year 1**:
- BC burden builds up
- Local atmospheric warming: +1-2 K
- Global mean: +0.01 to +0.05 K (hard to detect in noise)

**Years 2-5**:
- Ocean starts warming
- Global mean: +0.05 to +0.15 K (becoming detectable)

**Years 5-10**:
- Approaching equilibrium
- Global mean: +0.1 to +0.2 K (clear signal)

**Years 10-20**:
- Full equilibration
- Stable global mean response

---

## Shortcut: Radiative Forcing Instead of Full Run

If 10-year runs are too expensive, calculate **radiative forcing** instead:

### 1-Year Approach
Run both cases for just **1 year** and calculate:

```python
# Radiative forcing at top of atmosphere
RF = (FSNT - FLNT)_perturb - (FSNT - FLNT)_control  # W/m²

# Estimate equilibrium temperature from RF
ΔT_eq = RF × climate_sensitivity

# Where climate_sensitivity ≈ 0.5 to 1.0 K/(W/m²) for CAM6
```

This gives you the **forcing** quickly, and you can estimate temperature change using:
```
ΔT ≈ RF × 0.8 K/(W/m²)
```

---

## Complete Workflow Summary

```bash
# 1. Create emission file
cd /user/home/xz20153/work
python create_custom_emissions.py

# 2. Create two cases
cd /user/home/xz20153/my_cesm_sandbox
# (create control_noBC and perturb_BC as shown above)

# 3. Configure for 10-year runs
cd control_noBC
./xmlchange STOP_N=10,STOP_OPTION=nyears
cd ../perturb_BC
./xmlchange STOP_N=10,STOP_OPTION=nyears

# 4. Add emissions to perturb_BC only
nano perturb_BC/user_nl_cam
# (add BC emissions as shown above)

# 5. Build and submit
cd control_noBC && ./case.build && ./case.submit
cd ../perturb_BC && ./case.build && ./case.submit

# 6. After runs complete, analyze
cd /user/home/xz20153/work
python analyze_BC_temperature.py
```

---

## Troubleshooting

**Q: Signal is too small to detect**
- Increase BC emission rate
- Run longer (20+ years)
- Look at regional temperature instead of global mean
- Check radiative forcing (easier to detect)

**Q: Results are noisy**
- Average over longer periods (annual instead of monthly)
- Use ensemble runs (3-5 members each)
- Focus on multi-year trends, not year-to-year

**Q: No temperature response despite BC increase**
- Check BURDENBC actually increased
- Verify radiative forcing is non-zero (FSNT-FLNT difference)
- Ensure ocean is responding (coupled model, not data ocean)
- May need longer integration time

---

## References

- BC climate impacts: Bond et al. (2013), JGR
- CESM diagnostics: https://www.cesm.ucar.edu/models/cesm2/atmosphere/diagnostics
- Your analysis script: `/user/home/xz20153/work/analyze_BC_temperature.py`
