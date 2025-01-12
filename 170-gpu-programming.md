---
title: (extra) GPU
---

::: questions
- Can I have some Cuda please?
:::

::: objectives
- See what the current state of GPU computing over Julia is.
:::

## State of things

There are separate packages for GPU computing, depending on the hardware you have.

| Brand | Lib |
|---|---|
| NVidia | [`CUDA.jl`](https://github.com/JuliaGPU/CUDA.jl) |
| AMD | [`AMDGPU.jl`](https://github.com/JuliaGPU/AMDGPU.jl) |
| Intel | [`oneAPI.jl`](https://github.com/JuliaGPU/oneAPI.jl) |
| Apple | [`Metal.jl`](https://github.com/JuliaGPU/Metal.jl) |

Each of these offer similar abstractions for dealing with array based computations, though each with slightly different names.
CUDA by far has the best and most mature support. We can get reasonably portable code by using the above packages in conjunction with `KernelAbstractions`.

## `KernelAbstractions`

```julia
using BenchmarkTools
using oneAPI  # or CUDA or Metal etc.
using KernelAbstractions
```

```julia
@kernel function vector_add(a, b, c)
    I = @index(Global)
    c[I] = a[I] + b[I]
end
```

### Run on host

```julia
dev = CPU()
a = randn(Float32, 1024)
b = randn(Float32, 1024)
c = Vector{Float32}(undef, 1024)
vector_add(dev, 512)(a, b, c, ndrange=size(a))
```

::: challenge
### Run the vector-add on the device
Depending on your machine, try and run the above vector addition on your GPU. Most PC (Windows or Linux) laptops have an on-board Intel GPU that can be exploited using `oneAPI`. If you have a Mac, give it a shot with `Metal`. Some of you may have brought a gaming laptop with a real GPU, then `CUDA` or `AMDGPU` is your choice.

```julia
using oneAPI
a_dev = oneArray(a)
b_dev = oneArray(b)
c_dev = oneArray(zeros(Float32, 1024))
dev = get_backend(a_dev)
vector_add(dev, 512)(a_dev, b_dev, c_dev, ndrange=1024)
all(Array(c_dev) .== a .+ b)
```
:::

::: challenge
### Implement the Julia fractal
Use the GPU library that is appropriate for your laptop. Do you manage to get any speedup? 

```julia
function julia_host(c::ComplexF32, s::Float32, maxit::Int, out::AbstractMatrix{Int})
	w, h = size(out)
	Threads.@threads for idx in CartesianIndices(out)
		x = (idx[1] - w ÷ 2) * s
		y = (idx[2] - h ÷ 2) * s
		z = x + 1f0im * y

		out[idx] = maxit
		for k = 1:maxit
			z = z*z + c
			if abs(z) > 2f0
				out[idx] = k
				break
			end
		end
	end
end

c = -0.7269f0+0.1889f0im
out_host = Matrix{Int}(undef, 1920, 1080)
julia_host(c, 1f0/600, 1024, out_host)
```

```julia
@btime julia_host(c, 1f0/600, 1024, out_host)
```

Hint 1: you need to convert the `@index(Global)` index into a `(i, j)` pair. You can do this by computing the quotient and remainder to the image width.

```julia
idx = @index(Global)
i = (idx-1) % w + 1
j = (idx-1) ÷ w + 1
```

Hint 2: on Intel we needed a gang size that divides the width of the image, in this case `480` seemed to work.

:::: solution

```julia
@kernel function julia_dev(c::ComplexF32, s::Float32, maxit::Int, out)
	w, h = size(out)
	idx = @index(Global)
	i = (idx-1) % w + 1
	j = (idx-1) ÷ w + 1
	x = (i - w ÷ 2) * s
	y = (j - h ÷ 2) * s
	z = x + 1f0im * y

	out[idx] = maxit
	for k = 1:maxit
		z = z*z + c
		if abs(z) > 2f0
			out[idx] = k
			break
		end
	end
end
```

```julia
out = oneArray(zeros(Int, 1920, 1080))
backend = get_backend(out)
julia_dev(backend, 480)(c, 1f0/600, 1024, out, ndrange=size(out))
all(Array(out) .== out_host)
```

```julia
@btime begin julia_dev(backend, 480)(c, 1f0/600, 1024, out, ndrange=size(out)); Array(out) end
```
::::
:::

---

::: keypoints
- GPU support is in immature stages.
- We can compile Julia code to GPU backends using `KernelAbstractions`.
:::
