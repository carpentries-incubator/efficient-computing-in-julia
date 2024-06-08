---
title: Getting Started
---

::: questions

- Why should I use Julia?
- How do I get started with Julia?
:::

::: objectives

- Start a REPL
- Start Pluto
- Understand Pluto's behaviour (w.r.t. Jupyter)
:::

## Why Julia

Most of the participants will be coming from Python, Matlab or a lower level language like C/C++ or Fortran. Why should you be interested in learning Julia?

### Performance and usability

Julia promises:

- Native performance: close to or sometimes even exceeding C++ or Fortran.
- Solve the multiple language issue: one language for everything (including GPU).
- As easy to get into as Python or R.
- Designed for parallel computing.

These promises seem tantalizing and are in part what draws people to Julia, but in practice getting into Julia and writing performant code are two different things. Julia has its own idiosyncrasies that need to be understood to really squeeze every erg of performance out of your system.

Julia obtains its performance from being a Just-In-Time (JIT) compiler, on top of the lLVM compiler stack (similar to how Python's Numba operates).

### Language intrinsics

Next to being performant, it turns out that Julia is a very nice language that does some things a bit different from what you may be used to:

- **First-class arrays** and **Broadcasting**: arrays, slicing and operating on arrays have dedicated syntax, similar to Matlab.
- **Multiple dispatch**: Julia functions can be specialized on the entire call signature (not just its first argument like in Object Oriented Programming).
- **Macros and Meta-programming**: The Just-in-time nature of the Julia compiler exposes a wide range of meta-programming capabilities, ranging from small macros to enhance the expressibility of the language to full-on code generation.

Meta-programming, while very powerful, is also very easy to abuse, often leading to unreadable non-idiomatic code. So tread with care! We'll see some examples where macros are indispensable though, and the SciML stack relies deeply on on-the-fly code-generation.

:::discussion
Why are you interested in Julia? What is your current go-to for efficient computing?
:::

## Running Julia

When working in Julia it is very common to do so from the REPL (Read-Eval-Print Loop). Please open the Julia REPL on your system

```shell
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.10.3 (2024-04-30)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> 
```

The REPL needs a small introduction since it has several **modes**.

| Key | Prompt | Mode |o
|-----|--------|------|
| None | `julia>` | Standard **Julia** input. |
| `]` | `pkg>` | **Pkg** mode. Commands entered here are functions in the `Pkg` module. |
| `;` | `shell>` | **Shell** mode. |
| `?` | `help?>` | **Help** mode. Type the name of any entity to look up its documentation. |

:::challenge

### Play with the REPL

a. `Pkg` mode has a `help` command to help you along. Find out what the `add` command does.
b. Check the contents of the folder in which your are running your REPL (`ls` on Unix, `dir` on Windows).
c. Find out what the `print` method does in Julia.

::::solution
a. `]help add`, the `add` command installs packages
b. `;ls`
c. `?print`
::::
:::

::: callout
Please take a look at the Julia documentation now at [https://docs.julialang.org/en/v1/](https://docs.julialang.org/en/v1/).
:::

## Pluto

Pluto is the notebook environment from which we will teach much of this workshop. We can run it from the Julia REPL.

```shell
pkg> add Pluto
... quite a bit of output ...

julia> using Pluto

julia> Pluto.run()
[ Info: Loading...
┌ Info: 
└ Opening http://localhost:1235/?secret=xyzxyzxyz in your default browser... ~ have fun!
┌ Info: 
│ Press Ctrl+C in this terminal to stop Pluto
└ 
```

:::challenge

### Julia as a calculator

Try to play around in Pluto to use Julia as a calculator.

a. What do you find is the operator for exponentiation?
b. How do you assign a variable?
c. What happens when you divide any two integers? Use the `typeof` function to inspect the type of the result. Can you figure out how to integer division (search the documentation!)?
d. What happens in Pluto when you change a variable that is depended upon?

::::solution
a. In Julia exponentiation is `^`.
b. Just like you're used to `x = 3`.
c. The `/` operator always returns a floating point value. To get to integer division, we want the `÷` operator, which can be typed using `\div` and then press TAB. Or you can use the equivalent `div` function.
d. Pluto updates all dependent computations automatically. This is known as a **reactive notebook**.
::::
:::

::: keypoints

- In Julia, the REPL is much more important than in some other languages.
- Pluto is a reactive environment
:::
