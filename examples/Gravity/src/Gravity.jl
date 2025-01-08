# ~/~ begin <<episodes/060-plotting.md#examples/Gravity/src/Gravity.jl>>[init]
module Gravity

using Unitful
using GLMakie
using GeometryBasics
using DataFrames

# ~/~ begin <<episodes/060-plotting.md#gravity>>[init]
mutable struct Particle
	mass::typeof(1.0u"kg")
	position::typeof(Vec3d(1)u"m")
	velocity::typeof(Vec3d(1)u"m/s")
end
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[1]
const G = 6.6743e-11u"m^3*kg^-1*s^-2"
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[2]
function kick!(particles, dt)
	for i in eachindex(particles)
		a = zero(Vec3d)u"m/s^2"
		for j in eachindex(particles)
			i == j && continue
			r = particles[j].position - particles[i].position
			r2 = sum(r*r)
			a += r * (G * particles[j].mass * r2^(-1.5))
		end
		particles[i].velocity += dt * a
	end
	return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[3]
function drift!(p::Particle, dt)
	p.position += dt * p.velocity
end

function drift!(particles, dt)
	for p in values(particles)
		drift!(p, dt)
	end
	return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[4]
kick!(dt) = Base.Fix2(kick!, dt)
drift!(dt) = Base.Fix2(drift!, dt)
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[5]
leap_frog!(dt) = drift!(dt) ∘ kick!(dt)
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[6]
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
# ~/~ begin <<episodes/060-plotting.md#gravity>>[7]
function random_orbits(n, mass)
    random_particle() = Particle(mass, randn(Vec3d)u"m", randn(Vec3d)u"mm/s")
	particles = set_still!([random_particle() for _ in 1:n])
	run_simulation(particles, 1.0u"s", 5000)
end
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[8]
function set_still!(particles)
	total_momentum = sum(p.mass * p.velocity for p in values(particles))
	total_mass = sum(p.mass for p in values(particles))
	correction = total_momentum / total_mass
	for p in values(particles)
		p.velocity -= correction
	end
	return particles
end
# ~/~ end
# ~/~ begin <<episodes/060-plotting.md#gravity>>[9]
const SUN = Particle(2e30u"kg",
    Vec3d(0.0)u"m",
    Vec3d(0.0)u"m/s")

const EARTH = Particle(6e24u"kg",
    Vec3d(1.5e11, 0, 0)u"m",
    Vec3d(0, 3e4, 0)u"m/s")

const MOON = Particle(7.35e22u"kg",
    EARTH.position + Vec3d(3.844e8, 0.0, 0.0)u"m",
    EARTH.velocity + Vec3d(0, 1e3, 0)u"m/s")
# ~/~ end

end
# ~/~ end
