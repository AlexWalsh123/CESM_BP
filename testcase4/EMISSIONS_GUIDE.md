# Adding Custom Emissions to CESM/CAM

## Your Configuration
- **Compset**: `2000_CAM60%WCSC` (CAM6 with WACCM Specified Chemistry)
- **Chemistry**: Includes O3 and other chemical species
- **Aerosols**: Includes black carbon (BC), sulfate, organic carbon, etc.

## Methods for Adding Emissions

### Method 1: External Emissions Files (Recommended for Spatial/Temporal Control)

CESM uses NetCDF files for emissions that are spatially and temporally varying.

#### Quick Start Script

I've created `/user/home/xz20153/work/create_custom_emissions.py` that generates emission files for you.

**Usage:**
```bash
cd /user/home/xz20153/work
source /user/home/xz20153/CESM_postprocessing/cesm-env2/bin/activate
python create_custom_emissions.py
```

**To customize:**
Edit the script and modify these parameters:
```python
add_point_source_emission(
    species_name='BC',      # Chemical species
    lat_point=51.5,         # Latitude (-90 to 90)
    lon_point=0.0,          # Longitude (0 to 360, or use lon+360 for negative)
    emission_rate=1e-9,     # kg/m2/s (total emission)
    spread_sigma=1.0        # Spread in degrees (~111 km per degree)
)
```

#### Apply Emissions to Your Model

Once you have an emission file, add to `user_nl_cam`:

```fortran
! For surface emissions (external forcing)
ext_frc_specifier = 'BC    -> /path/to/your/custom_emissions.nc',
                    'SO2   -> /path/to/your/custom_emissions.nc',
                    'num_a1 -> /path/to/your/custom_emissions.nc'

! Alternatively, for some species use srf_emis:
srf_emis_specifier = 'BC    -> /path/to/your/custom_emissions.nc',
                     'SO2   -> /path/to/your/custom_emissions.nc'

! Set emission type
ext_frc_type = 'INTERP_MISSING_MONTHS'  ! Interpolate between months
```

Then:
```bash
cd /user/home/xz20153/my_cesm_sandbox/testcase4
./preview_namelists  # Check that emissions are applied
./case.submit
```

---

### Method 2: Using Standard CESM Emission Datasets

CESM comes with pre-configured emission inventories (CMIP6, etc.)

#### Check Current Emissions
```bash
cd /user/home/xz20153/my_cesm_sandbox/testcase4
grep -i "emis\|ext_frc" CaseDocs/atm_in
```

#### Available Species for Your Compset

For CAM6 with chemistry, common emission species:
- **Aerosols**: BC, OC (organic carbon), SO2, SO4, num_a1, num_a2, num_a3
- **Gases**: CO, NOx (NO + NO2), CH4, VOCs
- **Note**: O3 is typically **not emitted** - it's produced from photochemistry

---

### Method 3: Simple Uniform Emissions (Testing)

For quick testing, you can add uniform background emissions:

In `user_nl_cam`:
```fortran
! Add uniform surface flux (molecules/cm2/s)
! This is mainly for testing
prescribed_srf_fluxes = 'BC:1.0e8'  ! Example value
```

---

## Understanding Emission Units

### Common Unit Conversions

**Mass flux**: kg/m²/s
- This is what CESM emission files typically use
- Total emission = flux × grid cell area

**Molecular flux**: molecules/cm²/s  
- Used for some gas species
- Convert using: molecules/cm²/s = (kg/m²/s × Avogadro) / (Molecular_weight × 10)

### Example Emission Rates

For reference (these are rough estimates):

| Source Type | BC Emission | SO2 Emission |
|-------------|-------------|--------------|
| Large coal plant | ~1e-8 kg/m²/s over 1° cell | ~1e-7 kg/m²/s |
| Urban area | ~1e-9 kg/m²/s | ~5e-9 kg/m²/s |
| Wildfire (active) | ~1e-7 kg/m²/s | ~1e-8 kg/m²/s |
| Background | ~1e-12 kg/m²/s | ~1e-11 kg/m²/s |

---

## Output Variables to Track Emissions

Add these to your `fincl1/fincl2` in `user_nl_cam` to see emission impacts:

```fortran
! Aerosol concentrations and burdens
fincl1 = 'BC', 'SO4', 'SO2',
         'BURDENBC', 'BURDENSO4',
         'AODDUST', 'AODVIS',  ! Aerosol optical depth
         
! Deposition (where emissions go)
         'DF_BC', 'WD_BC',      ! Dry and wet deposition
         'DF_SO2', 'WD_SO2',
         
! For O3 (not emitted directly, but produced)
         'O3', 'O3_SRF',         ! Ozone concentration
         'TROPP_O3',             ! Tropospheric O3 column
         
! NOx chemistry (if you want to affect O3)
         'NO', 'NO2', 'HNO3'
```

---

## Important Chemistry Notes

### O3 (Ozone)
- **Cannot be directly emitted in CESM chemistry models**
- O3 is **produced photochemically** from precursors
- To increase O3, emit its **precursors**:
  - NOx (NO + NO2)
  - CO
  - Volatile Organic Compounds (VOCs)

### Black Carbon (BC)
- Direct emission works
- Tracked as aerosol mass
- Affects radiation, clouds, and deposition

### SO2 → SO4
- Emit SO2
- Model converts to SO4 (sulfate aerosol)
- Both affect radiation and climate

---

## Step-by-Step Example: Adding BC Emission

### 1. Create emission file
```bash
cd /user/home/xz20153/work
source /user/home/xz20153/CESM_postprocessing/cesm-env2/bin/activate
python create_custom_emissions.py
```

### 2. Edit user_nl_cam
```bash
cd /user/home/xz20153/my_cesm_sandbox/testcase4
nano user_nl_cam
```

Add:
```fortran
! Custom BC emissions
ext_frc_specifier = 'BC -> /user/home/xz20153/work/CESM_Input/custom_emissions.nc'
ext_frc_type = 'INTERP_MISSING_MONTHS'

! Output BC fields
fincl1 = 'BC', 'BURDENBC', 'DF_BC', 'WD_BC', 'AODDUST'
```

### 3. Preview and submit
```bash
./preview_namelists
grep "ext_frc" CaseDocs/atm_in  # Verify it's there
./case.submit
```

### 4. Check output
After run completes:
```bash
ncdump -h archive/testcase4/atm/hist/testcase4.cam.h0.*.nc | grep BC
```

Should see:
```
float BC(time, lev, lat, lon) ;
float BURDENBC(time, lat, lon) ;
```

---

## Troubleshooting

### Emissions not applied
- Check `CaseDocs/atm_in` for your emission settings
- Check `logs/atm.log.*` for errors about missing files
- Verify emission file path is absolute, not relative

### Species name not recognized
- Check spelling matches exactly what CAM expects
- Some species have specific naming: `num_a1` not `NUM_A1`
- Check your chemistry mechanism supports the species

### Wrong magnitude
- Check units (kg/m²/s vs molecules/cm²/s)
- Verify grid cell area effects
- 1° × 1° cell at equator ≈ 12,000 km²
- Total emission (kg/s) = flux (kg/m²/s) × area (m²)

### File format errors
- Ensure NetCDF3 or NetCDF4 classic format
- Dimensions must exactly match model grid
- Use `ncdump -h your_file.nc` to verify structure

---

## Advanced: Aircraft/Elevated Emissions

For emissions at altitude (e.g., aircraft):

1. Add `lev` dimension to emission file
2. Specify which vertical level(s)
3. Use same `ext_frc_specifier` approach

Example in script:
```python
add_point_source_emission(
    species_name='BC',
    lat_point=40.0,
    lon_point=280.0,
    emission_rate=1e-10,
    vertical_level=45,  # ~200 hPa (cruise altitude)
    ...
)
```

---

## References

- CAM6 Chemistry Guide: https://ncar.github.io/CAM/doc/build/html/cam6_scientific_guide/
- CESM Emissions: https://www.cesm.ucar.edu/models/cesm2/atmosphere/chemistry-emissions
- Your Python script: `/user/home/xz20153/work/create_custom_emissions.py`

