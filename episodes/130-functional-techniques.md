---
title: "Functional Programming: game of life"
---

::: questions
- How can I build abstractions without objects or classes?
- Does Julia have context managers, or other ways to manage resources?
:::

::: objectives
- Understand `do` syntax.
- Understand the concept of **closures**.
- Use dispatch with abstract types.
:::

Let's build cellular automata!

```julia
using GLMakie
using Transducers
using StaticArrays
```

```julia
#| file: src/CA.jl
module CA
    using GLMakie
    using StaticArrays

    <<ca>>
end
```

```julia
#| id: ca
abstract type BoundaryType{dim} end

struct Periodic{dim} <: BoundaryType{dim} end
struct Constant{dim, val} <: BoundaryType{dim} end

@inline get_bounded(::Type{Periodic{dim}}, arr::A, idx::CartesianIndex{dim}) where {T, dim, A <: AbstractArray{T, dim}} =
    arr[mod1.(Tuple(idx), size(arr))...]
    # arr[mod1.(Tuple(idx), size(arr))...]

@generated function get_bounded(::Type{Periodic{dim}}, arr, idx) where {dim}
    :(@inbounds arr[$((:(mod1(idx[$i], size(arr)[$i])) for i =1:dim)...)])
end

@inline get_bounded(::Type{Constant{dim, val}}, arr, idx) where {dim, val} =
    checkbounds(Bool, arr, idx) ? arr[idx] : val
```

```julia
#| id: ca


"""
    stencil(f, BoundaryType{dim}, size)

The function `f` should take an `AbstractArray` with size `size` as input
and return a single value, and `size` should be a tuple of length `dim` giving
the size of the stencil. Then, `stencil` returns a function of two arguments
`in` and `out` that should be arrays of the same shape.
"""
function stencil(f::F, ::Type{BT}, ::Size{sz}, inp::A, out) where {F, dim, sz, BT <: BoundaryType{dim}, T, A <: AbstractArray{T, dim}}
    @assert size(inp) == size(out)
    center = CartesianIndex((div.(sz, 2) .+ 1)...)
    nb = zeros(MArray{Tuple{sz...}, T})
    for i in eachindex(IndexCartesian(), inp)
        for j in eachindex(IndexCartesian(), nb)
            nb[j] = get_bounded(BT, inp, i - center + j)
        end
        out[i] = f(nb)
    end
end


stencil(f::F, ::Type{BT}, ::Size{sz}) where {F, dim, sz, BT <: BoundaryType{dim}} =
    (in, out) -> stencil(f, BT, Size(sz...), in, out)
```

```julia
using LinearAlgebra: dot
convolution(kernel::AbstractArray{T, dim}) where {T, dim} =
    stencil(x->dot(x, kernel), Periodic{dim}, Size{size(kernel)})

function gaussian_kernel(dims::Dims{dim}, sigma::Float64) where {dim}
    c = CartesianIndex((div.(dims, 2) .+ 1)...)
    [exp(-sum(Tuple(x - c).^2)/(2*sigma^2))/(sigma * sqrt(2π))
     for x in CartesianIndices(dims)]
end

g2 = convolution(gaussian_kernel((9, 9), 2.0))
a = randn(Float64, 256, 256)
b = Array{Float64, 2}(undef, 256, 256)

@profview g2(a, b)
```

```julia
eca(n) = nb -> 1 & (n >> ((nb[1] << 2) | (nb[2] << 1) | nb[3]))
rule(n) = stencil(eca(n), Periodic{1}, Size(3))

mutable struct IteratedStencil{T,S}
    state::T
    next::T
    fun::S
end

Base.IteratorSize(::Type{IteratedStencil{T,S}}) where {T, S} = Base.IsInfinite()

iterated_stencil(f, x0::AbstractArray{T, dim}) where {T, dim} =
    IteratedStencil(x0, Array{T, dim}(undef, size(x0)...), f)

Base.iterate(it::IteratedStencil) = (it.state, nothing)

function Base.iterate(it::IteratedStencil, ::Nothing)
    it.fun(it.state, it.next)
    it.state, it.next = it.next, it.state
    return (it.state, nothing)
end

singleton(n) = let x = zeros(Bool, n); x[div(n, 2)] = 1; x end

cmap = [colorant"white", colorant"black"]
to_image(arr) = cmap[arr'.+1]
iterated_stencil(rule(30), singleton(1024)) |>
    Map(copy) |> Take(512) |> stack |> to_image
```

```julia
#| id: ca
game_of_life(a) = let s = sum(a) - a[2, 2]
    s == 3 || (a[2, 2] && s == 2)
end

function tic(f, dt, running_)
    running::Observable{Bool} = running_

    @async begin
        while running[]
            sleep(dt)
            f()
        end
    end
end

function run_life()
    fig = Figure()

    sz = (64, 64)
    state = Observable(rand(Bool, sz...))
    temp = Array{Bool, 2}(undef, sz...)
    foo = stencil(game_of_life, Periodic{2}, Size(3, 3))

    function next()
        foo(state[], temp)
        state[], temp = temp, state[] # copy(temp)
    end

    ax = Axis(fig[1, 1], aspect=1)
    gb = GridLayout(fig[2, 1], tellwidth=false)

    playing = Observable(false)

    play_button_text = lift(p->(p ? "Pause" : "Play"), playing)
    play_button = gb[1,1] = Button(fig, label=play_button_text)
    rand_button = gb[1,2] = Button(fig, label="Randomize")

    on(play_button.clicks) do _
        p = !playing[]
        playing[] = p
        if p
            tic(next, 0.01, playing)
        end
    end

    on(rand_button.clicks) do _
        state[] = rand(Bool, sz...)
    end

    heatmap!(ax, state)

    fig
end
```

---

::: keypoints
:::


