---
title: Types and Dispatch
---

::: questions

- How does Julia deal with types?
- Can I do Object Oriented Programming?
- People keep talking about multiple dispatch. What makes it so special?
:::

::: objectives

- dispatch
- structs
- abstract types
:::

:::instructor
Parametric types will only be introduced when the occasion arises.
:::

Julia is a dynamically typed language. Nevertheless, we will see that knowing where and where not to annotate types in your program is crucial for managing performance.

In Julia there are two reasons for using the type system:

- structuring your data by declaring a `struct`
- dispatching methods based on their argument types

## Inspection

You may inspect the dynamic type of a variable or expression using the `typeof` function. For instance:

```julia
typeof(3)
```

```output
Int64
```

```julia
typeof("hello")
```

```output
String
```

:::challenge

### (plenary) Types of floats

Check the type of the following values:

a. `3`
b. `3.14`
c. `6.62607015e-34`
d. `6.6743f-11`
e. `6e0 * 7f0`

::::solution
a. `Int64`
b. `Float64`
c. `Float64`
d. `Float32`
e. `Float64`
::::
:::

## Structures

::: keypoints

- Julia is fundamentally a dynamically typed language.
- Static types are only ever used for dispatch.
- Multiple dispatch is the most important means of abstraction in Julia.
- Parametric types are important to achieve type stability.
:::
