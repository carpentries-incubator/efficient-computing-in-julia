---
title: Lesson Overview
---

## Audience

People know how to program in either Python or R (never both!)

## Goal

Create new Julia advocates. Win them over by showing technical superiority. World Domination!

## Setup

- TODO: Create named env that people can precompile

## Scope

- Introduction to Julia: 1st day
    - using Pluto
    - basics of Julia: 3h
        - basic flow control
        - broadcasting
        - Multiple dispatch
        - Parametric types
        - do syntax (similar to Python `with`)
        - Plotting with Makie: 1h
    - mis-en-place: 3h
        - creating a package
        - best practices in package development
        - testing
        - Revise
        - VSCode

- Efficient computing: 2nd day
    - Best practices for code efficiency:
        - use modules
        - use functions
        - only globals when const
        - ...
    - Performance analysis: 2h
        - The compiler is slow
        - BenchmarkTools
        - Profiling
        - Type stability:
            - `@code_warntype`
            - Cthulu
    - useful libraries: 30min
        - (scipy)  there is none:
            - SciML stack (Abel says: overengineered wrappers)
            - JuMP
            - quadrature, root-finding, ode-solving, optimisation
            - Google
        - (pandas) Dataframes.jl
    - Parallel programming: 2h
        - Channels
        - Tasks
        - Threads
        - Transducer based stuff
        - mention: GPU
        - mention: Distributed: https://github.com/JuliaParallel/ClusterManagers.jl

## Guiding examples

Principle: examples that are not *too* technical, but give the participants the feeling that we're solving real-world problems.

- Computing $\pi$ for realz
- Mandelbrot
- Lorenz attractor
- k-means clustering
- generate data, process, optimise! (analysis pipeline example)
- 

