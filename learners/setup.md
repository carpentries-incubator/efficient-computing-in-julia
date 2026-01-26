---
title: Setup
---

# Setup

This workshop is always taught using the latest release version of Julia. We use VS Code as our main environment. Depending on your experience, setting up your environment should take around 30min - 1h. We encourage you to also spend 1-2h exploring the Julia Manual.

## Equipment

You need a decent laptop with priviliges to install software. Julia is a compiled language and compiling can be demanding on your CPU. Specifically, something like a Chromebook or similar will definitely not do.

## Install/Update Julia

::: tab

### New installation
Install Julia by following the instruction on [the Julia webpage, downloads section](https://julialang.org/downloads/). This will also install `juliaup` which maintains different versions of Julia on your machine.

### Update old installation
If you installed Julia previously and you need to upgrade, run:

```bash
juliaup update
juliaup default release   # to be sure
```
:::

## Install Dependencies

Prepare the courses package environment. Create a directory that you will work in:

```bash
mkdir EfficientJulia
cd EfficientJulia
julia
```

Press `]` to enter package mode:

```julia
(@v1.12) pkg> activate .
(EfficientJulia) pkg> add GLMakie DataFrames BenchmarkTools GeometryBasics IterTools Revise Unitful StaticArrays Images FileIO
```

This may take a while, as Julia will precompile the added packages and their dependencies (which is why you need to do it in advance).

### GPU Libraries

Install the GPU library for your backend (this is needed for the GPU computing part at the end of day 2). If you're not sure, these dependencies are relatively quick to install, so we can help during the setup session or in a break during the workshop.

::: tab
### Intel
If you run on an Intel based laptop, chances are that your laptop contains an onboard GPU (a tiny one). This GPU is accessible through Intel's oneAPI.

```julia
(EfficientJulia) pkg> add oneAPI KernelAbstractions
```

### AMD
AMD Graphics cards are programmed using ROCm. As far as we know there are no laptops with official ROCm support.

```julia
(EfficientJulia) pkg> add AMDGPU KernelAbstractions
```

### NVidia
You probably know if you have an NVidia card. In that case CUDA is your goto.

```julia
(EfficientJulia) pkg> add CUDA KernelAbstractions
```

### MacBook (M-series)
Most current M-series MacBooks run on ARM and have a special architecture called Metal for GPU computing. Older MacBooks probably need to use Intel `oneAPI` or you might have a small NVidia card.

```julia
(EfficientJulia) pkg> add Metal KernelAbstractions
```
:::

## VS Code

Install [VS Code](https://code.visualstudio.com/). VS Code is the de-facto standard IDE for Julia. Within VS Code, install [the Julia language plugin](https://marketplace.visualstudio.com/items?itemName=julialang.language-julia). Press the puzzle-piece icon in the toolbar and search for Julia, the top result should be the official extension.

## Prepare

If you have time, explore the [Julia Manual](https://docs.julialang.org/en/v1/). This is not mandatory, but you will learn a lot more in the workshop if you are prepared. Skim through from "Getting Started" until (including) "Methods", and spend one or two hours trying out things that you find interesting, while enjoying a nice cup of your favourite hot beverage.
