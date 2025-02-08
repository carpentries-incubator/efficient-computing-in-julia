---
title: Best Practices in Package development
---

::: questions
- How do I generate a new Julia package that follows best practices?
- What is the best workflow for developing a Julia package?
- How can I prevent having to recompile every time I make a change?
:::

::: objectives
- Quick start with using the BestieTemplate to generate a package
- Basic structure of a package
- Revise.jl
:::


We will use a Julia template called `BestieTemplate`. The template code can be found on `GitHub`: <https://github.com/JuliaBesties/BestieTemplate.jl>.

Using the template automates the process of setting up the Julia package structure and adding all the small files and tools to help with applying best practices.

## Installing `BestieTemplate.jl`

In order to use `BestieTemplate` to create our new package, we first need to install it.

Open the `Julia` interpreter and enter `pkg` mode by pressing `]`. Then use `add` as we have done in previous exercises:

```shell
julia> # press ]
pkg> add BestieTemplate
```

This might take a couple of minutes to download.

## Generating a fresh new Julia package

We then use the `BestieTemplate` package to generate a new (empty) package at the specified path.

```shell
pkg> # Press backspace to get out of pkg mode
julia> using BestieTemplate
julia> BestieTemplate.generate("MyPackage.jl")
```

:::callout
It is actually posible to apply this template to existing packages too:
```shell
BestieTemplate.apply("path/to/YourExistingPackage.jl")
```
However, for clarity we generate a completely new package in this lesson.
:::


You will now be presented with a series of questions, some required and some optional.

1. Firstly you will be asked to choose a universally unique identifier (UUID) for the new package. This is a label to uniquely identify your package, thus avoiding relying on the package name (identically named packages are fairly likely to occur in a programming community). Luckily, `BestieTemplate` has auto-generated one for you. Press enter to select it.

2. Type in your GitHub username, if you have one. If you don't, then make one up as it does not really matter for this example. This allows BestieTemplate.jl to correctly generate URLs to your (potential) package repository (Julia typically expects packages to be on GitHub)

3. Add the comma separated list of authors. You can type your own name and email here.

4. Add the minimum Julia version that will be supported by your new package. BestieTemplate automatically suggests the latest Long Term Support (LTS) version, so we will press enter to use that one.

5. Choose a license for your package. This is up to the user. Use the arrow keys to select e.g. `Apache-2.0`.

6. Add the names of the copyright holders - again, this should be pre-filled with the name you typed earlier.

You will then be provided with the option to only answer a small number of 'Recommended' questions (first choice). Select this and choose the default (pre-filled) values for each.

Your new package structure will now be created, with configuration files set up according to the answers provided to the previous questions.


## Structure of your new (empty) package

* `.copier-answers.yml`
Here you can see the answers you provided when setting up your package with the `BestieTemplate`.

* `Project.toml`
The `Project.toml` file specifies the name of our package, UUID and authors (as given in our answers when setting up the template). It also specifies the package's current version
and dependencies.

* `README.md`
Standard place to document the purpose of the package, installation instructions, links to more extensive documentation etc.

* `CODE_OF_CONDUCT.md`
A clear description about how contributors are expected to behave and what processes are available in the event of a breach of conduct.

* `LICENSE`
Contains the text for the software license you chose for this package.

* `CITATION.cff`
Stores any authors or contributors to the package, allowing the software itself to be citable.

* Formatting tool configuration files: `.JuliaFormatter.toml`, `.pre-commit-config.yaml`, `.yamllint.yml`, `.markdownlint.json`
These configure the behaviour of linters and other code-style enforcement tools. They are important for keeping a clean and tidy code base.

* `src/`
The location of source code files.

* `test/`
The location of unit tests for the code in this package.

* `docs/`
The location of scripts for automatically building documentation for the functions in your package (e.g. based on docstrings). In the `docs/src/` directory you can also see some documentation pages explaining how to contribute to the package.

* `.github/`
This will only come into use if you push your package to GitHub. This directory contains some automated workflows that do things like run tests, build documentation etc.


### Activating the generated package

Now that we have generated our new package and inspected its contents and structure, we would like to use it.

In the shell, let's enter the the directory of the new package, and open the `Julia` REPL:
```shell
cd MyPackage.jl/
julia
```

We will start by checking what environment we are actually currently using. We do this with the `pkg> status` command:
```shell
julia> # press ]
pkg> status
```

The output will show something like the following:
```output
Status `~/.julia/environments/v1.11/Project.toml`
```

This tells us that we are currently using the base environment for the currently installed `Julia` version (in the above case, `v1.11`. In a sense, you can think of this as the "default" or "global" environment used by `Julia`, if no other has been specified by the user.

The output of `pkg> status` will also output the dependencies (and precise versions) that are currently installed in that environment. For example, you should see the `BestieTemplate` package that we installed earlier to generate our new package.

But we don't currently want this environment. We would like to use, and work on, our new project. We do this by "activating" it:
```shell
pkg> activate .
```

Now let us check the `pkg` status again:
```shell
pkg> status
```

The output should now show `Project MyPackage v0.1.0`, indicating that we are indeed using our new package.
The "Status" line will also now give the path to the `MyPackage.jl`'s `Project.toml`, which is another sign that everything is in order. However, the end of the line will say `(empty project)`, because there are currently no dependencies of our package.


### Adding dependencies 

As before, we can try adding the `Random` package.

```shell
pkg> add Random
```

Checking the new contents of `Project.toml`, we see that a `[deps]` section has appeared:
```output
[deps]
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
```
This shows that the `Random` package is a dependency of our package, and also specifies the UUID that precisely identifies the package. Remember that our package, `MyPackage.jl` also has such a UUID.

Running `pkg> status` again will now also list this dependency, instead of "(empty project)".

You should now see that a `Manifest.toml` file is also in the package directory. In this file, you should see something like the following:

```output
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.3"
manifest_format = "2.0"
project_hash = "edf6df7b02a39be5254eb0c7ce37b253a09a1e4c"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"
```

As before, we can now remove this `Random` package because we do not need it.

```shell
pkg> remove Random
```

If we check `pkg> status` again, we see that we have returned to the "(empty project)" state. Similarly, looking inside `Project.toml` we see that the dependency has indeed disappeared from the project.


## Developing the package

Now that we have our empty package set up, we would like to develop some code for it!

Navigate to `src/MyPackage.jl` to see some dummy code has already been generated by the template:
```julia
module MyPackage

"""
    hi = hello_world()
A simple function to return "Hello, World!"
"""
function hello_world()
    return "Hello, World!"
end

end
```

In the REPL we can try running this:
```shell
julia> using MyPackage
julia> MyPackage.hello_world()
```

```output
"Hello, World!"
```

Note that we needed `using MyPackage` to tell Julia to make the name `MyPackage` available for us to refer to. We then called the `hello_world` function that is part of that module.


:::challenge

### The world is not enough

But perhaps the "World" is not inclusive enough. Let's try saying hello to the whole universe. Try modifying the function to say "Hello, Universe!" then call it in the REPL again.

Before doing this - what do you think the result will be?

::::solution

```julia
function hello_world()
    return "Hello, Universe!"
end
```

```shell
julia> MyPackage.hello_world()
```

```output
"Hello, World!"
```

Why did this happen? The answer is that Julia is using the version of the package as it existed when it was first loaded. The modifications you have made have not been tracked or recompiled, so the original function is still being called.

If you reload Julia (exit then open the REPL again) and try again, you will see the result now says "Universe" as desired.

Change the message back to `Hello, World!` for now.

::::
:::


Julia uses the package `MyPackage` in whatever state it is when `using` is first called. Subsequent changes to the source code do not trigger automatic recompilation, unless e.g. Julia is restarted. This is problematic since, during development, we often want to make changes to our code without restarting the Julia session to check it. We can achieve this with `Revise.jl`.


### Installing `Revise.jl`

Make sure you are in the default environment when you install `Revise.jl`, as we generally do not want developer dependencies to be a part of the package. Anything you install in the default shared environment will be available in specific environments too due to what is called "environment stacking".

```shell
pkg> activate # No argument, so as to pick the default environment
pkg> status
pkg> add Revise
```

### Trying out `Revise.jl`

Now we are ready to try out `Revise`. Exit the Julia REPL and reload it, then indicate we wish to use `Revise`.

```shell
julia
julia> using Revise
pkg> activate . # Start using our local package environment again
```

:::callout
You must load `Revise` _before_ loading any packages you want it to track.
:::

Try loading and using our package again.

```shell
julia> using MyPackage
julia> MyPackage.hello_world()
```

```output
"Hello, World!"
```

Now try editing the message to say `Goodbye, World!`. Remember to save your changes.

```shell
julia> MyPackage.hello_world()
```

```output
"Goodbye, World!"
```

Now, thanks to `Revise`, the change to the package's code was being tracked and was automatically recompiled. This means you can make changes to the package and have them be active without needing to reload the Julia REPL.

:::callout
While `Revise` does its best to track any changes made, there are some limits to what can be done in a single Julia session. For example, changes to type definitions or `const`s (among others) will probably still necessitate restarting your Julia session.
:::



::: keypoints
- You can use the `BestieTemplate` to generate a new package structure complete with tooling for best practices in Julia development.
- The `Revise.jl` module can automatically reload parts of your code that have changed.
- Best practice: file names should reflect module names.
:::
