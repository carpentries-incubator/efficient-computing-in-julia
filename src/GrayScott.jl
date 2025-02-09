# ~/~ begin <<episodes/140-threads-async-and-tasks.md#src/GrayScott.jl>>[init]
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

macro reader(formal, func)
    println(formal)
    if @capture(shortdef(func), name_(args__) = body_)
        return :($name($(args...)) = Reader($formal -> $body))
    end
    if @capture(shortdef(func), name_(args__) where {T_} = body_)
        return :($name($(args...)) where {$T} = Reader($formal -> $body))
    end
end

@reader r dx(u) = (u[1, 0] - u[-1, 0]) / (2 * r.Δx)
@reader r dy(u) = (u[0, 1] - u[-1, 0]) / (2 * r.Δx)
@reader r Δ(u) = (u[1, 0] + u[0, 1] + u[-1, 0] + u[0, -1] - 4u[0, 0]) / r.Δx^2

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
# ~/~ end
