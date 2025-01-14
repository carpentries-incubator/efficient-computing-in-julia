---
title: Reducing allocations on the Logistic Map
---

::: questions
- How can I reduce the number of allocations?
:::

::: objectives
- Apply a code transformation to write to pre-allocated memory.
:::

Logistic growth (in economy or biology) is sometimes modelled using the recurrence formula:

$$N_{i+1} = r N_{i} (1 - N_{i}),$$

also known as the **logistic map**, where $r$ is the **reproduction factor**. For low values of $N$ this behaves as exponential growth. However, most growth processes will hit a ceiling at some point. Let's try:

```julia
logistic_map(r) = n -> r * n * (1 - n)
```

```julia
using IterTools
using GLMakie
using .Iterators: take, flatten
```

```julia
take(iterated(logistic_map(3.0), 0.001), 200) |> collect |> lines
```

::: challenge
### Vary `r`
Try different values of $r$, what do you see?

Extra (advanced!): see the [Makie documention on `Slider`](https://docs.makie.org/stable/reference/blocks/slider). Can you make an interactive plot?

:::: solution
```julia
let
    fig = Figure()
    sl_r = Slider(fig[2, 2], range=1.0:0.001:4.0, startvalue=2.0)
    Label(fig[2,1], lift(r->"r = $r", sl_r.value))
    points = lift(sl_r.value) do r
        take(iterated(logistic_map(r), 0.001), 50) |> collect
    end
    ax = Axis(fig[1, 1:2], limits=(nothing, (0.0, 1.0)))
    plot!(ax, points)
    lines!(ax, points)
    fig
end
```
::::
:::

There seem to be key values of $r$ where the iteration of the logistic map splits into periodic orbits, and even get into chaotic behaviour.

We can plot all points for an arbitrary sized orbit for all values of $r$ between 2.6 and 4.0. First of all, let's see how the `iterated |> take |> collect` function chain performs.

```julia
using BenchmarkTools
@btime take(iterated(logistic_map(3.5), 0.5), 10000) |> collect
```

```julia
function iterated_fn(f, x, n)
    result = Float64[]
    for i in 1:n
        x = f(x)
        push!(result, x)
    end
    return result
end

@btime iterated_fn(logistic_map(3.5), 0.5, 10000)
```

That seems to be slower than the original! Let's try to improve:

```julia
function iterated_fn(f, x, n)
    result = Vector{Float64}(undef, n)
    for i in 1:n
        x = f(x)
        result[i] = x
    end
    return result
end

@benchmark iterated_fn(logistic_map(3.5), 0.5, 10000)
```

We can do better if we don't need to allocate:

```julia
function iterated_fn!(f, x, out)
    for i in eachindex(out)
        x = f(x)
        out[i] = x
    end
end

out = Vector{Float64}(undef, 10000)
@benchmark iterated_fn!(logistic_map(3.5), 0.5, out)
```

```julia
function logistic_map_points(r::Real, n_skip)
    make_point(x) = Point2f(r, x)
    x0 = nth(iterated(logistic_map(r), 0.5), n_skip)
    Iterators.map(make_point, iterated(logistic_map(r), x0))
end

@btime takestrict(logistic_map_points(3.5, 1000), 1000) |> collect
```

```julia
function logistic_map_points(rs::AbstractVector{R}, n_skip, n_take) where {R <: Real}
    Iterators.flatten(Iterators.take(logistic_map_points(r, n_skip), n_take) for r in rs) 
end

@benchmark logistic_map_points(LinRange(2.6, 4.0, 1000), 1000, 1000) |> collect
```

First of all, let's visualize the output because its so pretty!

```julia
let
    pts = logistic_map_points_td(LinRange(2.6, 4.0, 10000), 1000, 10000)
	fig = Figure(size=(800, 700))
	ax = Makie.Axis(fig[1,1], limits=((2.6, 4.0), nothing))
	datashader!(ax, pts, async=false, colormap=:deep)
	fig
end
```

```julia
@profview logistic_map_points(LinRange(2.6, 4.0, 1000), 1000, 1000) |> collect
```

```julia
function collect!(it, tgt)
    for (i, v) in zip(eachindex(tgt), it)
        tgt[i] = v_map(r) = n -> r 
    end
end

function logistic_map_points_td(rs::AbstractVector{R}, n_skip, n_take) where {R <: Real}
    result = Matrix{Point2}(undef, n_take, length(rs))
    # Threads.@threads for i in eachindex(rs)
    for i in eachindex(rs)
        collect!(logistic_map_points(rs[i], n_skip), view(result, :, i))
    end
    return reshape(result, :)
end

@benchmark logistic_map_points_td(LinRange(2.6, 4.0, 1000), 1000, 1000)
@profview logistic_map_points_td(LinRange(2.6, 4.0, 10000), 1000, 1000)
```

:::challenge
### Rewrite the `logistic_map_points` function
Rewrite the last function, so that everything is in one body (Fortran style!). Is this faster than using iterators?

::::solution
```julia
function logistic_map_points_raw(rs::AbstractVector{R}, n_skip, n_take, out::AbstractVector{P}) where {R <: Real, P}
    # result = Array{Float32}(undef, 2, n_take, length(rs))
    # result = Array{Point2f}(undef, n_take, length(rs))
    @assert length(out) == length(rs) * n_take
    # result = reshape(reinterpret(Float32, out), 2, n_take, length(rs))
    result = reshape(out, n_take, length(rs))
    for i in eachindex(rs)
        x = 0.5
        r = rs[i]
        for _ in 1:n_skip
            x = r * x * (1 - x)
        end
        for j in 1:n_take
            x = r * x * (1 - x)
            result[j, i] = P(r, x)
            #result[1, j, i] = r
            #result[2, j, i] = x
        end
        # result[1, :, i] .= r
    end
    # return reshape(reinterpret(Point2f, result), :)
    # return reshape(result, :)
    out
end

out = Vector{Point2d}(undef, 1000000)
logistic_map_points_raw(LinRange(2.6, 4.0, 1000), 1000, 1000, out)
@benchmark logistic_map_points_raw(LinRange(2.6, 4.0, 1000), 1000, 1000, out)
```
::::
:::

---

::: keypoints
- Allocations are slow.
- Growing arrays dynamically induces allocations.
:::


