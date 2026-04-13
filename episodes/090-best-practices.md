---
title: Best practices
---

::: questions
- How do I setup unit testing?
- What about documentation?
- Are there good Github Actions available for CI/CD?
- I like autoformatters for my code - what is the best one for Julia?
- How can I make all this a bit easier?
:::

::: objectives
- tests
- documentation
- GitHub workflows
- JuliaFormatter.jl
:::


In this lesson, we will cover issues of best practices in Julia package development. In particular, this covers testing, documentation and formatting.

If you followed the instructions from the previous lesson (using the `BestieTemplate` to generate a package) then all these topics may already have been handled. However, this lesson assumes that only a basic `Pkg.generate()` was used, and we will build the additional structure manually. This is to better illustrate how Documentation, testing and other best practices work.

We will show how to take the Newtonian gravity code we developed earlier, and adapt it into the new package (`Newton.jl`) we created in the previous lesson.


## Preparing for developing

As before, we open the Julia REPL, activate our package and load `Revise`:
```shell
julia
julia> activate .
julia> using Revise
```


## Populate the src/ directory

From an earlier lesson we have the Newtonian gravity code. Let us add that code (you can copy-paste it in) to the `src/` directory of our package and save the file. After doing so, `src/Newton.jl` should look something like the following:


````julia
module Newton

using Unitful
using GeometryBasics
using LinearAlgebra
using Random

"""
Universal Gravitational Constant
"""
const G = 6.6743e-11u"m^3*kg^-1*s^-2"

"""
    gravitation_force(m1, m2, r)

Takes `r` to be the scalar distance between two objects of masses `m1` and `m2`.
Returns the strength of the force of gravitational attraction between the
two objects.
"""
gravitational_force(m1, m2, r) =
    G * m1 * m2 / r^2

"""
    gravitational_force(m1, m2, r::AbstractVector)

Takes `r` to be the distance vector between two objects of masses `m1` and `m2`.
Returns the gravitational force due to Newton's law in of the direction `r`.
"""
gravitational_force(m1, m2, r::AbstractVector) =
	r * (G * m1 * m2 * (r ⋅ r)^(-1.5))

"""
Type for masses in units of kilograms.
"""
const Mass = typeof(1.0u"kg")

"""
Type for a 3d momentum vector in units of Newton seconds.
"""
const MomentumVector = typeof(Vec3d(1)u"kg*m/s")

"""
Type for a 3d position in vector in units of meters.
"""
const PositionVector = typeof(Vec3d(1)u"m")

"""
Type for a 3d velocity vector in units of meters per second.
"""
const VelocityVector = typeof(Vec3d(1)u"m/s")

"""
    Particle(mass, position, momentum)

Particle structure. The `position` and `momentum` should be 3-vectors with the correct units,
and `mass` a scalar mass.
"""
mutable struct Particle
    mass::Mass
    position::PositionVector
    momentum::MomentumVector
end

mass(p::Particle) = p.mass
position(p::Particle) = p.position
momentum(p::Particle) = p.momentum

mass(p::AbstractArray{Particle}) = sum(mass, p)
momentum(p::AbstractArray{Particle}) = sum(momentum, p)
velocity(p) = momentum(p) / mass(p)

"""
    random_particle(mass=1e6"kg", spread=1.0u"m", dispersion=2.0u"mm/s")

Generate a particle with given `mass`, but random position and velocity.
The position and velocity are drawn from a normal distribution and scaled
with given `spread` and `dispersion`.

The default values are chosen to give a high probability for interesting
behaviour.
"""
random_particle(mass=1e6u"kg", spread=1.0u"m", dispersion=2.0u"mm/s") =
    Particle(mass, randn(Vec3d) * spread, randn(Vec3d) * dispersion * mass)

"""
    random_particles(n; seed=0, args...)

Generate `n` random particles with a given random seed. Extra keyword
arguments `args...` are forwarded to the `random_particle` function.
"""
function random_particles(n; seed=0, args...)
    Random.seed!(seed)
    [random_particle(args...) for _ in 1:n]
end

"""
    set_still!(particles)

Computes the net velocity of a set of particles, and changes the momentum
of each particle to match this frame of reference.

Returns the particle set.
"""
function set_still!(particles)
    v = velocity(particles)
    for p in particles
        p.momentum -= v * mass(p)
    end
    return particles
end

"""
    kick!(particles::AbstractVector{Particle}, dt)

Change the momentum of a each particle in the vector `particles`, following
direct one-to-one computation of their respective attractive forces.
"""
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

"""
    potential_energy(particles::AbstractVector{Particle})

Computes the potential energy of the system of particles.
"""
function potential_energy(particles)
    total = 0.0u"J"
    for i in eachindex(particles)
        for j in 1:(i-1)
            r = particles[j].position - particles[i].position
            m1 = particles[i].mass
            m2 = particles[j].mass
            total -= G * m1 * m2 / sqrt(r ⋅ r)
        end
    end
    return total
end

"""
    kinetic_energy(p::Particle)

Compute the kinetic energy of a particle.
"""
kinetic_energy(s::Particle) = let p = momentum(s)
    (p ⋅ p) / (2 * mass(s))
end

kinetic_energy(particles::AbstractVector{Particle}) =
    sum(kinetic_energy(p) for p in particles)

total_energy(particles::AbstractVector{Particle}) =
    potential_energy(particles) + kinetic_energy(particles)

"""
    drift!(p::Particle, dt)

Evolve the position of particle `p` for a time `dt` from its given momentum.
"""
function drift!(p::Particle, dt)
    p.position += dt * p.momentum / p.mass
end

"""
    drift!(particles: AbstractVector{Partcile}, dt)

Evolve the position of all particles.
"""
function drift!(particles, dt)
    for p in particles
        drift!(p, dt)
    end
    return particles
end

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

"""
    run_simulation(particles, dt, n_steps)

Leap-frog a set of particles `n_steps` times for a time step `dt`.
Copies the particle set after every iteration, returning a
vector containing the full state for each time step.
"""
function run_simulation(particles, dt, n_steps)
    x = deepcopy(particles)
    [deepcopy(leap_frog!(x, dt)) for _ in 1:n_steps]
end

"""
    random_orbits(n, mass; dt=1.0u"s", steps=5000, args...)

Generate random orbits of `n` particles with given `mass`.
"""
function random_orbits(n, mass; dt=1.0u"s", steps=5000, args...)
    particles = random_particles(n; args...)
    run_simulation(particles, dt, steps) |> collect
end

end  # module Newton
````

Before using this, we will need to add the dependencies to the project environment:
```
pkg> add Unitful GeometryBasics LinearAlgebra Random
```


Now let us load our package and attempt to use e.g. the `gravitational_force()` function:

```shell
julia> using Newton
julia> Newton.gravitational_force(1, 1, 1)
```

```output
6.6743e-11 m^3 kg^-1 s^-2
```

### Testing

#### Testing sanity
If we are to develop our package further, we may worry that any changes we make might break existing functionality. For this reason, it is important to add automated tests that can tell us immediately if the behaviour of our existing functions has changed.


First, let's add a new directory: `Newton.jl/test/`. In that directory, we add a new file called `runtests.jl`. 

We can start with an example test to illustrate how it works:
```julia
module Spec

using Test

@testset "Newton.jl" begin
    @testset "testing sanity" begin
        @test 1 + 1 == 2
    end
end

end
```

`@testset` is used to define a suite of many tests, while `@test` defines a single check. In this case, there is one test and it checks that 1 + 1 indeed equals 2.


And we will also register this `test/` "sub-project" to the main package's Project.toml, by adding the following:

```shell
[workspace]
projects = ["test"]
```

:::callout
The "workspace" feature is new to Julia 1.12, so will not work with older versions. It is useful because it allows sub-projects to have their own specific dependencies, but only one `Manifest.toml` for the whole project (and thus functioning as a single environment).
:::


#### Creating a test environment

To run our test, we first need to add the standard Julia `Test` package:
```shell
cd test/
julia
pkg> activate .
pkg> add Test
```

Here we have added the `Test` dependency to a different environment, specifically for testing. This means the `test/` directory now has its own `Project.toml`. This is useful for keeping testing-specific dependencies out of the main project dependencies, as an end user of our package may not care about such development tooling.


We will also add the main (`Newton.jl`) package as a dependency of the test environment, as well as the `Unitful` dependency - we will need theses to be able to test our package later.

```shell
pkg> dev .. # Add the main Newton package we want to test as a development dependency
pkg> add Unitful
```

We can now activate the main package environment again, and apply/install the new dependency we added.
```shell
cd .. # Return to Newton.jl/ directory
julia
pkg> activate .
```

In some cases you may need to run `pkg> resolve` and `pkg> instantiate` because we added a new dependency (`Test`) to our sub-project "test", but this has not actually been downloaded and installed yet. If the workspace was added before creating the test environment (i.e. there is no `Manifest.toml` in `test/`) then this should not be necessary.

After running these commands you will see that our test dependencies have appeared in the `Manifest.toml` for the main package.

#### Running the test

Having added the necessary dependencies, we can now run all tests for our package by simply typing `test` from the Julia `pkg>` prompt:
```shell
pkg> test
```

Hopefully the outcome will show a passing test i.e. proving that 1 + 1 = 2.

:::challenge
#### Massive attraction


Add a test to verify that the `Newton.gravitational_force()` function returns a force greater than zero for two 1 kg masses 1 metre apart.

What about a test for a zero attraction case?

Hint: If we are using `Unitful` then we must specify the units of any values.


::::solution

Here is the modified `test/runtests.jl` file with the added gravitational check:
```julia
module Spec

using Newton, Test, Unitful

@testset "Newton.jl" begin
    @testset "testing sanity" begin
        @test 1 + 1 == 2
        @test Newton.gravitational_force(1u"kg",1u"kg",1u"m") > 0u"N"
        @test Newton.gravitational_force(0u"kg",0u"kg",1u"m") == 0u"N"
    end

end

end
```

Then, running `pkg> test` should result in a pass.

::::
:::

#### Testing the functionality of Newton.jl
We can also add some more comprehensive tests, testing the energy conservation of a group of 3 particles.


```julia
module Spec

using Newton, Test, Unitful
using Newton: set_still!, random_particles, momentum, MomentumVector, run_simulation,
    total_energy

@testset "Newton.jl" begin
    @testset "testing sanity" begin
        @test 1 + 1 == 2
        @test Newton.gravitational_force(1u"kg",1u"kg",1u"m") > 0u"N"
        @test Newton.gravitational_force(0u"kg",0u"kg",1u"m") == 0u"N"
    end

    @testset "run $i" for i in 1:10
        p = set_still!(random_particles(3, seed=i))
        @test momentum(p) ≈ zero(MomentumVector) atol=1e-6u"N*s"

        orbit = run_simulation(p, 0.1u"s", 1000)
        @test momentum(orbit[end]) ≈ zero(MomentumVector) atol=1e-6u"N*s"
        @test total_energy(orbit[1]) ≈ total_energy(orbit[end]) rtol=1e-6
    end
end

end  # module Spec
```



### Documentation

#### Documenting `gravitational_force()`


Our `kinetic_energy()` function has a docstring before it:

```julia
"""
    kinetic_energy(p::Particle)

Compute the kinetic energy of a particle.
"""
```

This is low-level technical documentation for this particular function. 

#### Using the REPL help mode
In the Julia REPL, pressing `?` will enter help mode. You can then type the name of a function you would like documentation about:
```shell
julia> # Press '?'
help?> Newton.kinetic_energy()
```

```output
  │ Warning
  │
  │  The following bindings may be internal; they may change or be removed in future versions:
  │
  │    •  Newton.kinetic_energy

  kinetic_energy(p::Particle)

  Compute the kinetic energy of a particle.
```


#### Building the docs
The standard package for building beautiful documentation websites for Julia packages is `Documenter.jl`.

As we did for testing, we will add a directory (`docs/`) and an environment for any docs-specific dependencies.

```shell
mkdir docs/
```

Modify the `Project.toml` workspace section:
```shell
[workspace]
projects = ["test", "docs"]
```

Add `Documenter.jl` (the package used for building the documentation) and `LiveServer` (a package that lets us serve the pages locally):

```shell
julia --project=docs
pkg> add Documenter LiveServer Newton
```

Then add two files to the docs structure:

`docs/make.jl`
```julia
using Newton, Documenter, LiveServer
makedocs(remotes=nothing, sitename="Newton.jl")
```

`docs/src/index.md`:
````julia
```@autodocs
Modules = [Newton]
```
````

Then we can build the documentation and serve it using the following:
```shell
julia --project=docs -e 'using LiveServer; servedocs()'
```

There will be a lot of output and some warnings, but hopefully you will eventually see:
```output
✓ LiveServer listening on http://localhost:8000/ ...
```
Or something similar. Open this link in your web browser to see the rendered documentation.

When done, use `Ctrl+C` to stop the running server:


:::challenge
# Testing the examples in your documentation
In the 'Reference' section of the documentation website we just generated, you will find the `gravitational_force()` function with its docstring nicely rendered.

But did you know we can add an example of usage to this docstring and have it be tested automatically during the standard docs build?

Consider the following example function's docstring:

````julia
"""
    roots = cubic_roots(a, b, c, d)

    Returns the roots of a cubic polynomial defined by ax^3 + bx^2 + cx + d = 0

```jldoctest
julia> roots = MyPackage.cubic_roots(0, 0, 0, 0)
(0.0 + 0.0im, NaN + NaN*im, NaN + NaN*im)
```
"""
function cubic_roots(a, b, c, d)
````

When the documentation is built, the example in the `jldoctest` block will be run and its output verified.

Can you do something similar to add a tested example to our `gravitational_force()` function's docstring?


::::solution

We can add the `jldoctest` block as follows:

````julia
"""
    gravitation_force(m1, m2, r)

Takes `r` to be the scalar distance between two objects of masses `m1` and `m2`.
Returns the strength of the force of gravitational attraction between the
two objects.

```jldoctest
julia> gravitational_force(1u"kg",1u"kg",1u"m")
6.6743e-11 kg m s^-2
```
"""
````

The example given in the `jldoctest` block is actually run and the output checked during documentation building.
You can test this yourself by changing the arguments to `gravitational_force()` and running again. The output will no longer match that in the comment and the
documentation build will fail. This is a nice solution to a common problem in many languages where the documentation examples fall out of sync with the
package development.

::::
:::



### Formatting
A good automatic formatter for Julia is `JuliaFormatter.jl`

```shell
pkg> add JuliaFormatter
julia> using JuliaFormatter
```

Then you can try it out on our source file:

```shell
julia> format("src/Newton.jl")
```

Try making some changes to the source file (save the file afterwards!) and running this line again. You will see the formatter make modifications to the code.

In practice, you will not run this formatter manually, but rather automate it with various workflows. This course does not focus on these (largely they are integrated with `git` and e.g. `GitHub`) but they are helpful with ensuring a clean code base with minimal effort.

:::callout
For educational purposes, this lesson has focussed on manually operating the various tools needed for applying best practices in Julia development. In practice, you should use a template from `PkgTemplates.jl` or 'BestieTemplate.jl' to automate the set up of such a repository and CI workflows integrated with the git forge you wish to use.
:::


::: keypoints
- Julia has integrated support for unit testing.
- `Documenter.jl` is the standard package for generating documentation.
- The Julia ecosystem is well equiped to help you keep your code in fit shape.
:::

