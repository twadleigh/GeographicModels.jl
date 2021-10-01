# GeographicModels

A Julia interface to the gravity and magnetic models provided by [GeographicLib](https://geographiclib.sourceforge.io/).

## Quick start

```
julia> using Geodesy, GeographicModels

julia> lla = LLA(0.0, 0.0, 0.0)
LLA(lat=0.0°, lon=0.0°, alt=0.0)

julia> height(lla)
17.161578487990724

julia> height(EGM96, lla)
17.161578487990724

julia> earth_fixed_gravity(EGM96, lla)
ENU(-1.8142433323839776e-5, 7.755467819136968e-6, -9.780368681573895)

julia> ecef = ECEFfromLLA(wgs84)(lla)
ECEF(6.378137e6, 0.0, 0.0)

julia> earth_fixed_gravity(EGM96, ecef)
ECEF(-9.780368681573895, -1.8142433323839776e-5, 7.755467819136968e-6)
```
