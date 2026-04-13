---
title: GPU Programming
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


Load the correct packages for your GPU as follows:

::: group-tab
### Intel

```julia
using BenchmarkTools
using oneAPI
using KernelAbstractions
```

### Metal

```julia
using BenchmarkTools
using Metal
using KernelAbstractions
```

### NVidia

```julia
using BenchmarkTools
using CUDA
using KernelAbstractions
```

### AMD

```julia
using BenchmarkTools
using AMDGPU
using KernelAbstractions
```
:::


## Simple vector addition

Let us first consider some simple code to add two vectors (of length 1024) together:

```julia
function simple_vector_add(a, b, c)
    for I = 1:1024
        c[I] = a[I] + b[I]
    end
end
```

And you can run this with some randomly initialised vectors:
```julia
a = randn(Float32, 1024)
b = randn(Float32, 1024)
c = Vector{Float32}(undef, 1024)

simple_vector_add(a, b, c)

c # Print out c in the console
```

:::discussion
What part of the above `simple_vector_add()` function do you think is the "kernel"? Do you already have some idea how we might modify that for use on a GPU?
:::


## A kernel for vector addition

We can adapt `simple_vector_add()` to make a new function where we have removed the for-loop and kept only the core operation:

```julia
@kernel function vector_add(a, b, c)
    I = @index(Global)
    c[I] = a[I] + b[I]
end
```

We make use of `KernelAbstractions` macros to define this as a kernel (more on this later) and to allow the function to ask what `I` it should act on. We no longer determine how or in what order this kernel will be applied - that will be determined by the relevant backend for your device.


### Running on the host (CPU)

Before trying it on GPU, we can first test out our new kernel function on the normal, plain CPU. We do this by choosing the `CPU()` device:

```julia
dev = CPU()
vector_add_kernel(dev, 512)(a, b, c, ndrange=size(a))

c # Print out c in the console
```

### Moving our local arrays onto the device (GPU)

We would like to try running our vector addition kernel on the GPU. However, we run into a problem - the GPU has its own memory, separate from the RAM on the host. Our vectors, `a`, `b` and `c`, currently reside in the host's memory, so the GPU has no access to them and cannot perform any computations. 

Therefore, we must first create (on-GPU) device arrays. As before, this depends on the GPU you have:

::: group-tab
### Intel

```julia
a_dev = oneArray(a)
b_dev = oneArray(b)
a_dev .+ b_dev
```

### Metal

```julia
a_dev = MtlArray(a)
b_dev = MtlArray(b)
a_dev .+ b_dev
```

### NVidia

```julia
a_dev = CuArray(a)
b_dev = CuArray(b)
a_dev .+ b_dev
```

### AMD

```julia
a_dev = ROCArray(a)
b_dev = ROCArray(b)
a_dev .+ b_dev
```
:::


Note that `a_dev` and `b_dev` refer to arrays on the GPU device itself. This means that the addition (`a_dev .+ b_dev`) was actually performed on the GPU, and the result copied back to host for us to see.


## Computations on the device

Earlier we used `dev = CPU()` to set the location on which to run our kernel. We may now do the following to set that to be the GPU:
```julia
dev = get_backend(a_dev)
```

Now we should be able to run `vector_add()` on the GPU.

::: challenge
### Run the vector-add on the device
Depending on your machine, try and run the above vector addition on your GPU. Most PC (Windows or Linux) laptops have an on-board Intel GPU that can be exploited using `oneAPI`. If you have a Mac, give it a shot with `Metal`. Some of you may have brought a gaming laptop with a real GPU, then `CUDA` or `AMDGPU` is your choice.

Compare the run time of `vector_add` to the threaded CPU version and the array implementation. Make sure to run `KernelAbstractions.synchronize(backend)` when you time results.

::::solution
```julia
c_dev = oneArray(zeros(Float32, 1024))
vector_add(dev, 512)(a_dev, b_dev, c_dev, ndrange=1024)
all(Array(c_dev) .== a .+ b)

function test_vector_add()
	vector_add(dev, 512)(a_dev, b_dev, c_dev, ndrange=1024)
	KernelAbstractions.synchronize(dev) 
end

@benchmark test_vector_add()
@benchmark begin c_dev .= a_dev .+ b_dev; KernelAbstractions.synchronize(dev) end
@benchmark c .= a .+ b
```
::::
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
using GLMakie
heatmap(out_host)
```

```julia
@benchmark julia_host(c, 1f0/600, 1024, out_host)
```

Hint 1: There exists a `@index(Global, Cartesian)` macro.

Hint 2: on Intel we needed a gang size that divides the width of the image, in this case `480` seemed to work.

:::: solution

```julia
@kernel function julia_dev(c::ComplexF32, s::Float32, maxit::Int, out)
	w, h = size(out)
	idx = @index(Global, Cartesian)
	
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
```

```julia
out = oneArray(zeros(Int, 1920, 1080))
backend = get_backend(out)
julia_dev(backend, 480)(c, 1f0/600, 1024, out, ndrange=size(out))
all(Array(out) .== out_host)
```

```julia
@benchmark begin julia_dev(backend, 480)(c, 1f0/600, 1024, out, ndrange=size(out)); KernelAbstractions.synchronize(backend) end
```
::::
:::

---

::: keypoints
- We can compile Julia code to GPU backends using `KernelAbstractions`.
- Even on smaller laptops, significant speedups can be achieved, given the right problem.
:::
