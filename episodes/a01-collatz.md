---
title: "Appendix: Iterators and type stability"
---

::: questions
- I tried to be smart, but now my code is slow. What happened?
:::

::: objectives
- Understand how iterators work under the hood.
- Understand why parametric types can improve performance.
:::

This example is inspired on [material by Takafumi Arakaki](https://juliafolds.github.io/data-parallelism/tutorials/quick-introduction/).

The Collatz conjecture states that the integer sequence

$$x_{i+1} = \begin{cases}x_i / 2 &\text{if $x_i$ is even}\\
	3x_i + 1 &\text{if $x_i$ is odd}
\end{cases}$$

reaches the number $1$ for all starting numbers $x_0$.

``` {.julia #a-collatz}
collatz(x) = iseven(x) ? x ÷ 2 : 3x + 1
```

## Stopping time

We can try to test the Collatz conjecture for some initial numbers, by checking how long they take to reach $1$. A simple implementation would be as follows:

``` {.julia #count-until}
function count_until_fn(pred, fn, init)
  n = 1
  x = init
  while true
    if pred(x)
      return n
    end
    x = fn(x)
    n += 1
  end
end
```

``` {.julia #a-collatz}
collatz_stopping_time_v1(n::Int) = count_until_fn(==(1), collatz, n)
```

This is nice. We have a reusable function that counts how many times we need to recursively apply a function, until we reach a preset condition (predicate). However, in Julia there is a deeper abstraction for iterators, called iterators.

The `count_until` function for iterators becomes a little more intuitive.

``` {.julia #count-until}
function count_until(pred, iterator)
  for (i, e) in enumerate(iterator)
    if pred(e)
      return i
    end
  end
end
```

Now, all we need to do is write an iterator for our recursion.

::: callout
### Iterators
Custom iterators in Julia are implemented using the `Base.iterate` method. This is one way to create lazy collections or even infinite ones. We can write an iterator that takes a function and iterates over its results recursively.

We implement two instances of `Base.iterate`: one is the initializer

    iterate(i::Iterator) -> (item_0, state_0)

the second handles all consecutive calls

	iterate(i::Iterator, state_n) -> (item_n+1, state_n+1)

Then, many functions also need to know the size of the iterator, through `Base.IteratorSize(::Iterator)`. In our case this is `SizeUnknown()`. If you know the length in advance, also implement `Base.length`.

You may also want to implement `Base.IteratorEltype()` and `Base.eltype`.

Later on, we will see how we can achieve similar results using channels.

[Reference](https://docs.julialang.org/en/v1/base/collections/#lib-collections-iteration)
:::

Our new iterator can compute the next state from the previous value, so state and emitted value will be the same in this example.

``` {.julia #recursion-untyped}
struct Recursion
  fn
  init
end

recurse(fn) = init -> Recursion(fn, init)
recurse(fn, init) = Recursion(fn, init)

function Base.iterate(i::Recursion)
  i.init, i.init
end

function Base.iterate(i::Recursion, state)
  x = i.fn(state)
  x, x
end

Base.IteratorSize(::Recursion) = Base.SizeUnknown()
Base.IteratorEltype(::Recursion) = Base.EltypeUnknown()
```

There is a big problem with this implementation: it is slow as molasses. We don't know the types of the members of `Recursion` before hand, and neither does the compiler. The compiler will see a `iterate(::Recursion)` implementation that can contain members of any type. This means that the return value tuple needs to be dynamically allocated, and the call `i.fn(state)` is indeterminate.

We can make this code a lot faster by writing a generic function implementation, that specializes for every case that we encounter.

::: callout
### Function types
In Julia, every function has its own unique type. There is an overarching abstract `Function` type, but not all function objects (that implement `(::T)(args...)` semantics) derive from that class. The only way to capture function types statically is by making them generic, as in the following example.
:::

``` {.julia #recursion-typed}
struct Recursion{Fn,T}
  fn::Fn
  init::T
end

recurse(fn) = init -> Recursion(fn, init)
recurse(fn, init) = Recursion(fn, init)

function Base.iterate(i::Recursion{Fn,T}) where {Fn,T}
  i.init, i.init
end

function Base.iterate(i::Recursion{Fn,T}, state::T) where {Fn,T}
  x = i.fn(state)
  x, x
end

Base.IteratorSize(::Recursion) = Base.SizeUnknown()
Base.IteratorEltype(::Recursion) = Base.HasEltype()
Base.eltype(::Recursion{Fn,T}) where {Fn,T} = T
```

With this definition for `Recursion`, we can write our new function for the Collatz stopping time:

``` {.julia #a-collatz}
collatz_stopping_time_v2(n::Int) = count_until(==(1), recurse(collatz, n))
```

Retrieving the same run times as we had with our first implementation.

::: spoiler

### Collatz module

``` {.julia file=examples/Collatz/src/Collatz.jl}
module Collatz

<<count-until>>
<<recursion-typed>>
<<a-collatz>>

end # module Collatz
```

:::

::: keypoints
- When things are slow, try adding more types.
- Writing abstract code that is also performant is not easy.
:::

