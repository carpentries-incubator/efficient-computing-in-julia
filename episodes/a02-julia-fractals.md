---
title: "Appendix: Generating Julia Fractals"
---

::: spoiler

``` {.julia file=examples/JuliaFractal/src/JuliaFractal.jl}
module JuliaFractal

using Transducers: Iterated, Enumerate, Map, Take, DropWhile

module MyIterators
<<count-until>>

<<iterated>>
end

julia(c) = z -> z^2 + c

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

escape_time(fn, maxit) = function (z)
  MyIterators.count_until(
    z -> real(z * conj(z)) > 4.0,
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

end  # module
```

:::
