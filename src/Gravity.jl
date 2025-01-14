# ~/~ begin <<episodes/060-simulating-solar-system.md#src/Gravity.jl>>[init]
#| file: src/Gravity.jl
module Gravity

using GLMakie
using Unitful
using GeometryBasics
using DataFrames
using LinearAlgebra

# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[init]
#| id: gravity
const G = 6.6743e-11u"m^3*kg^-1*s^-2"
gravitational_force(m1, m2, r) = G * m1 * m2 / r^2
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[1]
#| id: gravity
gravitational_force(m1, m2, r::AbstractVector) = r * (G * m1 * m2 * (r ⋅ r)^(-1.5))
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[2]
#| id: gravity
using Unitful: Mass, Length, Velocity
mutable struct Particle
    mass::typeof(1.0u"kg")
    position::typeof(Vec3d(1)u"m")
    momentum::typeof(Vec3d(1)u"kg*m/s")
end

Particle(mass::Mass, position::Vec3{L}, velocity::Vec3{V}) where {L<:Length,V<:Velocity} =
    Particle(mass, position, velocity * mass)

velocity(p::Particle) = p.momentum / p.mass
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[3]
#| id: gravity
function kick!(particles, dt)
    for i in eachindex(particles)
        for j in 1:(i-1)
            r = particles[j].position - particles[i].position
            force = gravitational_force(particles[i].mass, particles[j].mass, r)
            particles[i].momentum += dt * force
            particles[j].momentum -= dt * force
        end
    end
    return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[4]
#| id: gravity
function drift!(p::Particle, dt)
    p.position += dt * p.momentum / p.mass
end

function drift!(particles, dt)
    for p in values(particles)
        drift!(p, dt)
    end
    return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[5]
#| id: gravity
kick!(dt) = Base.Fix2(kick!, dt)
drift!(dt) = Base.Fix2(drift!, dt)
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[6]
#| id: gravity
leap_frog!(dt) = drift!(dt) ∘ kick!(dt)
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[7]
#| id: gravity
function run_simulation(particles, dt, n)
    result = Matrix{typeof(Vec3d(1)u"m")}(undef, n, length(particles))
    x = deepcopy(particles)
    for c in eachrow(result)
        x = leap_frog!(dt)(x)
        c[:] = [p.position for p in values(x)]
    end
    DataFrame(:time => (1:n)dt, (Symbol.("p", keys(particles)) .=> eachcol(result))...)
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[8]
#| id: gravity
function set_still!(particles)
    total_momentum = sum(p.momentum for p in values(particles))
    total_mass = sum(p.mass for p in values(particles))
    correction = total_momentum / total_mass
    for p in values(particles)
        p.momentum -= correction * p.mass
    end
    return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[9]
#| id: gravity
using DataFrames
using GLMakie

function plot_orbits(orbits::DataFrame)
    fig = Figure()
    ax = Axis3(fig[1, 1], limits=((-5, 5), (-5, 5), (-5, 5)))

    for colname in names(orbits)[2:end]
        scatter!(ax, [orbits[1, colname] / u"m"])
        lines!(ax, orbits[!, colname] / u"m")
    end

    fig
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[10]
#| id: gravity
function random_orbits(n, mass)
    random_particle() = Particle(mass, randn(Vec3d)u"m", randn(Vec3d)u"mm/s")
    particles = set_still!([random_particle() for _ in 1:n])
    run_simulation(particles, 1.0u"s", 5000)
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[11]
#| id: gravity
const SUN = Particle(2e30u"kg",
    Vec3d(0.0)u"m",
    Vec3d(0.0)u"m/s")

const EARTH = Particle(6e24u"kg",
    Vec3d(1.5e11, 0, 0)u"m",
    Vec3d(0, 3e4, 0)u"m/s")

const MOON = Particle(7.35e22u"kg",
    EARTH.position + Vec3d(3.844e8, 0.0, 0.0)u"m",
    velocity(EARTH) + Vec3d(0, 1e3, 0)u"m/s")
# ~/~ end

end
# ~/~ end
