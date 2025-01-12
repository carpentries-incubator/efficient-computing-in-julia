

# Welcome

Welcome to Entangled! This is the project template for working with Pandoc. The template is shipped with a friendly HTML template ideal for documenting projects or writing research notes.

# Building

To build this template, run

```
brei weave
```

The site will appear in `docs/site`.

## Important files

| file or directory | description |
|---|---|
| `docs/index.md` | source for this page |
| `docs/ref.bib` | BibTeX references |
| `docs/contents.md` | source for the contents on the left |
| `docs/weave.toml` | build rules for Pandoc |
| `docs/template` | HTML template, including style sheets |
| `docs/filters` | Lua filters for enhancing document rendering |

# Features

## Citations

Please consider citing [@Hidding2023] if you use Entangled in your research.

## Numbered equations

Equations are numbered and cross-referenced.

[$$a^2 + b^2 = c^2$$]{#eq:pythagoras}

For Pythagoras theorem, refer to Equation @{eq:pythagoras}.

Equations need to be enclosed in a span (`[]{}` syntax) and have an identifier starting with `eq:`.

## Call-out blocks

In the following example we compute Euler's number using the formula,

[$$e = 1 + {1 \over 2!} + {1 \over 3!} + \dots$$]{#eq:eulers-number}

:::callout

### Taylor Expansions

This can be derived from the Taylor expansion of $f(x) = exp(x)$.
:::

## Code blocks

We may implement Equation @{eq:eulers-number} in the C language:

``` {.c #eulers-number}
double eulers_number() {
  double e = 2.0;
  double k = 1.0;
  unsigned i = 1;
  
  while (k > DBL_EPSILON) {
    k /= ++i;
    e += k;
  }
  return e;
}
```

## Detail blocks

In many cases you'll want to hide parts of your document for the casual reader. Detail blocks will be folded when the page loads, but interested readers can still get there.

:::details

### Main program

We compute and display Euler's number in a small program.

``` {.c file=src/euler.c}
#include <float.h>
#include <stdio.h>
#include <stdlib.h>

<<eulers-number>>

int main() {
  printf("Euler's number: %16.14f\n", eulers_number());
  return EXIT_SUCCESS;
}
```

:::

## Evaluate code blocks

You can evaluate code blocks in your shell. Compile the program, and run:

``` {.bash .eval}
gcc src/euler.c -o /tmp/euler
/tmp/euler
```

# Bibliography

::: {#refs}
:::

