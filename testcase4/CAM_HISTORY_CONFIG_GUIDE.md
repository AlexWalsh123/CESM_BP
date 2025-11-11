# CAM History File Configuration Guide

## What I've Configured

Your `user_nl_cam` file now contains settings to output full 3D atmospheric data.

## History Streams Configured

### h0 - Monthly Averages (default)
- **Frequency**: Monthly averages (`nhtfrq = 0`)
- **Files per month**: 1 (`mfilt = 1`)
- **Type**: Time-averaged (`avgflag = 'A'`)
- **Output**: `testcase4.cam.h0.YYYY-MM.nc`
- **Contains**: Full 3D fields (T, U, V, Q, etc.) averaged over each month
- **Use for**: Climate analysis, monthly statistics

### h1 - Daily Instantaneous Snapshots (NEW!)
- **Frequency**: Daily (`nhtfrq = -24` = every 24 hours)
- **Files**: 30 days per file (`mfilt = 30`)
- **Type**: Instantaneous snapshot (`avgflag = 'I'`)
- **Output**: `testcase4.cam.h1.YYYY-MM-DD-SSSSS.nc`
- **Contains**: 3D atmospheric state at specific times each day
- **Use for**: Daily variability, synoptic analysis

## Key Variables Included

### 3D Fields (lev, lat, lon) - 70 vertical levels
- **T**: Temperature [K]
- **U**: Zonal wind (east-west) [m/s]
- **V**: Meridional wind (north-south) [m/s]
- **Q**: Specific humidity [kg/kg]
- **OMEGA**: Vertical velocity (pressure coordinates) [Pa/s]
- **Z3**: Geopotential height [m]
- **CLOUD**: Cloud fraction [fraction]

### 2D Surface Fields (lat, lon)
- **PS**: Surface pressure [Pa]
- **PSL**: Sea level pressure [Pa]
- **PHIS**: Surface geopotential [m²/s²]
- **TS**: Surface temperature [K]
- **TREFHT**: 2m reference temperature [K]
- **QREFHT**: 2m reference humidity [kg/kg]

### Precipitation Fields
- **PRECT**: Total precipitation [m/s]
- **PRECC**: Convective precipitation [m/s]
- **PRECL**: Large-scale precipitation [m/s]

### Radiation and Energy Fluxes
- **FLNT**: Net longwave flux at top of model [W/m²]
- **FSNT**: Net shortwave flux at top of model [W/m²]
- **FLNS**: Net longwave flux at surface [W/m²]
- **FSNS**: Net shortwave flux at surface [W/m²]
- **LHFLX**: Latent heat flux [W/m²]
- **SHFLX**: Sensible heat flux [W/m²]

### Cloud Properties
- **CLDTOT**: Total cloud fraction [fraction]
- **CLDLOW/MED/HGH**: Low/Medium/High cloud fraction
- **TGCLDLWP**: Liquid water path [kg/m²]
- **TGCLDIWP**: Ice water path [kg/m²]

## File Size Expectations

With this configuration:
- **h0 files** (monthly avg): ~500 MB - 2 GB per month (depending on variables)
- **h1 files** (daily snapshots): ~300 MB - 1 GB per month

For a 1-year run at 1° resolution, expect ~10-20 GB total.

## How to Apply These Changes

1. **For NEW runs**:
   ```bash
   cd /user/home/xz20153/my_cesm_sandbox/testcase4
   ./case.setup --reset  # Reset if already set up
   ./case.setup
   ./case.build
   ./case.submit
   ```

2. **For CONTINUING existing runs**:
   The changes will take effect on the next model submission:
   ```bash
   cd /user/home/xz20153/my_cesm_sandbox/testcase4
   ./case.submit
   ```

## Customization Options

### Add More Variables
Add to `fincl1` or `fincl2`:
```fortran
fincl1 = 'T', 'U', 'V', 'Q', 'RELHUM', 'O3', 'N2O', 'CH4'
```

### Add Hourly Output (h2 stream)
Uncomment the h2 section in `user_nl_cam`:
```fortran
mfilt = 1, 30, 24
nhtfrq = 0, -24, -1
avgflag_pertape = 'A', 'I', 'I'
fincl3 = 'T', 'U', 'V', 'Q', 'PS'
```

### Reduce File Size
Exclude unnecessary variables:
```fortran
fexcl1 = 'PTTEND', 'DTCOND', 'DTV', 'VD01'
```

Or reduce vertical levels output:
```fortran
fincl1 = 'T:A:850:500:200'  # Only output T at 850, 500, 200 hPa
```

### Change Frequency
- `nhtfrq = -6`: Output every 6 hours
- `nhtfrq = -1`: Output every hour
- `nhtfrq = 2`: Output every 2 timesteps

## Common Variables Reference

To see ALL available CAM output variables:
```bash
cd /user/home/xz20153/my_cesm_sandbox/testcase4
./xmlquery CAM_CONFIG_OPTS
# Or check: /your/cesm/models/atm/cam/bld/namelist_files/namelist_defaults_cam.xml
```

## Checking Output After Run

After your model runs, check the history files:
```bash
ls -lh /user/home/xz20153/work/archive/testcase4/atm/hist/

# You should now see:
# testcase4.cam.h0.0001-01.nc    (monthly average)
# testcase4.cam.h1.0001-01-01-00000.nc  (daily snapshot, day 1)
# testcase4.cam.h1.0001-01-02-00000.nc  (daily snapshot, day 2)
# ... etc
```

View contents:
```bash
ncdump -h testcase4.cam.h0.0001-01.nc | grep "float T("
# Should show: float T(time, lev, lat, lon)
```

## Troubleshooting

**Problem**: Files not created
- Check `CaseStatus` for build/submit errors
- Check `atm.log.*` files in `logs/` directory

**Problem**: Files too large
- Reduce variables in `fincl1/2`
- Use `fexcl1` to exclude defaults
- Reduce output frequency

**Problem**: Missing variables
- Check spelling in `fincl` lists
- Some variables only available with certain physics options
- Check `atm.log` for warnings about unavailable fields
