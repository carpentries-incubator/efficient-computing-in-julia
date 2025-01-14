---
title: Instructor Notes
---

## Audience

Competent programmer in another language like Python, R, or Matlab.

## Goal

Julia is designed to solve the two-language problem. Languages like Python and R are easy to get started with, but don't offer the efficiency of compiled languages like C++, Rust or Fortran. Often the easier scripting languages offer a front-end for code implemented in one of the compiled languages. This means that, to implement a solution that is both efficient and user friendly, you need to write your package in two languages. This comes with several problems:

- The front-end talks to the back-end through a native interface (C-ABI) which is often unsafe and can cause bugs.
- Developers need to be competent in two languages as well as the interface between them.
- Native libraries can be hard to compile due to a stack of dependencies.
- Existing packages are hard to extend, i.e. the learning gradient from incidental user to developer is too steep considering the non-professional nature of most scientific applications.
- Interaction between different packages is often limited to the slower scripting language.

Julia solves these problems by offering a language that is both easy to get started with, and can achieve native performance. Furthermore, Julia has an excellent packaging system that solves many of the reproducibility problems associated with other languages. Although it is possible to write programs in Julia that perform similar (and sometimes even better) as in native languages (C, Fortran), actually getting to these levels of performance is not trivial.

This workshop aims to get research software engineers from their first steps in Julia to become aware of all the major techniques and pitfalls when it comes to writing performant Julia.

## Setup

Participants will have to install Julia by following the instruction on [the Julia webpage, downloads section](https://julialang.org/downloads/). They should be provided an environment with a `Project.toml` so they can precompile any dependencies before the workshop starts. In most cases this should suffice, though we have encountered university-managed Windows laptops in the wild that gave problems.

## Workflow

We're teaching using VS Code as the main environment. If you prefer, you might also use Pluto, but interactive `Makie` plots don't work so well in Pluto (you'd use `PlutoUI` instead), and the `@profview` macro needs an extra dependency to work from Pluto.

## Sillabus

The following sillabus assumes 6 hours of effective teaching per day.

### Day 1: Introduction to Julia

- Using Pluto
- Basics of Julia: 3h
  - basic operations, flow control and functions
  - `Unitful` quantities
  - types and multiple dispatch
  - arrays and broadcasting
- Plotting using `Makie`: 1h
  - Lorenz attractor
- Package development with `Pkg`: 1h
- Best practices: testing and documentation: 1h
  - `BestieTemplate`

### Day 2: Efficient with Julia

- Measuring speed with `BenchmarkTools`: 1h
  - closures to reduce allocations
  - static types to reduce dynamic look-up
- Types: 1h
  - parametric types
  - generic types
  - value types
- Type stability: 1h
  - `JET` and `Cthulu`
- Parallel programming: 1h
  - Channels
  - Threads and Tasks
  - Transducers
  - GPUs
- Computing Julia fractals: 2h

## 1-day alternative

- Using Pluto
- Basics of Julia: 3h
  - basic operations, flow control and functions
  - `Unitful` quantities
  - types and multiple dispatch
  - arrays and broadcasting
- Measuring speed with `BenchmarkTools`: 2h
  - closures to reduce allocations
  - static types to reduce dynamic look-up
- Best practices with `BestieTemplate`: 1h

## Oddities

Many of the code blocks have a comment stating some sort of id.

```julia
#| id: code-block-id
...
```

These are used to collect code blocks into executable units for automated testing and rendering of output figures, using [Entangled](https://entangled.github.io). You can certainly ignore them while teaching.
