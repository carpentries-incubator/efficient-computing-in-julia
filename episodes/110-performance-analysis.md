---
title: Performance Analysis
---

::: questions
- How can I measure the efficiency of my code?
- How can I identify bottle necks?
:::

::: objectives
- Learn how to use `BenchmarkTools`
- Learn how to use `Profiler` and `PProf`
:::

```julia
using IterTools
using GLMakie

logistic_map(r) = n -> r * n * (1 - n)
```

```julia
let
	fig = Figure(size=(800, 200))
	for (i, r) in enumerate([2.8, 3.3, 3.56, 3.671])
		ax = Axis(fig[1, i], aspect=1, title="r=$r")  # , limits=(nothing, nothing))
		orbit = Iterators.take(iterated(logistic_map(r), 0.5), 40) |> collect
		lines!(ax, orbit)
		scatter!(ax, orbit)
	end
	fig
end
```

```julia
using .Iterators: take, drop, flatten
using BenchmarkTools
```

```julia
lm_points(n_skip, n_take) = r -> imap(x->Point2(r, x), take(drop(iterated(logistic_map(r), 0.5), n_skip), n_take))
lm_points(r, n_skip, n_take) = map(lm_points(n_skip, n_take), r) |> flatten |> collect
```

```julia
function bifurcation_diagram_data(r::Float64, skip, data)
	x = 0.5
	f = logistic_map(r)
	for _ in 1:skip
		x = f(x)
	end
	for j in eachindex(view(data, 2, :))
		x = f(x)
		data[2,j] = x
	end
	data[1,:] .= r
	data
end
```

```julia
function bifurcation_diagram_data(rs::AbstractArray, skip, nitr)
	data = Array{Float32}(undef, 2, nitr, length(rs))
	for (i, r) in enumerate(rs)
		bifurcation_diagram_data(r, skip, view(data, :, :, i))
	end
	pts = reshape(view(data, :, :, :), 2, :)
end
```

```julia
pts = bifurcation_diagram_data(LinRange(2.6, 4.0, 80000), 1000, 1000)
```

```julia
let
	fig = Figure(size=(800, 700))
	ax = Makie.Axis(fig[1,1], limits=((2.6, 4.0), nothing))
	datashader!(ax, reinterpret(Point2f, pts)[1,:], async=false, colormap=:deep)
	fig
end
```

---

::: keypoints
- When you want to compare performance of different implementations, use `BenchmarkTools`.
- When you want to identify bottle necks, use `Profiler`.
- Pay close attention to the memory allocations.
:::


