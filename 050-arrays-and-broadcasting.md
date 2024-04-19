---
title: Arrays, broadcasting and (some) Linear Algebra
---

::: questions
- Does Julia have something similar to NumPy?
- How do I deal with arrays without writing for-loops everywhere?
:::

::: objectives
- Apply dot-notation broadcasting
- Understand array type notation
- Array indexing and manipulation (push, append)
- 1d and 2d concatenation (vcat, hcat, stack)
- Basic linear algebra: matrix multiply and solving `\`.
- Helper functions to generate vectors and matrices: zeros, ones, rand
- LinearAlgebra package and main functions: dot, norm
:::

::: keypoints
- Julia has column-major array lay-out, which may be confusing when you come from a row-major language like NumPy.
- Use `.` notation to do point-wise computations on arrays.
- Linear algebra is fully supported in the standard library.
:::

