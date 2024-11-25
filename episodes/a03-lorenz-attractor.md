---
title: "Appendix: Lorenz attractor"
---

The Lorenz attractor is a famous example of a dynamic system with chaotic behaviour. That means that the behaviour of this system has a particular high sensitivity to input parameters and initial conditions. The system consists of three coupled differential equations:

$$\partial_t x = \sigma (y - z),$$
$$\partial_t y = x (\rho - z) - y,$$
$$\partial_t z = xy - \beta z,$$

where $x, y, z$ is the configuration space and $\sigma, \rho$ and $\beta$ are parameters.

``` {.julia file=examples/Lorenz/src/Lorenz.jl}

```
