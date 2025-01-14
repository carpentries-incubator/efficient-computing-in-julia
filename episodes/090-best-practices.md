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
- BestieTemplate.jl
:::

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

::: keypoints
- Julia has integrated support for unit testing.
- `Documenter.jl` is the standard package for generating documentation.
- The Julia ecosystem is well equiped to help you keep your code in fit shape.
:::

