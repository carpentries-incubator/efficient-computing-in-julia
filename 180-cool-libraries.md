---
title: Recap and Recommended libraries
---

::: questions
- Is there a recommended set of standard libraries?
- What is the equivalent of SciPy in Julia.
:::

::: objectives
- Get street-wise.
:::

This is a nice closing episode.

## Notebooks

Use `Pluto.jl`!

## Reactive programming

At several points in this lesson we saw the use of `Observables.jl` to create interactive demos with `Makie.jl`. If you want to build more complicated interfaces, you may want to take a look at `GtkObservables.jl`.

```julia
using Observables
x = Observable(3.0)
y = map(sqrt, x)

x[] = 25.0
y[]
```

## Logging and Progress bars

Logging is done through the [`Logging` library](https://docs.julialang.org/en/v1/stdlib/Logging/) that is part of the standard library.

```julia
using Logging

@warn "Hello, World!"
```

While there is a package called `ProgressBars.jl` that seems quite popular, it is better to use `ProgressLogging.jl` to log progress of a computation. This utility hooks into the logging system and integrates well with Pluto and VS Code.

```julia
using ProgressLogging

@progress for i in 1:100
    sleep(0.02)
end
```

## Parallel pipelines

We've seen that we can use `IterTools.jl` to extend the functionality of standard Julia `Iterators`, at only a marginal performance hit.

The `Transducers.jl` package is a fundamental when building pipelines for parallel processing. Transducers are an interesting concept from functional programming, developed by the great Rich Hickey of Clojure fame. Several packages build on top of `Transducers.jl` with a more imperative interface, `FLoops.jl` for instance.

## SciML-verse

There is a large group of libraries managed by the same group under the nomer `SciML`. These libraries are focussed on scientific modelling and machine learning. Some of these libraries are incredibly useful on their own:

- `Symbolics.jl` for symbolic computation
- `Integrals.jl` for numeric integration
- `DifferentialEquations.jl` for solving differential equations
- `MethodOfLines.jl` for solving PDEs

etc.

These libraries are very powerful and offer highly abstracted interfaces to problems. The downside is that they pull in a massive amount of dependencies
(While this is also true for a package like `Makie.jl`, plotting is usually not a core buisness for a package, so `Makie` will usually be an optional dependency. The same can't be said of numerical algorithms). Also, the high level of abstraction means that code can be hard to debug.

---

::: keypoints
- SciML toolkit is dominant but not always the best choice.
- Search for libraries that specify your needs.
:::


