---
title: Best practices
---

::: questions
- How do I setup unit testing?
- What about documentation?
- Are there good Github Actions available for CI/CD?
- I like autoformatters for my code, what is the best one for Julia?
- How can I make all this a bit easier?
:::

::: objectives
- tests
- documentation
- GitHub workflows
- JuliaFormatter.jl
:::


In this lesson, we will cover issues of best practices in Julia package development. In particular, this covers testing, documentation and formatting.

If you followed the instructions from the previous lesson (using the `BestieTemplate` to generate a package) then all these topics have already been handled.

We will start with adding a new function to our `MyPackage.jl` package, and show how to quickly add unit tests and documentation.

## Preparing for developing

As before, we open the Julia REPL, activate our package and load `Revise`:
```shell
julia
julia> activate .
julia> using Revise
```


## The roots of a cubic polynomial

The following is a function for computing the roots of a cubic polynomial

$$ax^3 + bx^2 + cx + d = 0.$$

There is an interesting story about these equations. It was known for a long time how to solve quadratic equations.
In 1535 the Italian mathematician Tartaglia discovered a way to solve cubic equations, but guarded his secret carefully.
He was later persuaded by Cardano to reveal his secret on the condition that Cardano wouldn't reveal it further. However, later Cardano found out that an earlier mathematician Scipione del Ferro had also cracked the problem and decided that this anulled his deal with Tartaglia, and published anyway.
These days, the formula is known as Cardano's formula.

The interesting bit is that this method requires the use of complex numbers.

```julia
function cubic_roots(a, b, c, d)
	cNaN = NaN+NaN*im
	
	if (a != 0)
		delta0 = b^2 - 3*a*c
		delta1 = 2*b^3 - 9*a*b*c + 27*a^2*d
		cc = ((delta1 + sqrt(delta1^2 - 4*delta0^3 + 0im)) / 2)^(1/3)
		zeta = -1/2 + 1im/2 * sqrt(3)

		k = (0, 1, 2)
		return (-1/(3*a)) .* (b .+ zeta.^k .* cc .+ delta0 ./ (zeta.^k .* cc))
	end

	if (b != 0)
		delta = sqrt(c^2 - 4 * b * d + 0im)
		return ((-c - delta) / (2*b), (-c + delta) / (2*b), cNaN)
	end

	if (c != 0)
		return (-d/c + 0.0im, cNaN, cNaN)
	end

	if (d != 0)
		return (cNaN, cNaN, cNaN)
	end

	return (0.0+0.0im, cNaN, cNaN)
end
```

We would like to add the above `cubic_roots()` function to the `MyPackage.jl` package.

Add it to the `src/MyPackage.jl` file and save.

Let us load our package and attempt to use the `cubic_roots()` function:

```shell
julia> using MyPackage
julia> MyPackage.cubic_roots(1,1,1,1)
```

```output
(-1.0 - 0.0im, -3.700743415417188e-17 - 1.0im, -9.25185853854297e-17 + 1.0im)
```

We see that it is indeed returning some roots to the equation we defined: $$x^3 + x^2 + x + 1 = 0.$$


### Testing

#### Testing `hello_world()`
If we are to develop our package further, we may worry that any changes we make might break existing functionality. For this reason, it is important to add automated tests that can tell us immediately if the behaviour of our existing functions has changed.

In the `test/` directory of `MyPackage.jl` you should see that there already exists an example test for the `hello_world()` function, in `test-basic-test.jl`:
```julia
@testset "MyPackage.jl" begin
    @test MyPackage.hello_world() == "Hello, World!"
end
```

`@testset` is used to define a suite of many tests, while `@test` defines a single check. In this case, there is one test and it checks that the `hello_world()` function indeed returns "Hello, World!".

#### Running the tests

We first need to add the standard Julia `Test` package:
```shell
pkg> add Test
```

Then we can run all tests for our package by simply typing `test`:
```shell
pkg> test
```

The outcome of our `hello_world()` test now will depend on what state the `hello_world()` function is currently in. If you modified it in the previous lesson and it no longer returns "Hello, World!", then the test will fail. Try changing the function to make the tests fail and then pass again.

:::challenge
#### Add a test for `cubic_roots`

Create a new file in the `test/` directory, called `test-cubic.jl`.

Using what you know from the `hello_world()` tests, can you populate this file with a test for the following case:

* For the special case with $$a=0, b=0, c=0, d=0$$ check that the only (non-NaN) solution is 0.

Hint: You only need to check the first element of the returned tuple.


::::solution

The contents of `test-cubic.jl` should be e.g.
```julia
@testset "MyPackage.jl" begin
    @test MyPackage.cubic_roots(0,0,0,0)[1] == 0
end
```

Then, running `pkg> test` will result in a pass.

Note that the equality check would also work with:
```julia
    @test MyPackage.cubic_roots(0,0,0,0)[1] == 0.0
```
and
```julia
    @test MyPackage.cubic_roots(0,0,0,0)[1] == 0.0+0.0im
```

::::
:::

### Documentation

#### Documenting `hello_world()`

The `hello_world()` function has a docstring before it:
```julia
"""
    hi = hello_world()
A simple function to return "Hello, World!"
"""
```
This is low-level technical documentation for this particular function. 

#### Using the REPL help mode
In the Julia REPL, pressing `?` will enter help mode. You can then type the name of a function you would like documentation about:
```shell
julia> # Press '?'
help?> MyPackage.hello_world()
```

```output

  │ Warning
  │
  │  The following bindings may be internal; they may change or be removed in future versions:
  │
  │    •  MyPackage.hello_world

  hi = hello_world()

  A simple function to return "Hello, World!"
```


#### Building the docs
The standard package for building beautiful documentation websites for Julia packages is `Documenter.jl`. It can be seen in the `Project.toml` for the `docs/` directory that this is indeed the package that `BestieTemplate.jl` has set up for us.

In `docs/make.jl` we see `Documenter` being used to build the documentation website, that is then deployed to GitHub Pages where it is served from.

However, presently the code makes a lot of assumptions about being used with git on GitHub, and local builds tend not to render nicely. For a taste of how it looks when fully rendered, see e.g. <https://partitionedarrays.github.io/PartitionedArrays.jl/stable/>.

### Formatting
A good automatic formatter for Julia is `JuliaFormatter.jl`

```shell
pkg> add JuliaFormatter
julia> using JuliaFormatter
```

Then you can try it out on our source file:

```shell
julia> format("src/MyPackage.jl")
```

Not a huge amount will change, but you may notice that spaces are inserted around arithmetic operators, for example:
```
cNaN = NaN+NaN*im
```
becomes
```
cNaN = NaN + NaN * im
```

The configuration for the formatting in our package is set in `.JuliaFormatter.toml`. In practice, you will not run this formatter manually, but it will be automated by workflows created by the `BestieTemplate`. This course does not focus on these (largely they are integrated with `git` and `GitHub`) but they are helpful with ensuring a clean code base with minimal effort.


::: keypoints
- Julia has integrated support for unit testing.
- `Documenter.jl` is the standard package for generating documentation.
- The Julia ecosystem is well equiped to help you keep your code in fit shape.
:::

