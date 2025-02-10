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

```julia
struct Point2
  x::Float64
  y::Float64
end
```

```julia
let p = Point2(1, 3)
  println("Point at $(p.x), $(p.y)")
end
```

### Methods

```julia
dot(a::Point2, b::Point2) = a.x*b.x + a.y*b.y
```

:::challenge

### 3D Point

Create a structure that represents a point in 3D space and implement the dot product for it.

::::solution

```julia
struct Point3
  x::Float64
  y::Float64
  z::Float64
end

dot(a::Point3, b::Point3) = a.x*b.x + a.y*b.y + a.z*b.z
```

::::
:::

## Multiple dispatch (function overloading)

```julia
Base.:+(a::Point2, b::Point2) = Point2(a.x+b.x, a.y+b.y)
```

```julia
Point2(1, 2) + Point2(-1, -1)
```

```output
Point2(0, 1)
```

:::callout

## OOP (Sort of)

Julia is not an Object Oriented language. If you feel the unstoppable urge to implement a class-like abstraction, this can be done through abstract types.

```julia
abstract type Vehicle end

struct Car <: Vehicle
end

struct Bike <: Vehicle
end

bike = Bike()
car = Car()

function direction(v::Vehicle)
  return "forward"
end

println("A bike moves: $(direction(bike))")
println("A car moves: $(direction(car))")

function fuel_cost(v::Bike, distance::Float64)
  return 0.0
end

function fuel_cost(v::Car, distance::Float64)
  return 5.0 * distance
end

println("Cost for riding a bike for 10km: $(fuel_cost(bike, 10.0))")
println("Cost for driving a car for 10km: $(fuel_cost(car, 10.0))")
```

```output
A bike moves: forward
A car moves: forward
Cost for riding a bike for 10km: 0.0
Cost for driving a car for 10km: 50.0
```

An abstract type cannot be instantiated directly:

```julia
vehicle = Vehicle()
```

```output
ERROR: MethodError: no constructors have been defined for Vehicle
The type `Vehicle` exists, but no method is defined for this combination of argument types when trying to construct it.
```

:::

::: keypoints

- Julia is fundamentally a dynamically typed language.
- Static types are only ever used for dispatch.
- Multiple dispatch is the most important means of abstraction in Julia.
- Parametric types are important to achieve type stability.
:::

