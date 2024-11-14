# ~/~ begin <<episodes/a02-julia-fractals.md#examples/JuliaFractal/src/JuliaFractal.jl>>[init]
module JuliaFractal

using Transducers: Iterated, Enumerate, Map, Take, DropWhile
using GLMakie

module MyIterators
# ~/~ begin <<episodes/a01-collatz.md#count-until>>[init]
function count_until_fn(pred, fn, init)
  n = 1
  x = init
  while true
    if pred(x)
      return n
    end
    x = fn(x)
    n += 1
  end
end
# ~/~ end
# ~/~ begin <<episodes/a01-collatz.md#count-until>>[1]
function count_until(pred, iterator)
  for (i, e) in enumerate(iterator)
    if pred(e)
      return i
    end
  end
  return -1
end
# ~/~ end

# ~/~ begin <<episodes/a01-collatz.md#iterated>>[init]
struct Iterated{Fn,T}
  fn::Fn
  init::T
end

iterated(fn) = init -> Iterated(fn, init)
iterated(fn, init) = Iterated(fn, init)

function Base.iterate(i::Iterated{Fn,T}) where {Fn,T}
  i.init, i.init
end

function Base.iterate(i::Iterated{Fn,T}, state::T) where {Fn,T}
  x = i.fn(state)
  x, x
end

Base.IteratorSize(::Iterated) = Base.IsInfinite()
Base.IteratorEltype(::Iterated) = Base.HasEltype()
Base.eltype(::Iterated{Fn,T}) where {Fn,T} = T
# ~/~ end
end

# ~/~ begin <<episodes/a02-julia-fractals.md#julia-fractal>>[init]
julia(c) = z -> z^2 + c
# ~/~ end

struct BoundingBox
    shape::NTuple{2,Int}
    origin::ComplexF64
    resolution::Float64
end

bounding_box(; width::Int, height::Int, center::ComplexF64, resolution::Float64) =
    BoundingBox(
        (width, height),
        center - (resolution * width / 2) - (resolution * height / 2)im,
        resolution)

grid(box::BoundingBox) =
    ((idx[1] * box.resolution) + (idx[2] * box.resolution)im + box.origin
     for idx in CartesianIndices(box.shape))

axes(box::BoundingBox) =
    ((1:box.shape[1]) .* box.resolution .+ real(box.origin),
        (1:box.shape[2]) .* box.resolution .+ imag(box.origin))

escape_time(fn::Fn, maxit::Int64) where {Fn} =
    function (z::Complex{T}) where {T<:Real}
        MyIterators.count_until(
            (z::Complex{T}) -> real(z * conj(z)) > 4.0,
            Iterators.take(MyIterators.iterated(fn, z), maxit))
    end

escape_time_3(fn, maxit) = function (z)
    Iterators.dropwhile(
        ((i, z),) -> real(z * conj(z)) < 4.0,
        enumerate(Iterators.take(MyIterators.iterated(fn, z), maxit))
    ) |> first |> first
end

escape_time_2(fn, maxit) = function (z)
    MyIterators.iterated(fn, z) |> Enumerate() |> Take(maxit) |>
    DropWhile(((i, z),) -> real(z * conj(z)) < 4.0) |>
    first |> first
end

function plot_julia(z::Complex{T}) where {T<:Real}
    width = 1920
    height = 1080
    bbox = bounding_box(width=width, height=height, center=0.0 + 0.0im, resolution=0.004)

    image = grid(bbox) .|> escape_time(julia(z), 512)
    fig = Figure()
    ax = Axis(fig[1, 1])
    x, y = axes(bbox)
    heatmap!(ax, x, y, image)
    return fig
end

end  # module
# ~/~ end