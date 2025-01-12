---
title: "Performance: do's and don'ts"
---

::: questions
- Can you give me some guiding principles on how to keep Julia code performant?
:::

::: objectives
- Identify potential problems with given code.
:::

## Type Stability

:::callout
A good summary on type stability can be found in the following blog post:
- [Writing type-stable Julia code](https://www.juliabloggers.com/writing-type-stable-julia-code/)
:::

---

::: keypoints
- Don't use mutable global variables.
- Write your code inside functions.
- Specify element types for containers and structs.
- Specialize functions instead of doing manual dispatch.
- Write functions that always return the same type (type stability).
- Don't change the type of variables.
:::
