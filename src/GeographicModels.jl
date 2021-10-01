"""
Earth gravity and magnetic models.
"""
module GeographicModels

# wraps GeographicLibWrapper_jll
module Internal

using CxxWrap
using GeographicLibWrapper_jll
@wrapmodule(GeographicLibWrapper_jll.libGeographicLibWrapper_path)

const WGS84 = Ref{ConstCxxRef{Geocentric}}()

function __init__()
    @initcxx
    WGS84.x = wgs84_geocentric()
    return nothing
end

end  # module Internal

using Artifacts
using Geodesy
using LazyArtifacts

"""
    @enum GeoidKey = EGM2008_1 | EGM2008_2_5 | EGM2008_5 | EGM96_5 | EGM96_15 | EGM84_15 | EGM84_30

Enumerates available instances of [gridded geoid models](https://geographiclib.sourceforge.io/html/geoid.html).

See also: [`GEOID_DEFAULT`](@ref), [`model`](@ref) 
"""
@enum GeoidKey begin
    EGM2008_1 = 1
    EGM2008_2_5 = 2
    EGM2008_5 = 3
    EGM96_5 = 4
    EGM96_15 = 5
    EGM84_15 = 6
    EGM84_30 = 7
end

"""
    GEOID_DEFAULT = EGM96_5

Geoid model used when none is explicitly specified.

See also: [`GeoidKey`](@ref), [`model`](@ref)
"""
const GEOID_DEFAULT = EGM96_5

export GeoidKey, GEOID_DEFAULT
export EGM2008_1, EGM2008_2_5, EGM2008_5, EGM96_5, EGM96_15, EGM84_15, EGM84_30

const GEOIDS = Dict{GeoidKey,Internal.Geoid}()

"""
    model(key)

Return an instance of the geographic model indicated by `key`.

The method first checks an internal dictionary for an instance of the model already
loaded. If found, that instance is returned. Otherwise, the method will instantiate the
model from a corresponding artifact, caching it in the dictionary before returning it. If
the artifact is not already found on the system, it will first download it.

See also: [`GeoidKey`](@ref), [`GravityModelKey`](@ref), [`MagneticModelKey`](@ref)
"""
function model(key::GeoidKey)
    ids = (
        "egm2008-1",
        "egm2008-2_5",
        "egm2008-5",
        "egm96-5",
        "egm96-15",
        "egm84-15",
        "egm84-30",
    )
    return get!(GEOIDS, key) do
        id = ids[Int(key)]
        pth = joinpath(Artifacts.@artifact_str(id), "geoids")
        return Internal.Geoid(id, pth, true, true)
    end
end

"""
    @enum GravityModelKey = GRS80 | WGS84 | EGM84 | EGM96 | EGM2008

Enumerates available instances of [earth gravity models](https://geographiclib.sourceforge.io/html/gravity.html).

See also: [`GRAVITY_MODEL_DEFAULT`](@ref), [`model`](@ref)
"""
@enum GravityModelKey begin
    GRS80 = 1
    WGS84 = 2
    EGM84 = 3
    EGM96 = 4
    EGM2008 = 5
end

"""
    GRAVITY_MODEL_DEFAULT = EGM96

Default gravity model to use when none is explicitly specified.

See also: [`GravityModelKey`](@ref), [`model`](@ref)
"""
const GRAVITY_MODEL_DEFAULT = EGM96

export GravityModelKey, GRAVITY_MODEL_DEFAULT
export GRS80, WGS84, EGM84, EGM96, EGM2008

const GRAVITY_MODELS = Dict{GravityModelKey,Internal.GravityModel}()

function model(key::GravityModelKey)
    ids = ("grs80", "wgs84", "egm84", "egm96", "egm2008")
    return get!(GRAVITY_MODELS, key) do
        id = ids[Int(key)]
        pth = joinpath(Artifacts.@artifact_str(id), "gravity")
        return Internal.GravityModel(id, pth, -1, -1)
    end
end

"""
    @enum MagneticModelKey = EMM2010 | EMM2015 | EMM2017 | IGRF11 | IGRF12 | IGRF13 | WMM2010 | WMM2015 | WMM2015v2 | WMM2020

Enumerates available instances of [earth magnetic models](https://geographiclib.sourceforge.io/html/magnetic.html).

See also: [`MAGNETIC_MODEL_DEFAULT`](@ref), [`model`](@ref)
"""
@enum MagneticModelKey begin
    EMM2010 = 1
    EMM2015 = 2
    EMM2017 = 3
    IGRF11 = 4
    IGRF12 = 5
    IGRF13 = 6
    WMM2010 = 7
    WMM2015 = 8
    WMM2015v2 = 9
    WMM2020 = 10
end

"""
    MAGNETIC_MODEL_DEFAULT = WMM2020

Default magnetic model to use when none is explicitly specified.

See also: [`MagneticModelKey`](@ref), [`model`](@ref)
"""
const MAGNETIC_MODEL_DEFAULT = WMM2020

export MagneticModelKey, MAGNETIC_MODEL_DEFAULT
export EMM2010,
    EMM2015, EMM2017, IGRF11, IGRF12, IGRF13, WMM2010, WMM2015, WMM2015v2, WMM2020

const MAGNETIC_MODELS = Dict{MagneticModelKey,Internal.MagneticModel}()

function model(key::MagneticModelKey)
    ids = (
        "emm2010",
        "emm2015",
        "emm2017",
        "igrf11",
        "igrf12",
        "igrf13",
        "wmm2010",
        "wmm2015",
        "wmm2015v2",
        "wmm2020",
    )
    return get!(MAGNETIC_MODELS, key) do
        id = ids[Int(key)]
        pth = joinpath(Artifacts.@artifact_str(id), "magnetic")
        return Internal.MagneticModel(id, pth, Internal.WGS84.x, -1, -1)
    end
end

export model

"""
    height([key|model], position)

Return the geoid height, in m, relative to the WGS84 ellipsoid height at `position`.

Upstream documentation: [`Geoid::operator()`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1Geoid.html#ab93330904bbfd607d6adde2cef844b9b)
and [`GravityModel::GeoidHeight`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1GravityModel.html#a454bf53c090f2b85d8a3cfeb8dcc3961).
"""
function height(geoid::Internal.Geoid, lat, lon)
    return geoid(lat, lon)
end

function height(gm::Internal.GravityModel, lat, lon)
    return Internal.geoid_height(gm, lat, lon)
end

height(key::Enum, lat, lon) = height(model(key), lat, lon)
height(model, lla::LLA) = height(model, lla.lat, lla.lon)
height(lat, lon) = height(GRAVITY_MODEL_DEFAULT, lat, lon)
height(lla::LLA) = height(lla.lat, lla.lon)

export height

"""
    earth_fixed_potential_and_gradient([key|model], position)

Return the potential, in m^2/s^2, and acceleration, in m/s^2, due to gravity and the
centrifugal acceleration at `position`.

Upstream documentation: [`GravityModel::Gravity`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1GravityModel.html#a7edb25ad4417fa932acaade613c6f027)
and [`GravityModel::W`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1GravityModel.html#aba0b5cbd1f80162677ce47ac94ad4c44).

See also: [`inertial_potential_and_gradient`](@ref), [`centrifugal_potential_and_gradient`](@ref),
[`earth_fixed_gravity`](@ref)
"""
function earth_fixed_potential_and_gradient(gm::Internal.GravityModel, lla::LLA)
    gx = Ref{Float64}()
    gy = Ref{Float64}()
    gz = Ref{Float64}()
    w = Internal.gravity(gm, lla.lat, lla.lon, lla.alt, gx, gy, gz)
    return (w, ENU(gx.x, gy.x, gz.x))
end

function earth_fixed_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    gX = Ref{Float64}()
    gY = Ref{Float64}()
    gZ = Ref{Float64}()
    w = Internal.w(gm, ecef.x, ecef.y, ecef.z, gX, gY, gZ)
    return (w, ECEF(gX.x, gY.x, gZ.x))
end

function earth_fixed_potential_and_gradient(key::Enum, x)
    return earth_fixed_potential_and_gradient(model(key), x)
end

function earth_fixed_potential_and_gradient(x)
    return earth_fixed_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

export earth_fixed_potential_and_gradient

"""
    earth_fixed_gravity([key|model], position)

Like `earth_fixed_potential_and_gradient`, but returns only the gravity vector.

See also: [`earth_fixed_potential_and_gradient`], [`inertial_gravity`](@ref) 
"""
function earth_fixed_gravity(model, x)
    return earth_fixed_potential_and_gradient(model, x)[2]
end

export earth_fixed_gravity

"""
    inertial_potential_and_gradient([key|model], position)

Return the potential, in m^2/s^2, and acceleration, in m/s^2, due to gravity at `position`.

Upstream documentation: [`GravityModel::V`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1GravityModel.html#aa49d04f9f21c06cb652b9977196fcffe).

See also: [`earth_fixed_potential_and_gradient`](@ref), [`centrifugal_potential_and_gradient`](@ref),
[`inertial_gravity`]
"""
function inertial_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    GX = Ref{Float64}()
    GY = Ref{Float64}()
    GZ = Ref{Float64}()
    v = Internal.v(gm, ecef.x, ecef.y, ecef.z, GX, GY, GZ)
    return (v, ECEF(GX.x, GY.x, GZ.x))
end

function inertial_potential_and_gradient(key::Enum, x)
    return inertial_potential_and_gradient(model(key), x)
end

function inertial_potential_and_gradient(x)
    return inertial_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

export inertial_potential_and_gradient

"""
    inertial_gravity([key|model], position)

Like `inertial_potential_and_gradient`, but returns only the gravity vector.

See also: [`inertial_potential_and_gradient`]
"""
function inertial_gravity(model, x)
    return inertial_potential_and_gradient(model, x)[2]
end

export inertial_gravity

"""
    centrifugal_potential_and_gradient([key|model], position)

Return the potential, in m^2/s^2, and acceleration, in m/s^2, due to centrifugal acceleration
at `position`.

Upstream documentation: [`GravityModel::Phi`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1GravityModel.html#a9ef0cb672cecb5c5922f8ea88dc5846c).

See also: [`earth_fixed_potential_and_gradient`](@ref), [`inertial_potential_and_gradient`](@ref)
"""
function centrifugal_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    fX = Ref{Float64}()
    fY = Ref{Float64}()
    phi = Internal.phi(gm, ecef.x, ecef.y, fX, fY)
    return (phi, ECEF(fX.x, fY.x, 0.0))
end

function centrifugal_potential_and_gradient(key::Enum, x)
    return centrifugal_potential_and_gradient(model(key), x)
end

function centrifugal_potential_and_gradient(x)
    return centrifugal_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

export centrifugal_potential_and_gradient

"""
    centrifugal_acceleration([key|model], position)

Like `centrifugal_potential_and_gradient`, but returns only the acceleration vector.

See also: [`centrifugal_potential_and_gradient`]
"""
function centrifugal_acceleration(model, x)
    return centrifugal_potential_and_gradient(model, x)[2]
end

export centrifugal_acceleration

"""
    normal_potential_and_gradient([key|model], position)

Return the potential, in m^2/s^2, and acceleration, in m/s^2, due to gravity and the
centrifugal acceleration at `position` as implied by the WGS84 reference ellipsoidal
model.

Upstream documentation: [`GravityModel::U`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1GravityModel.html#ad5f97f59cee99fd804af246634de2bbc).

See also: [`earth_fixed_potential_and_gradient`](@ref), [`disturbing_potential_and_gradient`](@ref),
[`normal_gravity`](@ref)
"""
function normal_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    fX = Ref{Float64}()
    fY = Ref{Float64}()
    phi = Internal.phi(gm, ecef.x, ecef.y, fX, fY)
    return (phi, ECEF(fX.x, fY.x, 0.0))
end

function normal_potential_and_gradient(key::Enum, x)
    return normal_potential_and_gradient(model(key), x)
end

function normal_potential_and_gradient(x)
    return normal_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

export normal_potential_and_gradient

"""
    normal_gravity([key|model], position)

Like `normal_potential_and_gradient`, but returns only the acceleration vector.

See also: [`normal_potential_and_gradient`]
"""
function normal_gravity() end

export normal_gravity

"""
    disturbing_potential_and_gradient([key|model], position)

Return the difference in potential, in m^2/s^2, and acceleration, in m/s^2, due to gravity 
at `position` as implied by the model and the normal gravity of the WGS84 reference ellipsoid.

Upstream documentation: [`GravityModel::T`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1GravityModel.html#a46e1863fe86c7a7dcae0bfb433eae287).

See also: [`earth_fixed_potential_and_gradient`](@ref), [`normal_potential_and_gradient`](@ref),
[`disturbance`](@ref)
"""
function disturbing_potential_and_gradient(gm::Internal.GravityModel, lla::LLA)
    dx = Ref{Float64}()
    dy = Ref{Float64}()
    dz = Ref{Float64}()
    t = Internal.disturbance(gm, lla.lat, lla.lon, lla.alt, dx, dy, dz)
    return (t, ENU(dx.x, dy.x, dz.x))
end

function disturbing_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    dX = Ref{Float64}()
    dY = Ref{Float64}()
    dZ = Ref{Float64}()
    t = Internal.t(gm, ecef.x, ecef.y, ecef.z, dX, dY, dZ)
    return (t, ECEF(dX.x, dY.x, dZ.x))
end

function disturbing_potential_and_gradient(key::Enum, x)
    return disturbing_potential_and_gradient(model(key), x)
end

function disturbing_potential_and_gradient(x)
    return disturbing_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

export disturbing_potential_and_gradient

"""
    disturbance([key|model], position)

Like `disturbing_potential_and_gradient`, but returns only the acceleration vector.

See also: [`disturbing_potential_and_gradient`]
"""
function disturbance(model, x)
    return disturbing_potential_and_gradient(model, x)[2]
end

export disturbance

"""
    field([key|model], year, position)

Return the magnetic field vector, in nT, at `position` at `year`.

Upstream documentation: [`MagneticModel::operator()`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1MagneticModel.html#a6926b87c45184af8664f047c047d3b98).

See also: [`field_and_rate`](@ref)
"""
function field(mm::Internal.MagneticModel, time_year, lla::LLA)
    Bx = Ref{Float64}()
    By = Ref{Float64}()
    Bz = Ref{Float64}()
    mm(time_year, lla.lat, lla.lon, lla.alt, Bx, By, Bz)
    return ENU(Bx.x, By.x, Bz.x)
end

function field(mm::Internal.MagneticModel, time_year, ecef::ECEF)
    BX = Ref{Float64}()
    BY = Ref{Float64}()
    BZ = Ref{Float64}()
    Internal.field_geocentric(mm, time_year, ecef.x, ecef.y, ecef.z, BX, BY, BZ)
    return ECEF(BX.x, BY.x, BZ.x)
end

field(key::Enum, t, x) = field(model(key), t, x)
field(t, x) = field(MAGNETIC_MODEL_DEFAULT, t, x)

export field

"""
    field_and_rate([key|model], year, position)

Return the magnetic field vector, in nT, and its time rate of change, in nT/yr, at
`position` at `year`.

Upstream documentation: [`MagneticModel::operator()`](https://geographiclib.sourceforge.io/html/classGeographicLib_1_1MagneticModel.html#ae99b6cc47355e452c398eb3cf7cab0e6).

See also: [`field`](@ref)
"""
function field_and_rate(mm::Internal.MagneticModel, time_year, lla::LLA)
    Bx = Ref{Float64}()
    By = Ref{Float64}()
    Bz = Ref{Float64}()
    Bxt = Ref{Float64}()
    Byt = Ref{Float64}()
    Bzt = Ref{Float64}()
    mm(time_year, lla.lat, lla.lon, lla.alt, Bx, By, Bz, Bxt, Byt, Bzt)
    return (ENU(Bx.x, By.x, Bz.x), ENU(Bxt.x, Byt.x, Bzt.x))
end

function field_and_rate(mm::Internal.MagneticModel, time_year, ecef::ECEF)
    BX = Ref{Float64}()
    BY = Ref{Float64}()
    BZ = Ref{Float64}()
    BXt = Ref{Float64}()
    BYt = Ref{Float64}()
    BZt = Ref{Float64}()
    Internal.field_geocentric(
        mm,
        time_year,
        ecef.x,
        ecef.y,
        ecef.z,
        BX,
        BY,
        BZ,
        BXt,
        BYt,
        BZt,
    )
    return (ECEF(BX.x, BY.x, BZ.x), ECEF(BXt.x, BYt.x, BZt.x))
end

field_and_rate(key::Enum, t, x) = field_and_rate(model(key), t, x)
field_and_rate(t, x) = field_and_rate(MAGNETIC_MODEL_DEFAULT, t, x)

export field_and_rate

function __init__()
    Internal.__init__()
    return nothing
end

end  # module GeographicModels
