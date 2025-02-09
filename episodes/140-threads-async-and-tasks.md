---
title: Threads, ASync and Tasks
---

::: questions
- How do we distribute work across threads?
:::

::: objectives
- Change for-loops to run parallel.
- Launch tasks and generate results asynchronously.
:::

```julia
#| file: src/GrayScott.jl
module GrayScott
end
```

::: spoiler
### Using SciML stack

I've tried integrating the Gray-Scott model using libraries from the SciML toolkit. However, the following code, directly modified from their documentation doesn't give anything within reasonable time. In my opinion this is symptomatic for most of the SciML stack. It never really works and you never discover why.

```julia
using ModelingToolkit, MethodOfLines, DomainSets, OrdinaryDiffEq

function gray_scott_model(F, k, Du, Dv, N, order=2)
    @parameters x y t
    @variables u(..) v(..)

    Dt = Differential(t)
    Dx = Differential(x)
    Dy = Differential(y)
    Dxx = Dx^2
    Dyy = Dy^2

    Δ(u) = Dxx(u) + Dyy(u)

    x_min = y_min = t_min = 0.0
    x_max = y_max = 1.0
    t_max = 10.0

    u0(x, y) = 0.01 * exp((-(x - 0.5)^2 - (y - 0.5)^2) / (2 * 0.1^2)) / (sqrt(2pi) * 0.1)
    v0(x, y) = 1.0 - u0(x, y)

    eqs = let v = v(x, y, t),
              u = u(x, y, t)
        [Dt(u) ~ -u * v^2 + F * (1 - u) + Du * Δ(u),
         Dt(v) ~ u * v^2 - (F + k) * v + Dv * Δ(v)]
    end

    domains = [x in Interval(x_min, x_max),
               y in Interval(y_min, y_max),
               t in Interval(t_min, t_max)]

    bcs = [u(x,y,0) ~ u0(x,y),
           u(0,y,t) ~ u(1,y,t),
           u(x,0,t) ~ u(x,1,t),

           v(x,y,0) ~ v0(x,y),
           v(0,y,t) ~ v(1,y,t),
           v(x,0,t) ~ v(x,1,t)]

    @named pdesys = PDESystem(eqs, bcs, domains, [x, y, t], [u(x, y, t), v(x, y, t)])
    discretization = MOLFiniteDifference([x=>N, y=>N], t, approx_order=order)
    return discretize(pdesys, discretization)
end

problem = gray_scott_model(0.055, 0.062, 0.02, 0.04, 256)
solve(problem, TRBDF2(), saveat=0.1)
```
:::

---

::: keypoints
- Basic parallel for-loops are done with the `@threads` macro.
- Julia has built-in support for atomics.
- Channels are primary means of asynchronous communication.
:::


