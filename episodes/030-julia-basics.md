---
title: Julia Syntax
---

::: questions

- How do I write elementary programs in Julia?
- What are the differences with Python/Matlab/R?
:::

::: objectives

- functions
- loops
- conditionals
- containers: arrays, dictionary, set
- primitive types
- strings (inc interpolation)
- scoping (and do syntax?)
:::

Unfortunately, it lies outside the scope of this workshop to give a introduction to the full Julia language. Instead, we'll briefly show the basic syntax, and then focus on some key differences with other popular languages.

## Functions

Functions are declared with the `function` keyword. The **block** or function **body** is ended with `end`. All blocks in Julia end with `end`.

```julia
const G = 6.6743e-11

function gravitational_force(m1, m2, r)
  return G * m1 * m2 / r^2
end
```

Let's compute the force between Earth and Moon, given the following constants:

```julia
const EARTH_MASS = 5.97219e24
# const EARTH_RADIUS = 6.378e6
const LUNAR_MASS = 7.34767e22
const LUNAR_DISTANCE = 384_400_000.0
```

```julia
gravitational_force(EARTH_MASS, LUNAR_MASS, LUNAR_DISTANCE)
```

```output
1.982084770423259e26
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
Read the documentation of `map` using the `?` help mode, also available in Pluto.

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

### Return statement

In Julia, the `return` statement is not always strictly necessary. Every statement is an expression, meaning that it has a value. The value of a compound block is simply that of its last expression. In the above function however, we have a non-local return: once we find a divider for a number, we know the number is not prime, and we don't need to check any further.

Many people find it more readable however, to always have an explicit `return`.
:::

:::callout

### More on for-loops

Loop iterations can be skipped using `continue`, or broken with `break`, identical to C or Python.
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

::::
:::

::: keypoints

- Julia has `if-else`, `for`, `while`, `function` and `module` blocks that are not dissimilar from other languages.
- Blocks are all ended with `end`.
- ...
- Julia variables are not visible outside the block in which they're defined (unlike Python).
:::
