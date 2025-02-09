---
title: Type Stability
---

::: questions
- What is type stability?
- Why is type stability so important for performance?
- What is the origin of type unstable code? How can I prevent it?
:::

::: objectives
- Learn to diagnose type stability using `@code_warntype` and `@profview`
- Understand how and why to avoid global mutable variables.
- Analyze the problem when passing functions as members of a struct.
:::

In this episode we will look into **type stability**, a very important topic when it comes to writing efficient Julia. We will first show some small examples, trying to explain what type stability means and how you can create code that is not type stable. Then we will have two examples: one computing the growth of a coral reef under varying sea level, the other computing the value of $\pi$ using the Chudnovsky algorithm.

```julia
using BenchmarkTools
```

## Type stability
If types cannot be inferred at compile time, a function cannot be entirely compiled to machine code. This means that evaluation will be slow as molasses.
One example of a type instability is when a function's return type depends on run-time values:

```julia
function safe_inv(x::T) where {T}
    if x == zero(T)
        nothing
    else
        one(T) / x
    end
end
```

```julia
@code_warntype safe_inv(-2:2)
```

In this case we may observe that the induced type is `Union{Nothing, T}`. If we run `@code_warntype` we can see the yellow highlighting of the union type. Having union-types can be hint that the compiler is in uncertain territory. However, union types are at the very core of how Julia approaches iteration and therefore for-loops, so usually this will not lead to run-time dispatches being triggered.

The situation is much worse when mutable globals are in place.

```julia
x = 5

replace_x(f, vs) = [(f(v) ? x : v) for v in vs]

replace_x((<)(0), -2:2)

@code_warntype replace_x((<)(0), -2:2)
```

We can follow this up with:

```julia
x = "sloppy code!"

replace_x((<)(0), -2:2)
```

:::challenge
### Use parameters or `const`
Change the definition of `replace_x` by passing `x` as a parameter.
Change the definition of `x` to a constant using `const`.
Time the result against the type unstable version.
:::

## Functions in structs
Every function has its own unique type. This can be a problem when we want to get some functional user input. The following computes the sedimentation history of a coral reef, following a paper by Bosscher & Schlager 1992:

$$\frac{\partial y}{\partial t} = g_m \tanh \left(\frac{I_0 \exp(-kw)}{I_k}\right),$$

where $g_m$ is the maximum growth rate, $I_0$ is the insolation (light intensity at sea-level), $I_k$ the saturation intensity, $k$ the extinction coefficient and $w$ the waterdepth, being $sl(t) - y + \sigma*t$, where $sl(t)$ is the sea level and $\sigma$ is the subsidence rate. The model uses the $\tanh$ function to interpolate between maximum growth and zero growth, modified by the exponential extinction of sun light as we go deeper into the water. Details don't matter much, the point being that we'd like to be able to specify the sea level as an input parameter in functional form.

```julia
using Unitful
using GLMakie

@kwdef struct Input
    "The sea level as a function of time"
    sea_level = _ -> 0.0u"m"

    "Maximum growth rate of the coral, in m/Myr"
    maximum_growth_rate::typeof(1.0u"m/Myr") = 0.2u"mm/yr"

    "The light intensity at which maximum growth is attained, in W/m^2"
    saturation_intensity::typeof(1.0u"W/m^2") = 50.0u"W/m^2"

    "The rate at which growth rate drops every meter of water depth, in 1/m"
    extinction_coefficient::typeof(1.0u"m^-1") = 0.05u"m^-1"

    "The light intensity of the Sun, in W/m^2"
    insolation::typeof(1.0u"W/m^2") = 400.0u"W/m^2"

    "Subsidence rate is the rate at which the plateau drops, in m/Myr"
    subsidence_rate::typeof(1.0u"m/Myr") = 50.0u"m/Myr"
end

function growth_rate(input)
    sea_level = input.sea_level
    function df(y, t)
        # w = input.sea_level(t) - y + input.subsidence_rate * t
        w = sea_level(t) - y + input.subsidence_rate * t
        g_m = input.maximum_growth_rate
        I_0 = input.insolation
        I_k = input.saturation_intensity
        k = input.extinction_coefficient

        w > 0u"m" ? g_m * tanh(I_0 * exp(-k * w) / I_k) : 0.0u"m/Myr"
    end
end
```

```julia
function forward_euler(df, y0::T, t) where {T}
    result = Vector{T}(undef, length(t) + 1)
    result[1] = y = y0
    dt = step(t)

    for i in eachindex(t)
        y = y + df(y, t[i]) * dt
        result[i+1] = y
    end
    
    return result
end
```

```julia
let input = Input(sea_level=t->20.0u"m" * sin(2π*t/200u"kyr"))
    initial_topography = (0.0:-1.0:-100.0)u"m"
    result = stack(forward_euler(growth_rate(input), y0, (0.0:0.001:1.0)u"Myr")
        for y0 in initial_topography) .- 1.0u"Myr" * input.subsidence_rate
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="y0", ylabel="y", xreversed=true)
    for r in eachrow(result[1:20:end,:])
        lines!(ax, initial_topography/u"m", r/u"m", color=:black)
    end
    fig
end
```

What is wrong with this code?

```julia
let input = Input(sea_level=t->20.0u"m" * sin(2π*t/200u"kyr")),
    y0 = -50.0u"m"
    @code_warntype forward_euler(growth_rate(input), y0, (0.0:0.001:1.0)u"Myr")
end
```

The function in `Input` is untyped. We could try to type the argument with a type parameter, but that doesn't work so well with `@kwdef` (we'd have to redefine the constructor). The problem is also fixed if we recapture the `sea_level` parameter in the local scope of the `growth_rate` function, see [Performance Tips](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-captured).

:::challenge
### Fix the code
Modify the `growth_rate` function such that the `sea_level` look-up becomes type stable. Assign the parameter to a value with local scope.

::::solution

```julia
function growth_rate(input)
    sea_level = input.sea_level
    function df(y, t)
        w = sea_level(t) - y + input.subsidence_rate * t
        g_m = input.maximum_growth_rate
        I_0 = input.insolation
        I_k = input.saturation_intensity
        k = input.extinction_coefficient

        w > 0u"m" ? g_m * tanh(I_0 * exp(-k * w) / I_k) : 0.0u"m/Myr"
    end
end
```

```julia
let input = Input(sea_level=t->20.0u"m" * sin(2π*t/200u"kyr")),
    y0 = -50.0u"m"
    @code_warntype forward_euler(growth_rate(input), y0, (0.0:0.001:1.0)u"Myr")
end
```
::::
:::

## Multi-threading and type stability
Here we have an algorithm that computes the value of π to high precision. We can make this algorithm parallel by recursively calling `Threads.@spawn`, and then `fetch` on each task. Unfortunately the return type of `fetch` is never known at compile time. We can keep the type instability localized by declaring the return types.

The following algorithm is [copy-pasted from Wikipedia](https://en.wikipedia.org/wiki/Chudnovsky_algorithm).

```julia
function binary_split_1(a, b)
    Pab = -(6*a - 5)*(2*a - 1)*(6*a - 1)
    Qab = 10939058860032000 * a^3
    Rab = Pab * (545140134*a + 13591409)
    return Pab, Qab, Rab
end

setprecision(20, base=30) do
    _, q, r = binary_split_1(big(1), big(2))
    (426880 * sqrt(big(10005.0)) * q) / (13591409*q + r)
end

# The last few digits are wrong... check
setprecision(20, base=30) do
    π |> BigFloat
end

# The algorithm refines by recursive binary splitting
# Recursion is fine here: we go 2logN deep.

function binary_split(a, b)
    if b == a + 1
        binary_split_1(a, b)
    else
        m = div(a + b, 2)
        Pam, Qam, Ram = binary_split(a, m)
        Pmb, Qmb, Rmb = binary_split(m, b)
        
        Pab = Pam * Pmb
        Qab = Qam * Qmb
        Rab = Qmb * Ram + Pam * Rmb
        return Pab, Qab, Rab
    end
end

function chudnovsky(n)
    P1n, Q1n, R1n = binary_split(big(1), n)
    return (426880 * sqrt(big(10005.0)) * Q1n) / (13591409*Q1n + R1n)
end

setprecision(10000)
@btime chudnovsky(big(20000))

# We can create a parallel version by spawning jobs. These are green threads.

function binary_split_td(a::T, b::T) where {T}
    if b == a + 1
        binary_split_1(a, b)
    else
        m = div(a + b, 2)
        t1 = @Threads.spawn binary_split_td(a, m)
        t2 = @Threads.spawn binary_split_td(m, b)

        Pam, Qam, Ram = fetch(t1)
        Pmb, Qmb, Rmb = fetch(t2)
        
        Pab = Pam * Pmb
        Qab = Qam * Qmb
        Rab = Qmb * Ram + Pam * Rmb
        return Pab, Qab, Rab
    end
end

function chudnovsky_td(n)
    P1n, Q1n, R1n = binary_split_td(big(1), n)
    return (426880 * sqrt(big(10005.0)) * Q1n) / (13591409*Q1n + R1n)
end
```

The following may show why the parallel code isn't faster yet.

```julia
setprecision(10000)
@btime chudnovsky_td(big(20000))
@profview chudnovsky_td(big(200000))
```

```julia
@code_warntype chudnovsky_td(big(6))
```

- The red areas in the flame graph show type unstable code (marked with **run-time dispatch**)
- Yellow regions are allocations.
- The same can be seen in the code, as a kind of histogram back drop.

The code is also inefficient because `poptask` is very prominent. We can make sure that each task is a bit beefier by reverting to the serial code at some point. Insert the following in `binary_split_td`:

```julia
elseif b - a <= 1024
    binary_split(a, b)
```

We can limit the type instability by changing the `fetch` lines:

```julia
Pam::T, Qam::T, Ram::T = fetch(t1)
Pmb::T, Qmb::T, Rmb::T = fetch(t2)
```

::: challenge
### Rerun the profiler
Rerun the profiler and `@code_warntype`. Is the type instability gone?

:::: solution

```julia
function binary_split_td(a::T, b::T) where {T}
    if b == a + 1
        binary_split_1(a, b)
    elseif b - a <= 1024
        binary_split(a, b)
    else
        m = div(a + b, 2)
        t1 = @Threads.spawn binary_split_td(a, m)
        t2 = @Threads.spawn binary_split_td(m, b)

        Pam::T, Qam::T, Ram::T = fetch(t1)
        Pmb::T, Qmb::T, Rmb::T = fetch(t2)
        
        Pab = Pam * Pmb
        Qab = Qam * Qmb
        Rab = Qmb * Ram + Pam * Rmb
        return Pab, Qab, Rab
    end
end
```

Yes!
::::

:::

:::callout
A good summary on type stability can be found in the following blog post:
- [Writing type-stable Julia code](https://www.juliabloggers.com/writing-type-stable-julia-code/)
:::

---

::: keypoints
- Type instabilities are the bane of efficient Julia
- We can discover type instability using `@profview`, and analyze further using `@code_warntype`.
- Don't use mutable global variables.
- Write your code inside functions.
- Specify element types for containers and structs.
:::


