# ~/~ begin <<episodes/060-simulating-solar-system.md#src/Gravity.jl>>[init]
#| file: src/Gravity.jl
module Gravity

using Unitful
using GeometryBasics
using DataFrames
using LinearAlgebra
using Random

import Base: position

export random_partcle, random_particles, velocity, mass, momentum, position
export run_simulation, set_still!

# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[init]
#| id: gravity
const G = 6.6743e-11u"m^3*kg^-1*s^-2"
gravitational_force(m1, m2, r) = G * m1 * m2 / r^2
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[1]
#| id: gravity
"""
    gravitational_force(m1, m2, r)

Returns the gravitational force as a function of masses `m1` and `m2` and `r` the distance vector between them. The force will be in the direction of `r`.
"""
gravitational_force(m1, m2, r::AbstractVector) =
    r * (G * m1 * m2 * (r ⋅ r)^(-1.5))
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[2]
#| id: gravity

const Mass = typeof(1.0u"kg")
const MomentumVector = typeof(Vec3d(1)u"kg*m/s")
const PositionVector = typeof(Vec3d(1)u"m")
const VelocityVector = typeof(Vec3d(1)u"m/s")
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[3]
#| id: gravity
mutable struct Particle
    mass::Mass
    position::PositionVector
    momentum::MomentumVector
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[4]
#| id: gravity
random_particle(mass=1e6u"kg", spread=1.0u"m", dispersion=2.0u"mm/s") =
    Particle(mass, randn(Vec3d) * spread, randn(Vec3d) * dispersion * mass)

function random_particles(n; seed=0, args...)
    Random.seed!(seed)
    [random_particle(args...) for _ in 1:n]
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[5]
#| id: gravity
mass(p::Particle) = p.mass
position(p::Particle) = p.position
momentum(p::Particle) = p.momentum

# random_particles(3) .|> momentum
# etc...

mass(p::AbstractArray{Particle}) = sum(mass, p)
momentum(p::AbstractArray{Particle}) = sum(momentum, p)
velocity(p) = momentum(p) / mass(p)
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[6]
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
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[7]
#| id: gravity
function drift!(p::Particle, dt)
    p.position += dt * p.momentum / p.mass
end

function drift!(particles, dt)
    for p in particles
        drift!(p, dt)
    end
    return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[8]
#| id: gravity
kick!(dt) = Base.Fix2(kick!, dt)
drift!(dt) = Base.Fix2(drift!, dt)
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[9]
#| id: gravity
leap_frog!(dt) = drift!(dt) ∘ kick!(dt)
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[10]
#| id: gravity

"""
    leap_frog!(particles, dt)

One leap-frog integration time step `dt` for `particles` under
gravity.
"""
function leap_frog!(particles, dt)
    drift!(particles, dt/2)
    kick!(particles, dt)
    drift!(particles, dt/2)
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[11]
#| id: gravity
function run_simulation(particles, dt, n_steps)
    x = deepcopy(particles)
    [deepcopy(leap_frog!(x, dt)) for _ in 1:n_steps]
end

function random_orbits(n, mass; dt=1.0u"s", steps=5000, args...)
    particles = random_particles(n; args...)
    run_simulation(particles, dt, steps) |> collect
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[12]
#| id: gravity
function set_still!(particles)
    v = velocity(particles)
    for p in particles
        p.momentum -= v * mass(p)
    end
    return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-simulating-solar-system.md#gravity>>[13]
#| id: gravity
# const SUN = Particle(2e30u"kg",
#     Vec3d(0.0)u"m",
#     Vec3d(0.0)u"m/s")

# const EARTH = Particle(6e24u"kg",
#     Vec3d(1.5e11, 0, 0)u"m",
#     Vec3d(0, 3e4, 0)u"m/s")

# const MOON = Particle(7.35e22u"kg",
#     EARTH.position + Vec3d(3.844e8, 0.0, 0.0)u"m",
#     velocity(EARTH) + Vec3d(0, 1e3, 0)u"m/s")
# ~/~ end

end
# ~/~ end
