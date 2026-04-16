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

using MacroTools
using OffsetArrays
using StaticArrays

abstract type BoundaryType{dim} end

struct Periodic{dim} <: BoundaryType{dim} end
struct Constant{dim, val} <: BoundaryType{dim} end
struct Reflected{dim} <: BoundaryType{dim} end

@inline get_bounded(::Type{Periodic{dim}}, arr, idx) where {dim} =
    checkbounds(Bool, arr, idx) ? arr[idx] : 
    arr[mod1.(Tuple(idx), size(arr))...]

@inline get_bounded(::Type{Constant{dim, val}}, arr, idx) where {dim, val} =
    checkbounds(Bool, arr, idx) ? arr[idx] : val

@inline get_bounded(::Type{Reflected{dim}}, arr, idx) where {dim} =
    checkbounds(Bool, arr, idx) ? arr[idx] : 
    arr[modflip.(Tuple(idx), size(arr))...]

function stencil!(f, ::Type{BT}, ::Size{sz}, out::AbstractArray, inp::AbstractArray...) where {dim, sz, BT <: BoundaryType{dim}}
    @assert all(size(a) == size(out) for a in inp)
    center = CartesianIndex((div.(sz, 2) .+ 1)...)
    for i in eachindex(IndexCartesian(), out)
        nb = (SArray{Tuple{sz...}}(
                get_bounded(BT, a, i - center + j)
                for j in CartesianIndices(sz))
              for a in inp)
        out[i] = f(nb...)
    end
    return out
end

stencil!(f, ::Type{BT}, sz) where {BT} =
    (out, inp...) -> stencil!(f, BT, sz, out, inp...)

struct Reader{T}
    func::T
end

macro reader(formals, func)
    env = (:($f = r.$f) for f in formals.args)
    if @capture(shortdef(func), name_(args__) = body_)
        return :($name($(args...)) = Reader(function (r)
            $(env...)
            $(body)
        end))
    end
    if @capture(shortdef(func), name_(args__) where {T_} = body_)
        return :($name($(args...)) where {$T} = Reader(function (r)
            $(env...)
            $(body)
        end))
    end
end

@reader [Δx] dx(u) = (u[1, 0] - u[-1, 0]) / (2Δx)
@reader [Δx] dy(u) = (u[0, 1] - u[-1, 0]) / (2Δx)
@reader [Δx] Δ(u) = (u[1, 0] + u[0, 1] + u[-1, 0] + u[0, -1] - 4u[0, 0]) / Δx^2

@inline (a::Reader{A})(r) where {A} = a.func(r)
@inline Base.map(f, a::Reader{A}, b::Reader{B}) where {A, B} = Reader(r->f(a(r), b(r)))
@inline Base.map(f, a::Reader{A}) where {A} = Reader(r->f(a))
@inline Base.:+(f, a::Reader{A}, b::Reader{B}) where {A, B} = map((+), a, b)
@inline Base.:-(f, a::Reader{A}, b::Reader{B}) where {A, B} = map((-), a, b)
@inline Base.:*(f, a::Reader{A}, b::Reader{B}) where {A, B} = map((*), a, b)
@inline Base.:*(f, a, b::Reader{B}) where {B} = map(x->a*x, b)
@inline Base.:*(f, a::Reader{A}, b) where {A} = map(x->x*b, a)

struct State
    u::Matrix{Float64}
    v::Matrix{Float64}
end

struct Delta
    du::Matrix{Float64}
    dv::Matrix{Float64}
end

abstract type AbstractInput{BT} end

function gray_scott_model(F, k, D_u, D_v)
    function (r::AbstractInput{BT}) where BT
        u_t(u, v) = D_u * r.Δ(u) - u[0, 0] * v[0, 0]^2 + F * (1 - u[0, 0])
        v_t(u, v) = D_v * r.Δ(v) + u[0, 0] * v[0, 0]^2 - (F + k) * v[0, 0]

        d = Delta(Matrix{Float64}(undef, r.size...), Matrix{Float64}(undef, r.size...))
        function (s)
            stencil!(u_t, BT, Size(3, 3), d.du, s.u, s.v)
            stencil!(v_t, BT, Size(3, 3), d.dv, s.u, s.v)
            return d
        end
    end |> Reader
end


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


