---
title: Type Stability
---

::: questions
- What is type stability?
- Why is type stability so important for performance?
- What is the origin of type unstable code? How can I prevent it?
:::

::: objectives
- Learn to diagnose type stability using `@code_warntype` and `@profview`
- Understand how and why to avoid global mutable variables.
- Analyze the problem when passing functions as members of a struct.
:::

In this episode we will look into **type stability**, a very important topic when it comes to writing efficient Julia. We will first show some small examples, trying to explain what type stability means and how you can create code that is not type stable. 

```julia
using BenchmarkTools
```

## Compiler stack

We take a small tidbit of code to see what the Julia compiler is doing. Today we will be looking at logistic functions and logistic maps.

```julia
logistic_map(r, x) = r * x * (1 - x)
```

We'll run the following macros on this code to see what the compiler is doing:

- `@code_lower`
- `@code_typed`
- `@code_llvm`
- `@code_native`

## Type stability
If types cannot be inferred at compile time, a function cannot be entirely compiled to machine code. This means that evaluation will be slow as molasses.
One example of a type instability is when a function's return type depends on run-time values:

```julia
function safe_inv(x)
    if x == zero(typeof(x))
        nothing
    else
        one(typeof(x)) / x
    end
end
```

```julia
@code_warntype safe_inv(2)
```

In this case we may observe that the induced type is `Union{Nothing, T}`. If we run `@code_warntype` we can see the yellow highlighting of the union type. Having union-types can be hint that the compiler is in uncertain territory. However, union types are at the very core of how Julia approaches iteration and therefore for-loops, so usually this will not lead to run-time dispatches being triggered.

The situation is much worse when mutable globals are in place.

```julia
x = 5

replace_x(f, vs) = [(f(v) ? x : v) for v in vs]

replace_x((<)(0), -2:2)

@code_warntype replace_x((<)(0), -2:2)
```

We can follow this up with:

```julia
x = "sloppy code!"

replace_x((<)(0), -2:2)
```

:::challenge
### Use parameters or `const`
Put the following code in a file and use `include` to load.

```julia
module TypeUnstable
    x = 5

    replace_x(f, vs) = [(f(v) ? x : v) for v in vs]
end

@code_warntype TypeUnstable.replace_x((<)(0), -2:2)
```

- Change the definition of `x` to a constant using `const`.
- Change the definition of `replace_x` by passing `x` as a parameter.
- Time the result against the type unstable version.
:::

## Logistic model

We'll now introduce a new application: logistic growth. Suppose we model a population $P$ of bacteria in a petri dish. In time we expect the population to grow by some reproduction factor $r$, so

$$\frac{dP}{dt} = rP.$$

However, the total capacity is limited, so this exponential growth needs to plateau at some point. We introduce the **carrying capacity** K.

$$\frac{dP}{dt} = rP \left(1 - \frac{P}{K}\right).$$

This is the logistic model. We may collect these two parameters in a struct. For the moment, we leave out types so that we can choose precision or the use of Unitful quantities later on.

```julia
#| file: src/PopulationModel.jl
module PopulationModel
    <<population-model>>
    <<population-model-main>>
end
```

```julia
#| id: population-model
abstract type LogisticModel end

struct LogisticModelUntyped <: LogisticModel
    reproduction_factor
    carrying_capacity
end
```

A typical ODE solver takes in a function $y' = f(x, t)$.

```julia
ode(model::LogisticModel) = function (x, _)
    x * model.reproduction_factor * (1 - x / model.carrying_capacity)
end
```

We can rewrite this to be a bit nicer.

```julia
#| id: population-model
ode(model::LogisticModel) = function (x, t)
    let r = model.reproduction_factor,
        k = model.carrying_capacity

        x * r * (1 - x / k)
    end
end
```

We can solve an ODE with a simple forward method

```julia
#| id: population-model
function forward_euler(df, y0::T, t) where {T}
    result = Vector{T}(undef, length(t))
    result[1] = y = y0
    dt = step(t)

    for i in 2:length(t)
        y = y + df(y, t[i-1]) * dt
        result[i] = y
    end

    return result
end
```

:::callout
This is our first time encountering a generic function. The `where` clause introduces a type variable that we can use inside the function to create a typed vector. In this case we could still have used `typeof(y0)` to deduce `T`, but the type variable notation is cleaner.
:::

We may write the following `main` function which we can improve on

```julia
#| id: population-model-main
function main(r)
    t = 0.0:0.01:1.0
    y0 = 0.01
    y = forward_euler(ode(LogisticModelUntyped(r, 1.0)), y0, t)
    return t, y
end
```

:::callout
There is a package for solving ODE using better solvers called `DifferentialEquations.jl`. Be warned however, that this package is part of the larger SciML ecosystem. While SciML provides a highly advanced toolkit to do many very complicated things, it has a tendency to pull in a lot of unneeded (transitive) dependencies. In general we recommend caution before using SciML based packages.
:::

:::challenge
### Find the type-instability

a. Run `@code_warntype PopulationModel.ode(PopulationModel.LogisticModelUntyped(10.0, 1.0))(0.01, 0.0)`. Why is there a type instability here?
b. Run `@code_warntype PopulationModel.main(10.0)`. Do you notice anything odd?

::::solution
a. There is no way from just the type information that the compiler can infer the types of the parameters. Dispatch happens on the `LogisticModelUntyped` type, and that's as good as the compiler knows.
b. The `@code_warntype` macro only checks one level deep: the `main` function seems fine on the surface.

We can check type-information deeper in the call tree by using the `@descend` macro from `Cthulhu.jl`.
::::
:::

There are two techniques to fix this problem in this particular case.

## Closures

Upto now we haven't really made a distinction between plain functions and **closures**. A closure is a function that carries a reference to the scope it was defined in. Where we may think of a function as a black box machine, a closure is a box with some memory. This memory can be both mutable or immutable, but what we should make certain about is that the captured variables are type stable!

In our example the closure stores a reference to the `LogisticModelUntyped` structure. The compiler has no way to infer the types of the `reproduction_rate` and `carrying_capacity` members. We can solve this one way by generating a closure that stores these individual numbers directly instead of looking them up in the `LogisticModelUntyped` struct. All we need to do is reverse the `let` binding and inner function definition in the implementation of ode:

```julia
ode(model::LogisticModel) =
    let r = model.reproduction_factor,
        k = model.carrying_capacity

        (x, _) -> x * r * (1 - x / k)
    end
```

:::discussion
Which variables are in the closure of the anonymous function that's being returned here? We have `x` as a parameter, and `r` and `k` are in the lexical scope of the closure. At the time when the function is created, the types of `k` and `r` are completely known.
:::

:::challenge
### Time the new implementation
Rerun `@code_warntype PopulationModel.ode(PopulationModel.LogisticModelUntyped(10.0, 1.0))(0.01, 0.0)` and benchmark the main function with the two versions.
:::

## Generic types
The second and more generic method of solving the issue, is by using generic types.

```julia
struct LogisticModelGeneric{R, K} <: LogisticModel
    reproduction_factor::R
    carrying_capacity::K
end
```

:::challenge
### Generic Types

a. Create an instance of the `LogisticModelGeneric`. You can use the constructor without explicit type arguments as types are deduced from the constructor call.
b. Check the types of the returned instance.
c. Run the `forward_euler` method on `LogisticModelGeneric`; how does this perform?
d. (optional) Try to use some units, say `LogisticModelGeneric(1.5u"1/d", 1.0u"dm^2")` to model the growth of mold on a piece of bread. Do the units affect performance?
:::

:::callout
A good summary on type stability can be found in the following blog post:
- [Writing type-stable Julia code](https://www.juliabloggers.com/writing-type-stable-julia-code/)
:::

---

::: keypoints
- Type instabilities are the bane of efficient Julia
- We can discover type instability using `@profview`, and analyze further using `@code_warntype`.
- Don't use mutable global variables.
- Write your code inside functions.
- Specify element types for containers and structs.
:::
