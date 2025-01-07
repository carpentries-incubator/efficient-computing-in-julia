# Efficient computing in Julia

## Synopsis

The Julia programming language is getting more and more popular as a language for data analysis, modelling and optimization problems. It promises the ease of Python or R with a run-time efficiency closer to C or Fortran. Julia also is a more modern language with a packaging ecosystem that makes packages easier to install and maintain. A programmer that is familiar with Python, R or Matlab should have little problem getting up to speed with the basics of Julia. However, to really obtain the promised near native run-time efficiency is a different skill altogether.

This workshop aims to get research software engineers (experienced in another programming language) from their first steps in Julia to become aware of all the major techniques and pitfalls when it comes to writing performant Julia.

We will work hands-on with real-world examples to explore concepts in the Julia language, focussing on differences with other languages. After the first day, you will be familiar with the basic constructs of the language, some popular libraries, and its package manager, including unit testing and documentation.

The second day we will dive deeper in making Julia code fast to run. We'll see how to benchmark and profile code, and find out what is fast and slow. This means getting to grips with Julia's type system and its compilation strategy. We will close the day with parallel programming and using the GPU to make our code even faster.

## Syllabus

- Basics of Julia: build a model of our solar system
  * operations, control flow, functions
  * `Unitful` quantities, `Dataframes` and plotting with `Makie`
  * types and dispatch
  * arrays and broadcasting
- Package development: solving Cubic equations
  * working with the REPL, and `Pkg`
  * best practices with `BestieTemplate`
  * testing with `Test`, documentation with `Documenter`
- Faster code: a logistic population model
  * `BenchmarkTools` and `ProfileView` (flame graphs)
  * Optimisation techniques
  * The type system in more depth
  * Type stability
  * Parallel programming: `Threads` and GPU programming (with Julia fractals)

## Who

This workshop is aimed at scientists and research engineers who are already familiar with another language like Python, Matlab or R. The basics of Julia will be introduced, but it is essential that participants are familiar with programming concepts and are comfortable working with a programming editor and command-line interfaces.

Participants should bring a decent laptop (no chrome book) with the latest version of Julia installed and working (instructions will be provided after registration).

## Teaching this lesson?
Do you want to teach Efficient computing in Julia? This material is open-source and freely available.
Are you planning on using our material in your teaching?
We would love to help you prepare to teach the lesson and receive feedback on how it could be further improved, based on your experience in the workshop.

You can notify us that you plan to teach this lesson by creating an issue in this repository. Also, it would be great if you can update [this overview of all workshops taught with this lesson material](workshops.md). This helps us show the impact of developing open-source lessons to our funders.
