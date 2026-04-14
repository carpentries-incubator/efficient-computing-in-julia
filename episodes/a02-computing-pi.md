---
title: Appendix, Multi-threading and type stability
---

Here we have an algorithm that computes the value of π to high precision. We can make this algorithm parallel by recursively calling `Threads.@spawn`, and then `fetch` on each task. Unfortunately the return type of `fetch` is never known at compile time. We can keep the type instability localized by declaring the return types.

The following algorithm is [copy-pasted from Wikipedia](https://en.wikipedia.org/wiki/Chudnovsky_algorithm).

```julia
function binary_split_1(a, b)
    Pab = -(6*a - 5)*(2*a - 1)*(6*a - 1)
    Qab = 10939058860032000 * a^3
    Rab = Pab * (545140134*a + 13591409)
    return Pab, Qab, Rab
end

setprecision(20, base=30) do
    _, q, r = binary_split_1(big(1), big(2))
    (426880 * sqrt(big(10005.0)) * q) / (13591409*q + r)
end

# The last few digits are wrong... check
setprecision(20, base=30) do
    π |> BigFloat
end

# The algorithm refines by recursive binary splitting
# Recursion is fine here: we go 2logN deep.

function binary_split(a, b)
    if b == a + 1
        binary_split_1(a, b)
    else
        m = div(a + b, 2)
        Pam, Qam, Ram = binary_split(a, m)
        Pmb, Qmb, Rmb = binary_split(m, b)

        Pab = Pam * Pmb
        Qab = Qam * Qmb
        Rab = Qmb * Ram + Pam * Rmb
        return Pab, Qab, Rab
    end
end

function chudnovsky(n)
    P1n, Q1n, R1n = binary_split(big(1), n)
    return (426880 * sqrt(big(10005.0)) * Q1n) / (13591409*Q1n + R1n)
end

setprecision(10000)
@btime chudnovsky(big(20000))

# We can create a parallel version by spawning jobs. These are green threads.

function binary_split_td(a::T, b::T) where {T}
    if b == a + 1
        binary_split_1(a, b)
    else
        m = div(a + b, 2)
        t1 = @Threads.spawn binary_split_td(a, m)
        t2 = @Threads.spawn binary_split_td(m, b)

        Pam, Qam, Ram = fetch(t1)
        Pmb, Qmb, Rmb = fetch(t2)

        Pab = Pam * Pmb
        Qab = Qam * Qmb
        Rab = Qmb * Ram + Pam * Rmb
        return Pab, Qab, Rab
    end
end

function chudnovsky_td(n)
    P1n, Q1n, R1n = binary_split_td(big(1), n)
    return (426880 * sqrt(big(10005.0)) * Q1n) / (13591409*Q1n + R1n)
end
```

The following may show why the parallel code isn't faster yet.

```julia
setprecision(10000)
@btime chudnovsky_td(big(20000))
@profview chudnovsky_td(big(200000))
```

```julia
@code_warntype chudnovsky_td(big(6))
```

- The red areas in the flame graph show type unstable code (marked with **run-time dispatch**)
- Yellow regions are allocations.
- The same can be seen in the code, as a kind of histogram back drop.

The code is also inefficient because `poptask` is very prominent. We can make sure that each task is a bit beefier by reverting to the serial code at some point. Insert the following in `binary_split_td`:

```julia
elseif b - a <= 1024
    binary_split(a, b)
```

We can limit the type instability by changing the `fetch` lines:

```julia
Pam::T, Qam::T, Ram::T = fetch(t1)
Pmb::T, Qmb::T, Rmb::T = fetch(t2)
```

::: challenge
### Rerun the profiler
Rerun the profiler and `@code_warntype`. Is the type instability gone?

:::: solution

```julia
function binary_split_td(a::T, b::T) where {T}
    if b == a + 1
        binary_split_1(a, b)
    elseif b - a <= 1024
        binary_split(a, b)
    else
        m = div(a + b, 2)
        t1 = @Threads.spawn binary_split_td(a, m)
        t2 = @Threads.spawn binary_split_td(m, b)

        Pam::T, Qam::T, Ram::T = fetch(t1)
        Pmb::T, Qmb::T, Rmb::T = fetch(t2)

        Pab = Pam * Pmb
        Qab = Qam * Qmb
        Rab = Qmb * Ram + Pam * Rmb
        return Pab, Qab, Rab
    end
end
```

Yes!
::::

:::
