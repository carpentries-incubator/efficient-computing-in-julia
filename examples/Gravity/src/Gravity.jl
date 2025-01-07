# ~/~ begin <<episodes/060-plotting.md#examples/Gravity/src/Gravity.jl>>[init]
module Gravity

using Unitful
using GLMakie
using GeometryBasics

"""
## Challenge generate random Vec3d
The `Vec3d` type is a static 3-vector of double precision floating point
values. Read the documentation on the `randn` function. Can you figure out
a way to generate a random `Vec3d`?
"""

mutable struct Particle
	mass::typeof(1.0u"kg")
	position::typeof(Vec3d(1)u"m")
	velocity::typeof(Vec3d(1)u"m/s")
end

const SUN = Particle(2e30u"kg",
    Vec3d(0.0)u"m",
    Vec3d(0.0)u"m/s")

const EARTH = Particle(6e24u"kg",
    Vec3d(1.5e11, 0, 0)u"m",
    Vec3d(0, 29.8e3, 0)u"m/s")

const MOON = Particle(7.35e22u"kg",
    EARTH.position + Vec3d(3.844e8, 0.0, 0.0)u"m",
    EARTH.velocity + Vec3d(0, 1e3, 0)u"m/s")

const G = 6.6743e-11u"m^3*kg^-1*s^-2"

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

kick!(dt) = Base.Fix2(kick!, dt)

function drift!(p::Particle, dt)
	p.position += dt * p.velocity
end

function drift!(particles, dt)
	for p in particles
		drift!(p, dt)
	end
	return particles
end

drift!(dt) = Base.Fix2(drift!, dt)

leap_frog!(dt) = kick!(dt) ∘ drift!(dt)

function solve(step!, x, n)
	result = Array{typeof(x)}(undef, n)
	for i in eachindex(result)
		x = step!(x)
		result[i] = deepcopy(x)
	end
	return result
end

function set_still!(particles)
	total_momentum = sum(p.mass * p.velocity for p in particles)
	total_mass = sum(p.mass for p in particles)
	correction = total_momentum / total_mass
	for p in particles
		p.velocity -= correction
	end
	return particles
end

function plot_orbits()
	out = solve(leap_frog!(5.0e4u"s"), set_still!(deepcopy([SUN, EARTH, MOON])), 2000)
	
	fig = Figure()
	ax = Axis(fig[1,1])

    for i in 1:3
	    lines!(ax, [p[i].position[1] / u"m" for p in out], [p[i].position[2] / u"m" for p in out])
    end

	fig
end

function generate(f, n)
    Ts = Base.return_types(f, ())
    @assert length(Ts) == 1
    T = Ts[1]
    result = Vector{T}(undef, n)
    for i = 1:n
        result[i] = f()
    end
    return result
end

function plot_random_orbits(n, mass)
    random_particle() = Particle(mass, randn(Vec3d)u"m", randn(Vec3d)u"mm/s")

	out = solve(leap_frog!(1.0u"s"), set_still!(generate(random_particle, n)), 5000)
	
	fig = Figure()
	ax = Axis3(fig[1,1]) #, limits=((-5, 5), (-5, 5), (-5, 5)))

    for i in 1:n
        scatter!(ax, [out[1][i].position / u"m"])
	    lines!(ax, [p[i].position / u"m" for p in out])
    end

	fig
end

end
# ~/~ end