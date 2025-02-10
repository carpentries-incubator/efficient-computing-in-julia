---
title: Introduction to Julia
---

::: questions

- How do I write elementary programs in Julia?
- What are the differences with Python/MATLAB/R?
:::

::: objectives
- functions
- loops
- conditionals
- scoping
:::

Unfortunately, it lies outside the scope of this workshop to give an introduction to the full Julia language. Instead, we'll briefly show the basic syntax, and then focus on some key differences with other popular languages.

::: instructor
Much of the content of the lesson relies on "Show, don't tell". This introduction feels far from complete, but that's Ok.
It is just enough to teach the forms of function definitions, and some peculiarities that might trip-up people that are used to a different language.
:::

## About Julia

These are some words that we will write down: never forget.

- A just-in-time compiled, dynamically typed language
- multiple dispatch
- expression based syntax
- rich macro system

Oddities for Pythonistas:

- 1-based indexing
- lexical scoping

Better well stolen ... Always ask when learning a new language: what are the primitives, the means of combination and the means of abstraction. Many languages are very similar in these regards, so we'll look at things that are different:

| What | Procedures | Data        |
|------|------------|-------------|
| primitives | standard library | (numbers, strings, etc.) arrays, symbols, channels |
| means of combination | (`for`, `if` etc.) broadcasting, `do` | tuples, `struct`, expressions |
| means of abstraction | functions, dispatch, macros (no classes!) | `abstract type`, generics | 

### Eval
How is Julia evaluated? Types only instantiate at run-time, triggering the compile time specialization of untyped functions.

- Julia can be "easy", because the user doesn't have to tinker with types.
- Julia can be "fast", as soon as the compiler knows all the types. 

When a function is called with a hitherto new type signature, compilation is triggered. Julia's biggest means of abstraction: *multiple dispatch* is only an emergent property of this evaluation strategy.

Julia has a heritage from functional programming languages (nowadays well hidden not to scare people). What we get from this:

- expression based syntax: everything is an expression, meaning it reduces to a value
- a rich macro system: we can extend the language itself to suit our needs (not covered in this workshop)

Julia is designed to replace MATLAB:

- high degree of built-in support for multi-dimensional arrays and linear algebra
- ecosystem of libraries around numeric modelling

Julia is designed to replace Fortran:

- high performance
- accelerate using `Threads` or through the GPU interfaces
- scalable through `Distributed` or `MPI`

Julia is designed to replace Conda:

- quality package system with pre-compiled binary libraries for system dependencies
- highly reproducible
- easy to use on HPC facilities

Julia is not (some people might get angry for this):

- a suitable scripting language
- a systems programming language like C or Rust (imagine waiting for `ls` to compile every time you run it)
- replacing either C or Python anytime soon

## Functions

Functions are declared with the `function` keyword. The **block** or function **body** is ended with `end`. All blocks in Julia end with `end`.

```julia
const G = 6.6743e-11

function gravitational_force(m1, m2, r)
  return G * m1 * m2 / r^2
end
```

There is a shorter syntax for functions that is useful for one-liners:

```julia
gravitational_force(m1, m2, r) = G * m1 * m2 / r^2
```

### Anonymous functions (or lambdas)

Julia inherits a lot of concepts from functional programming. There are two ways to define anonymous functions:

```julia
F_g = function(m1, m2, r)
  return G * m1 * m2 / r^2
end
```

And a shorter syntax,

```julia
F_g = (m1, m2, r) -> G * m1 * m2 / r^2
```

::: challenge

### Higher order functions

Use the `map` function in combination with an anonymous function to compute the squares of the first ten integers (use `1:10` to create that range).

:::: solution
Read the documentation of `map` using the `?` help mode in the REPL.

```julia
map(x -> x^2, 1:10)
```

In fact, we'll see that `map` is not often used, since Julia has many better ways to express mapping operations of this kind.
::::
:::

## If statements, for loops

Here's another function that's a little more involved.

```julia
function is_prime(x)
  if x < 2
    return false
  end

  for i = 2:isqrt(x)
    if x % i == 0
      return false
    end
  end

  return true
end
```

:::callout

### Ranges

The `for` loop iterates over the range `2:isqrt(x)`. We'll see that Julia indexes sequences starting at integer value `1`. This usually implies that ranges are given inclusive on both ends: for example, `collect(3:6)` evaluates to `[3, 4, 5, 6]`.
:::

:::callout
### More on for-loops

Loop iterations can be skipped using `continue`, or broken with `break`, identical to C or Python.
:::

::: challenge
The `i == j && continue` is a short-cut notation for

```julia
if i == j
	continue
end
```

We could also have written `i != j || continue`.

In general, the `||` and `&&` operators can be chained to check increasingly stringent tests. For example:

```julia
inbounds(Bool, i, data) && data[i] < 10 && return 3*data[i]
```

Here, the second condition can only be evaluated if the first one was true.

**Rewrite the `is_prime` function using this notation.**

:::: solution
```julia
function is_prime(x)
    x < 2 && return false
    for i = 2:isqrt(x)
        x % i == 0 && return false
    end
    return true
end

is_prime(42)
is_prime(43)
```
::::
:::

:::callout
### Return statement

In Julia, the `return` statement is not always strictly necessary. Every statement is an expression, meaning that it has a value. The value of a compound block is simply that of its last expression. In the above function however, we have a non-local return: once we find a divider for a number, we know the number is not prime, and we don't need to check any further.

Many people find it more readable however, to always have an explicit `return`.

The fact that the `return` statement is optional for normal function exit is part of a larger philosophy: everything is an expression.
:::

:::callout
### Lexical scoping

Julia is **lexically scoped**. This means that variables do not outlive the block that they're defined in. In a nutshell, this means the following:

  ```julia
  let s = 42
    println(s)

    for s = 1:5
      println(s)
    end

    println(s)
  end
  ```

  ```output
  42
  1
  2
  3
  4
  5
  42
  ```

  In effect, the variable `s` inside the for-loop is said to **shadow** the outer definition. Here, we also see a first example of a `let` binding, creating a scope for some temporary variables to live in.

:::

::: challenge

### Loops and conditionals

Write a loop that prints out all primes below 100.

:::: solution

```julia
for i in 1:100
  if is_prime(i)
    println(i)
  end
end
```

If you like to collect those into a vector, try the following:

```julia
1:100 |> filter(is_prime) |> collect
```
::::
:::

## Macros

Julia has macros. These are invocations that change the behaviour of a given piece of code. In effect, arguments of a macro are syntactic forms that can be rewritten by the macro. These can reduce the amount of code you need to write to express certain concepts. You can recognize macro calls by the `@` sign in front of them.

```julia
@assert true "This will always pass"
@assert false "Oh, noes!"
@macroexpand @assert false "Oh, noes!"
```

We will explain some macro's as they are used. We won't get into writing macros ourselves. They can be incredibly useful, but should also come with a warning: overuse of macros can make your code non-idiomatic and therefore harder to read. Also macro-heavy frameworks tend to be harder to debug, and often lack in composability.

## Arrays and broadcasting

Julia has built-in support for multi-dimensional arrays. Any function that can be applied to single values, can also be applied to entire arrays using the concept of **broadcasting**.

```julia
x = -2π:0.01:2π
y = sin.(x)
```

Notice that the broadcasting mechanism works transparently over ranges as well as arrays. We can sequence broadcasted operations:

```julia
y = sin.(x) ./ x
```

The compiler will fuse chained broadcasting operations into a single loop. We could spend half the workshop on getting good at array based operations, but we won't. Instead, we refer to the [Julia documentation on arrays](https://docs.julialang.org/en/v1/manual/arrays/). During the rest of the workshop you will be exposed to array based computation here and there.

::: keypoints

- Julia has `if-else`, `for`, `while`, `function` and `module` blocks that are not dissimilar from other languages.
- Blocks are all ended with `end`.
- Always enclose code in functions because functions are compiled
- Don't use global mutable variables
- Julia variables are not visible outside the block in which they're defined (unlike Python).
:::
