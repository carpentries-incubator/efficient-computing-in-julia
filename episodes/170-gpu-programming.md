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

## Array abstraction

```julia
using oneAPI
```

```julia
a = oneArray(randn(1024))
b = oneArray(randn(1024))
c = a .+ b
```

## `KernelAbstractions`

```julia
using oneAPI  # or CUDA or Metal etc.
using KernelAbstractions
```

```julia
@kernel function vector_add(a::T, b::T, c::T) where {T}
    I = @index(Global)
    c[T] = a[T] + b[T]
end
```

### Run on host

```julia
dev = CPU()
a = randn(1024)
b = randn(1024)
c = Array(undef, 1024)
vector_add(dev, 512)(a, b, c, ndrange=size(a))
synchronize(dev)
```

::: challenge
### Implement the Julia fractal
Use the GPU library that is appropriate for your laptop. Do you manage to get any speedup?

```julia
@kernel function julia_dev(c::ComplexF32, s::Float32, maxit::Int, out::M) where {M}
	w, h = size(out)
	idx = @index(Global)
	i = idx % w
	j = idx ÷ w
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

:::

---

::: keypoints
- Direct GPU support is still in infancy.
- We can compile Julia code directly to CUDA using `CUDA.jl`.
- AMD with `AMDGPU.jl`.
- The same for Intel with `OneAPI.jl`.
- Apple Metal with `Metal.jl` (Experimental)
:::
