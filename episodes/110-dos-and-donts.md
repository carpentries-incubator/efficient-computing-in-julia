---
title: "Performance: do's and don'ts"
---

::: questions
- Can you give me some guiding principles on how to keep Julia code performant?
:::

::: objectives
- Identify potential problems with given code.
:::

The Julia documentation has a great chapter on [Performance Tips](https://docs.julialang.org/en/v1/manual/performance-tips/).

We follow the population model of the Spruce Budworm by May '77 (doi:10.1038/269471a0).

$$\frac{dN}{dt} = r N \left(1 - \frac[N}{K}]\right) - \frac{cN^2}{H^2 + N^2}$$

```julia
abstract type AbstractInput end
Broadcast.broadcastable(input::AbstractInput) = Ref(input)
struct Input <: AbstractInput
    reproduction_rate::Float64
    predation::Float64
    carrying_capacity::Float64
    characteristic_population::Float64
end

function growth_rate(input, N)
    r = input.reproduction_rate
    c = input.predation
    K = input.carrying_capacity
    H = input.characteristic_population

    return r*N*(1 - N/K) - c*N^2/(H^2 + N^2)
end
```

We can analyse the behaviour of this model. We'll fix the growth rate to 1.0, the carrying capacity to 10.0 and the characteristic population to 1.0, but vary the predation between 1 and 3.

```julia
using GLMakie

let
    N = 0:0.01:10.0
    fig = Figure()
    c_slider = Slider(fig[2, 2], range=1.0:0.01:3.0)
    c_label = Label(fig[2, 1], lift(c->"c = $c", c_slider.value))
    #r_slider = Slider(fig[3, 2], range=1.0:0.01:4.0)
    #r_label = Label(fig[3, 1], lift(r->"r = $r", r_slider.value))

    input(c) = Input(1.0, c, 10.0, 1.0)
    dN(c) = growth_rate.(input(c), N)
    ax = Makie.Axis(fig[1, 1:2], ylabel="dN", xlabel="N")
    lines!(ax, N, lift(dN, c_slider.value))
    fig
end
```

The points where the N-dN line crosses the axis are very important: these are equilibria, both stable and unstable ones.
At a predation rate of around 2.6 something special happens: a stable equilibrium dissapears, leaving only the stable equilibrium with a much lower population. If the predation rises beyond this 2.6 value, we should observe a sudden collapse of the population, also called a **catastrophe**.

```julia
function forward_euler(dy, y0, t_range)
    y = Vector{typeof(y0)}(undef, length(t_range))
    y[1] = y0
    t, t_rest... = t_range
    for (i, t_next) in enumerate(t_rest)
        dt = t_next - t
        y[i+1] = y[i] + dy(t, y[i]) * dt
        t = t_next
    end
    return y
end
```

```julia
let
    input(c) = Input(1.0, c, 10.0, 1.0)
    t = 0.0:0.1:25.0
    N = 0:0.01:10.0
    fig = Figure()
    c_slider = Slider(fig[2,2:3], range=1.0:0.01:3.0)
    Label(fig[2,1], lift(c->"c = $c", c_slider.value))
    y0_slider = Slider(fig[3,2:3], range=0.0:0.01:10.0)
    Label(fig[3,1], lift(y0->"y_0 = $y0", y0_slider.value))

    dN(c) = growth_rate.(input(c), N)
    ax1 = Makie.Axis(fig[1, 1:2], ylabel="dN", xlabel="N")
    lines!(ax1, N, lift(dN, c_slider.value))

    ax2 = Makie.Axis(fig[1, 3], ylabel="N", xlabel="t", limits=(nothing, (0.0, 8.0)))
    y = lift(c_slider.value, y0_slider.value) do c, y0
        forward_euler((t, y) -> growth_rate(input(c), y), y0, t)
    end
    lines!(ax2, t, y)
    fig
end
```

## Type Stability

:::callout
A good summary on type stability can be found in the following blog post:
- [Writing type-stable Julia code](https://www.juliabloggers.com/writing-type-stable-julia-code/)
:::

---

::: keypoints
- Don't use mutable global variables.
- Write your code inside functions.
- Specify element types for containers and structs.
- Specialize functions instead of doing manual dispatch.
- Write functions that always return the same type (type stability).
- Don't change the type of variables.
:::
