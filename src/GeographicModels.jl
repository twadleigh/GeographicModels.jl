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

@enum GeoidKey begin
    EGM2008_1 = 1
    EGM2008_2_5 = 2
    EGM2008_5 = 3
    EGM96_5 = 4
    EGM96_15 = 5
    EGM84_15 = 6
    EGM84_30 = 7
end
const GEOID_DEFAULT = EGM96_5

export GeoidKey, GEOID_DEFAULT
export EGM2008_1, EGM2008_2_5, EGM2008_5, EGM96_5, EGM96_15, EGM84_15, EGM84_30

const GEOIDS = Dict{GeoidKey,Internal.Geoid}()

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

@enum GravityModelKey begin
    GRS80 = 1
    WGS84 = 2
    EGM84 = 3
    EGM96 = 4
    EGM2008 = 5
end
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
const MAGNETIC_MODEL_DEFAULT = WMM2020

export MagneticModelKey, MAGNETIC_MODEL_DEFAULT
export EMM2010, EMM2015, EMM2017, IGRF11, IGRF12, IGRF13, WMM2010, WMM2015, WMM2015v2,
    WMM2020

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

function earth_fixed_potential_and_gradient(gm::Internal.GravityModel, lla::LLA)
    gx = Ref{Float64}()
    gy = Ref{Float64}()
    gz = Ref{Float64}()
    w = Internal.gravity(gm, lla.lat, lla.lon, lla.alt, gx, gy, gz)
    return (w, ENU(gx.x, gy.x, gz.x))
end

function disturbing_potential_and_gradient(gm::Internal.GravityModel, lla::LLA)
    dx = Ref{Float64}()
    dy = Ref{Float64}()
    dz = Ref{Float64}()
    t = Internal.disturbance(gm, lla.lat, lla.lon, lla.alt, dx, dy, dz)
    return (t, ENU(dx.x, dy.x, dz.x))
end

function earth_fixed_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    gX = Ref{Float64}()
    gY = Ref{Float64}()
    gZ = Ref{Float64}()
    w = Internal.w(gm, ecef.x, ecef.y, ecef.z, gX, gY, gZ)
    return (w, ECEF(gX.x, gY.x, gZ.x))
end

function disturbing_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    dX = Ref{Float64}()
    dY = Ref{Float64}()
    dZ = Ref{Float64}()
    t = Internal.t(gm, ecef.x, ecef.y, ecef.z, dX, dY, dZ)
    return (t, ECEF(dX.x, dY.x, dZ.x))
end

function inertial_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    GX = Ref{Float64}()
    GY = Ref{Float64}()
    GZ = Ref{Float64}()
    v = Internal.v(gm, ecef.x, ecef.y, ecef.z, GX, GY, GZ)
    return (v, ECEF(GX.x, GY.x, GZ.x))
end

function centrifugal_potential_and_gradient(gm::Internal.GravityModel, ecef::ECEF)
    fX = Ref{Float64}()
    fY = Ref{Float64}()
    phi = Internal.phi(gm, ecef.x, ecef.y, fX, fY)
    return (phi, ECEF(fX.x, fY.x, 0.0))
end

function earth_fixed_potential_and_gradient(key::Enum, x)
    return earth_fixed_potential_and_gradient(model(key), x)
end

function disturbing_potential_and_gradient(key::Enum, x)
    return disturbing_potential_and_gradient(model(key), x)
end

function inertial_potential_and_gradient(key::Enum, x)
    return inertial_potential_and_gradient(model(key), x)
end

function centrifugal_potential_and_gradient(key::Enum, x)
    return centrifugal_potential_and_gradient(model(key), x)
end

function earth_fixed_gravity(model, x)
    return earth_fixed_potential_and_gradient(model, x)[2]
end

function disturbance(model, x)
    return disturbing_potential_and_gradient(model, x)[2]
end

function inertial_gravity(model, x)
    return inertial_potential_and_gradient(model, x)[2]
end

function centrifugal_acceleration(model, x)
    return centrifugal_potential_and_gradient(model, x)[2]
end

function earth_fixed_potential_and_gradient(x)
    return earth_fixed_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

function disturbing_potential_and_gradient(x)
    return disturbing_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

function inertial_potential_and_gradient(x)
    return inertial_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

function centrifugal_potential_and_gradient(x)
    return centrifugal_potential_and_gradient(GRAVITY_MODEL_DEFAULT, x)
end

export earth_fixed_potential_and_gradient, disturbing_potential_and_gradient,
    inertial_potential_and_gradient, centrifugal_potential_and_gradient,
    earth_fixed_gravity, inertial_gravity, centrifugal_acceleration

function field(mm::Internal.MagneticModel, time_year, lla::LLA)
    Bx = Ref{Float64}()
    By = Ref{Float64}()
    Bz = Ref{Float64}()
    mm(time_year, lla.lat, lla.lon, lla.alt, Bx, By, Bz)
    return ENU(Bx.x, By.x, Bz.x)
end

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

function field(mm::Internal.MagneticModel, time_year, ecef::ECEF)
    BX = Ref{Float64}()
    BY = Ref{Float64}()
    BZ = Ref{Float64}()
    Internal.field_geocentric(mm, time_year, ecef.x, ecef.y, ecef.z, BX, BY, BZ)
    return ECEF(BX.x, BY.x, BZ.x)
end

function field_and_rate(mm::Internal.MagneticModel, time_year, ecef::ECEF)
    BX = Ref{Float64}()
    BY = Ref{Float64}()
    BZ = Ref{Float64}()
    BXt = Ref{Float64}()
    BYt = Ref{Float64}()
    BZt = Ref{Float64}()
    Internal.field_geocentric(
        mm, time_year, ecef.x, ecef.y, ecef.z, BX, BY, BZ, BXt, BYt, BZt
    )
    return (ECEF(BX.x, BY.x, BZ.x), ECEF(BXt.x, BYt.x, BZt.x))
end

field(key::Enum, t, x) = field(model(key), t, x)
field_and_rate(key::Enum, t, x) = field_and_rate(model(key), t, x)
field(t, x) = field(MAGNETIC_MODEL_DEFAULT, t, x)
field_and_rate(t, x) = field_and_rate(MAGNETIC_MODEL_DEFAULT, t, x)

export field, field_and_rate

function __init__()
    Internal.__init__()
    return nothing
end

end  # module GeographicModels
