# ~/~ begin <<episodes/130-value-types-and-ca.md#src/Stencils.jl>>[init]
#| file: src/Stencils.jl
module Stencils
    using StaticArrays

    # ~/~ begin <<episodes/130-value-types-and-ca.md#stencils>>[init]
    #| id: stencils
    abstract type BoundaryType{dim} end

    struct Periodic{dim} <: BoundaryType{dim} end
    struct Constant{dim, val} <: BoundaryType{dim} end

    @inline get_bounded(::Type{Periodic{dim}}, arr, idx) where {dim} =
        checkbounds(Bool, arr, idx) ? arr[idx] : 
        arr[mod1.(Tuple(idx), size(arr))...]

    @inline get_bounded(::Type{Constant{dim, val}}, arr, idx) where {dim, val} =
        checkbounds(Bool, arr, idx) ? arr[idx] : val
    # ~/~ end
    # ~/~ begin <<episodes/130-value-types-and-ca.md#stencils>>[1]
    #| id: stencils
    struct Reflected{dim} <: BoundaryType{dim} end

    @inline get_bounded(::Type{Reflected{dim}}, arr, idx) where {dim} =
        checkbounds(Bool, arr, idx) ? arr[idx] : 
        arr[modflip.(Tuple(idx), size(arr))...]
    # ~/~ end
    # ~/~ begin <<episodes/130-value-types-and-ca.md#stencils>>[2]
    #| id: stencils
    """
        stencil!(f, <: BoundaryType{dim}, Size{sz}, inp, out)

    The function `f` should take an `AbstractArray` with size `sz` as input
    and return a single value. Then, `stencil` applies the function `f` to a
    neighbourhood around each element and writes the output to `out`. 
    """
    function stencil!(f, ::Type{BT}, ::Size{sz}, inp::AbstractArray{T,dim}, out::AbstractArray{RT,dim}) where {dim, sz, BT <: BoundaryType{dim}, T, RT}
        @assert size(inp) == size(out)
        center = CartesianIndex((div.(sz, 2) .+ 1)...)
        for i in eachindex(IndexCartesian(), inp)
            nb = SArray{Tuple{sz...}, T}(
                get_bounded(BT, inp, i - center + j)
                for j in CartesianIndices(sz))
            out[i] = f(nb)
        end
        return out
    end

    stencil!(f, ::Type{BT}, sz) where {BT} =
        (inp, out) -> stencil!(f, BT, sz, inp, out)
    # ~/~ end
end
# ~/~ end