---
title: Transducers
---

::: questions
- Aren't there better abstractions to deal with parallelism, like `map` and `reduce`?
- What other libraries exist to aid in parallel computing, and what makes them special?
:::

::: objectives
- Exposure to some higher level programming concepts.
- Learn how to work with the pipe `|>` operator.
- Write performant code that scales.
:::

---

::: keypoints
- Transducers are composable functions.
- Using the `|>` operator can make your code consise, with fewer parenthesis, and more readable.
- Overusing the `|>` operator can make your code an absolute mess.
- Using Tranducers you can build scalable data pipe lines.
- Many Julia libraries for parallel computing and data processing are built on top of Tranducers.
:::

