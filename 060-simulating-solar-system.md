---
title: Simulating the Solar System
---

::: questions
- How can I work with physical units?
- How do I quickly visualize some data?
- How is dispatch used in practice?
:::

::: objectives
- Learn to work with `Unitful`
- Take the first steps with `Makie` for visualisation
- Work with `const`
- Define a `struct`
:::

::: instructor

:::

In this episode we'll be building a simulation of the solar system. That is, we'll only consider the Sun, Earth and Moon, but feel free to add other planets to the mix later on! To do this we need to work with the laws of gravity.

## Introduction to `Unitful`
We'll be using the `Unitful` library to ensure that we don't mix up physical units.

```julia
using Unitful
```

Using `Unitful` is without any run-time overhead. The unit information is completely contained in the `Quantity` type.
With `Unitful` we can attach units to quantities using the `@u_str` syntax:

```julia
1.0u"kg" == 1000.0u"g"
```

```julia
2.0u"m" - 8.0u"cm"
```

::: challenge
### Try adding incompatible quantities
For instance, add a quantity in meters to one in seconds. Be creative. Can you understand the error messages?
:::

Next to that, we use the `Vec3d` type from `GeometryBasics` to store vector particle positions.

```julia
using GeometryBasics
```

Libraries in Julia tend to work well together, even if they're not principally designed to do so. We can combine `Vec3d` with `Unitful` with no problems.

```julia
Vec3d(1, 2, 3)u"km"
```

:::challenge
### Generate random Vec3d
The `Vec3d` type is a static 3-vector of double precision floating point
values. Read the documentation on the [`randn` function](https://docs.julialang.org/en/v1/stdlib/Random/#Base.randn).
Can you figure out a way to generate a random `Vec3d`?

::::solution
One way is to generate three random numbers and convert the resulting array to a `Vec3d`:

```julia
Vec3d(randn(Float64, 3))
```

But it is even better to call `randn` with the `Vec3d` argument directly:

```julia
randn(Vec3d)
```

(We can time these using `@btime` from `BenchmarkTools`)
::::
:::

## Particles
We are now ready to define the `Particle` type.

``` {.julia #gravity}
mutable struct Particle
	mass::typeof(1.0u"kg")
	position::typeof(Vec3d(1)u"m")
	velocity::typeof(Vec3d(1)u"m/s")
end
```

Two bodies of mass $M$ and $m$ attract each other with the force

$$F = \frac{GMm}{r^2},$$

where $r$ is the distance between those bodies, and $G$ is the universal gravitational constant.

``` {.julia #gravity}
const G = 6.6743e-11u"m^3*kg^-1*s^-2"
```

It is custom to divide the computation of orbits into a *kick* and *drift* function. (There are deep mathematical reasons for this that we won't get into.)
We'll first implement the `kick!` function, that updates a collection of particles, given a certain time step.

``` {.julia #gravity}
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
```

:::callout
### Why the `!` exclamation mark?
In Julia it is custom to have an exclamation mark at the end of names of functions that mutate their arguments.
:::

:::callout
### Use `eachindex`
Note the way we used `eachindex`. This idiom guarantees that we can't make out-of-bounds errors, and also this code is generic over different kinds of collections in Julia. We could have a `Vector{Particle}`, but a `Dict{Symbol, Particle}` would work just as well.
:::

Luckily the `drift!` function is much easier to implement, and doesn't require that we know about all particles.

``` {.julia #gravity}
function drift!(p::Particle, dt)
	p.position += dt * p.velocity
end

function drift!(particles, dt)
	for p in values(particles)
		drift!(p, dt)
	end
	return particles
end
```

Note that we defined the `drift!` function twice, for different arguments. We're using the dispatch mechanism to write clean/readable code.

### Fixing arguments
One pattern that you can find repeatedly in the standard library is that of *fixing* arguments of functions to make them more composable.
For instance, most comparison operators allow you to give a single argument, saving the second argument for a second invocation.

```julia
filter(x -> x < 3, 1:5)
filter(<(3), 1:5)
```

and even

```julia
map(filter(<(5)), eachcol(rand(1:10, 5, 5)))
```

We can do a similar thing here:

``` {.julia #gravity}
kick!(dt) = Base.Fix2(kick!, dt)
drift!(dt) = Base.Fix2(drift!, dt)
```

These kinds of identities let us be flexible in how to use and combine methods in different circumstances.

``` {.julia #gravity}
leap_frog!(dt) = drift!(dt) ∘ kick!(dt)
```

This defines the `leap_frog!` function as first performing a `kick!` and then a `drift!`. Another way to compose these functions is the `|>` operator.
In contrast to the `∘` operator, `|>` is very popular and seen everywhere in Julia code bases.

```julia
leap_frog!(particles, dt) = particles |> kick!(dt) |> drift!(dt)
leap_frog!(dt) = Base.Fix2(leap_frog!, dt)
```

## With random particles
Let's run a simulation with some random particles

``` {.julia #gravity}
function run_simulation(particles, dt, n)
	result = Matrix{typeof(Vec3d(1)u"m")}(undef, n, length(particles))
	x = deepcopy(particles)
	for c in eachrow(result)
		x = leap_frog!(dt)(x)
		c[:] = [p.position for p in values(x)]
	end
	DataFrame(:time => (1:n)dt, (Symbol.("p", keys(particles)) .=> eachcol(result))...)
end
```

``` {.julia #gravity}
function random_orbits(n, mass)
    random_particle() = Particle(mass, randn(Vec3d)u"m", randn(Vec3d)u"mm/s")
	particles = set_still!([random_particle() for _ in 1:n])
	run_simulation(particles, 1.0u"s", 5000)
end
```

### Plotting

```julia
function plot_orbits(orbits::DataFrame)
	fig = Figure()
	ax = Axis3(fig[1,1], limits=((-5, 5), (-5, 5), (-5, 5)))

    for colname in names(orbits)[2:end]
        scatter!(ax, [orbits[1,colname] / u"m"])
	    lines!(ax, orbits[!,colname] / u"m")
    end

	fig
end
```

Try a few times with two random particles. You may want to use the `set_still!` function to negate any collective motion.

### Frame of reference
We need to make sure that our entire system doesn't have a net velocity. Otherwise it will be hard to visualize our results!

``` {.julia #gravity}
function set_still!(particles)
	total_momentum = sum(p.mass * p.velocity for p in values(particles))
	total_mass = sum(p.mass for p in values(particles))
	correction = total_momentum / total_mass
	for p in values(particles)
		p.velocity -= correction
	end
	return particles
end
```

``` {.julia #gravity}
const SUN = Particle(2e30u"kg",
    Vec3d(0.0)u"m",
    Vec3d(0.0)u"m/s")

const EARTH = Particle(6e24u"kg",
    Vec3d(1.5e11, 0, 0)u"m",
    Vec3d(0, 3e4, 0)u"m/s")

const MOON = Particle(7.35e22u"kg",
    EARTH.position + Vec3d(3.844e8, 0.0, 0.0)u"m",
    EARTH.velocity + Vec3d(0, 1e3, 0)u"m/s")
```

::: challenge
## Challenge

Plot the orbit of the moon around the earth. Make a `Dataframe` that contains all model data, and work from there. Can you figure out the period of the orbit?
:::

``` {.julia file=examples/Gravity/src/Gravity.jl}
module Gravity

using Unitful
using GLMakie
using GeometryBasics
using DataFrames

<<gravity>>

end
```

::: keypoints
- `Plots.jl` is in some ways the 'standard' plotting package, but it is in fact quite horrible.
- `Makie.jl` offers a nice interface, pretty plots, is generally stable and very efficient once things have been compiled.
:::
