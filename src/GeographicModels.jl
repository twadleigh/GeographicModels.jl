module GeographicModels

export GEOID_EGM2008_1
export GEOID_EGM2008_2_5
export GEOID_EGM2008_5
export GEOID_EGM96_5
export GEOID_EGM96_15
export GEOID_EGM84_15
export GEOID_EGM84_30
export GEOID_DEFAULT
export GRAVITY_GRS80
export GRAVITY_WGS84
export GRAVITY_EGM84
export GRAVITY_EGM96
export GRAVITY_EGM2008
export GRAVITY_DEFAULT
export MAGNETIC_EMM2010
export MAGNETIC_EMM2015
export MAGNETIC_EMM2017
export MAGNETIC_IGRF11
export MAGNETIC_IGRF12
export MAGNETIC_IGRF13
export MAGNETIC_WMM2010
export MAGNETIC_WMM2015
export MAGNETIC_WMM2015v2
export MAGNETIC_WMM2020
export MAGNETIC_DEFAULT

export deref!, height, field, field_and_rate
export gravitational_potential_and_gradient, disturbing_potential_and_gradient
export inertial_potential_and_gradient, centrifugal_potential_and_gradient

module Internal

using CxxWrap
using GeographicLibWrapper_jll
@wrapmodule(GeographicLibWrapper_jll.libGeographicLibWrapper_path)

const GEOCENTRIC_WGS84 = Ref{ConstCxxRef{Geocentric}}()

function __init__()
    @initcxx
    GEOCENTRIC_WGS84.x = wgs84_geocentric()
    return nothing
end

end  # module Internal

using Artifacts
using Geodesy
using LazyArtifacts
using StaticArrays

# allows package "constants" to be instantiated lazily from artifacts
mutable struct LazyRef{T}
    id::String
    val::Union{Nothing,T}

    function LazyRef{T}(id) where {T}
        return new{T}(id, nothing)
    end
end

# instantiate(::Type{T}, ::String, ::String) needs to be defined for T
function deref!(lw::LazyRef{T}) where {T}
    # if the object has already been instantiated, return it
    !isnothing(lw.val) && return lw.val

    # otherwise, instantiate it first
    pth = Artifacts.@artifact_str(lw.id)
    inst = instantiate(T, lw.id, pth)
    lw.val = inst
    return inst
end

const Geoid = LazyRef{Internal.Geoid}
const GEOID_EGM2008_1 = Geoid("egm2008-1")
const GEOID_EGM2008_2_5 = Geoid("egm2008-2_5")
const GEOID_EGM2008_5 = Geoid("egm2008-5")
const GEOID_EGM96_5 = Geoid("egm96-5")
const GEOID_EGM96_15 = Geoid("egm96-15")
const GEOID_EGM84_15 = Geoid("egm84-15")
const GEOID_EGM84_30 = Geoid("egm84-30")
const GEOID_DEFAULT = GEOID_EGM96_5

function instantiate(::Type{Internal.Geoid}, id::String, pth::String)
    return Internal.Geoid(id, joinpath(pth, "geoids"), true, true)
end

const GravityModel = LazyRef{Internal.GravityModel}
const GRAVITY_GRS80 = GravityModel("grs80")
const GRAVITY_WGS84 = GravityModel("wgs84")
const GRAVITY_EGM84 = GravityModel("egm84")
const GRAVITY_EGM96 = GravityModel("egm96")
const GRAVITY_EGM2008 = GravityModel("egm2008")
const GRAVITY_DEFAULT = GRAVITY_EGM96

function instantiate(::Type{Internal.GravityModel}, id::String, pth::String)
    return Internal.GravityModel(id, joinpath(pth, "gravity"), -1, -1)
end

const MagneticModel = LazyRef{Internal.MagneticModel}
const MAGNETIC_EMM2010 = MagneticModel("emm2010")
const MAGNETIC_EMM2015 = MagneticModel("emm2015")
const MAGNETIC_EMM2017 = MagneticModel("emm2017")
const MAGNETIC_IGRF11 = MagneticModel("igrf11")
const MAGNETIC_IGRF12 = MagneticModel("igrf12")
const MAGNETIC_IGRF13 = MagneticModel("igrf13")
const MAGNETIC_WMM2010 = MagneticModel("wmm2010")
const MAGNETIC_WMM2015 = MagneticModel("wmm2015")
const MAGNETIC_WMM2015v2 = MagneticModel("wmm2015v2")
const MAGNETIC_WMM2020 = MagneticModel("wmm2020")
const MAGNETIC_DEFAULT = MAGNETIC_WMM2020

function instantiate(::Type{Internal.MagneticModel}, id::String, pth::String)
    return Internal.MagneticModel(
        id, joinpath(pth, "magnetic"), Internal.GEOCENTRIC_WGS84.x, -1, -1
    )
end

function height(geoid::Internal.Geoid, lat, lon)
    return geoid(lat, lon)
end

function height(gravity::Internal.GravityModel, lat, lon)
    return Internal.geoid_height(gravity, lat, lon)
end

height(model::LazyRef, lat, lon) = height(deref!(model), lat, lon)
height(model, lla::LLA) = height(model, lla.lat, lla.lon)
height(lat, lon) = height(GRAVITY_DEFAULT, lat, lon)
height(lla::LLA) = height(lla.lat, lla.lon)

function gravitational_potential_and_gradient(gravity::Internal.GravityModel, lla::LLA)
    gx = Ref{Float64}()
    gy = Ref{Float64}()
    gz = Ref{Float64}()
    w = Internal.gravity(gravity, lla.lat, lla.lon, lla.alt, gx, gy, gz)
    return (w, ENU(gx.x, gy.x, gz.x))
end

function disturbing_potential_and_gradient(gravity::Internal.GravityModel, lla::LLA)
    dx = Ref{Float64}()
    dy = Ref{Float64}()
    dz = Ref{Float64}()
    t = Internal.disturbance(gravity, lla.lat, lla.lon, lla.alt, dx, dy, dz)
    return (t, ENU(dx.x, dy.x, dz.x))
end

function gravitational_potential_and_gradient(gravity::Internal.GravityModel, ecef::ECEF)
    gX = Ref{Float64}()
    gY = Ref{Float64}()
    gZ = Ref{Float64}()
    w = Internal.w(gravity, ecef.x, ecef.y, ecef.z, gX, gY, gZ)
    return (w, ECEF(gX.x, gY.x, gZ.x))
end

function disturbing_potential_and_gradient(gravity::Internal.GravityModel, ecef::ECEF)
    dX = Ref{Float64}()
    dY = Ref{Float64}()
    dZ = Ref{Float64}()
    t = Internal.t(gravity, ecef.x, ecef.y, ecef.z, dX, dY, dZ)
    return (t, ECEF(dX.x, dY.x, dZ.x))
end

function inertial_potential_and_gradient(gravity::Internal.GravityModel, ecef::ECEF)
    GX = Ref{Float64}()
    GY = Ref{Float64}()
    GZ = Ref{Float64}()
    v = Internal.v(gravity, ecef.x, ecef.y, ecef.z, GX, GY, GZ)
    return (v, ECEF(GX.x, GY.x, GZ.x))
end

function centrifugal_potential_and_gradient(gravity::Internal.GravityModel, ecef::ECEF)
    fX = Ref{Float64}()
    fY = Ref{Float64}()
    phi = Internal.phi(gravity, ecef.x, ecef.y, fX, fY)
    return (phi, ECEF(fX.x, fY.x, 0.0))
end

function gravitational_potential_and_gradient(model::LazyRef, x)
    return gravitational_potential_and_gradient(deref!(model), x)
end

function disturbing_potential_and_gradient(model::LazyRef, x)
    return disturbing_potential_and_gradient(deref!(model), x)
end

function inertial_potential_and_gradient(model::LazyRef, x)
    return inertial_potential_and_gradient(deref!(model), x)
end

function centrifugal_potential_and_gradient(model::LazyRef, x)
    return centrifugal_potential_and_gradient(deref!(model), x)
end

function gravitational_potential_and_gradient(x)
    return gravitational_potential_and_gradient(GRAVITY_DEFAULT, x)
end

function disturbing_potential_and_gradient(x)
    return disturbing_potential_and_gradient(GRAVITY_DEFAULT, x)
end

function inertial_potential_and_gradient(x)
    return inertial_potential_and_gradient(GRAVITY_DEFAULT, x)
end

function centrifugal_potential_and_gradient(x)
    return centrifugal_potential_and_gradient(GRAVITY_DEFAULT, x)
end

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
    mm(time_year, ecef.x, ecef.y, ecef.z, BX, BY, BZ)
    return ECEF(BX.x, BY.x, BZ.x)
end

function field_and_rate(mm::Internal.MagneticModel, time_year, ecef::ECEF)
    BX = Ref{Float64}()
    BY = Ref{Float64}()
    BZ = Ref{Float64}()
    BXt = Ref{Float64}()
    BYt = Ref{Float64}()
    BZt = Ref{Float64}()
    mm(time_year, ecef.x, ecef.y, ecef.z, BX, BY, BZ, BXt, BYt, BZt)
    return (ECEF(BX.x, BY.x, BZ.x), ECEF(BXt.x, BYt.x, BZt.x))
end

field(mm::LazyRef, t, x) = field(deref!(mm), t, x)
field_and_rate(mm::LazyRef, t, x) = field_and_rate(deref!(mm), t, x)
field(t, x) = field(MAGNETIC_DEFAULT, t, x)
field_and_rate(t, x) = field_and_rate(MAGNETIC_DEFAULT, t, x)

function __init__()
    Internal.__init__()
    return nothing
end

end  # module GeographicModels
