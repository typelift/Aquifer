# Aquifer

This is a port of [pipes](http://hackage.haskell.org/package/pipes) (and its 
immediate associated ecosystem) to Swift, using 
[Swiftz](https://github.com/typelift/Swiftz) and 
[Focus](https://github.com/typelift/Focus).

For those already familiar with the Haskell libraries, check out the source.  For
everybody else, see the [Tutorial Playground](Tutorial.playground) for a
beginner-level introduction to the major concepts and use-cases of this library.

# Introduction

`Aquifer` is a collection of powerful stream processing abstractions and
a network of components dedicated to stream-like concepts such as IO,
Parser-Combinators, Data Processing, Functional Reactive Programming, and much
more.  The fundamental unit of abstraction is a type called `Proxy` that the
framework further segments into 6 distinct types, each representing a specific
kind of information flow:

* `Producer`s: Types that only `yield` values.
* `Consumer`s: Types that only `await` values.
* `Pipes`s; Types that can both `yield` and `await` values.
* `Client`s: Types that can `request` values and receive `response`s to those requests.
* `Server`s: Types that can `respond` to `request`s with values.
* `Effect`s: A computation made of pipes with all the ends properly fused that can be run to yield values.

Because a `Proxy` is very generic (weighing in at 5 type parameters!), it can
be quite cumbersome to work with.  To combat this, the library declares each
of the above as `typealias`es to mark methods in the library.  Rarely will the
fully expanded form of `Proxy` be seen by the average user.  And when it is
present, it is only to mark operations that can work with any of the 6 types
enumerated above.

# First Principles

For the more advanced user, `Aquifer`'s semantics can be described by a number
of Categories.  To that end, the library includes notes and diagrams to aid
understanding, and to present a detailed graphical view of its most general
parts.  For example, this is the diagram outlining `Proxy`:

```
              Upstream | Downstream
                  +---------+
                  |         |
 Upstream Output <==       <== Downstream Input
                  |         |
 Upstream Input  ==>       ==> Downstream Output
                  |    |    |
                  +----|----+
                       v
                  Final Results
```

And another from the `Request` Category:

```
            IS                   /===>DO                     IS
             |                  /      |                      |
        +----|----+            /  +----|----+            +----|----+
        |    v    |           /   |    v    |            |    v    |
    UO <==       <== DI <==\ / UO<==       <== NI    UO <==       <== NI
        |    f    |         X     |    g    |     =      | f |>| g |
    UI ==>       ==> DO ===/ \ UI==>       ==> NO    UI ==>       ==> NI
        |    |    |           \   |    |    |            |    |    |
        +----|----+            \  +----|----+            +----|----+
             v                  \      v                      v
             FR                  \====>DI                     FR
```

If that all seems complicated, don't worry!  The diagrams are always accompanied
by proper explanations of the semantics of their respective methods in *plain
English*.  If the documentation is ever unclear, feel free to ask a question,
file an issue, or put it in your own words in a pull request.  

# Programming With Pipes

By now you may be wondering how one actually goes about using `Aquifer` to
produce useful programs.  Returning to the `Proxy` type from earlier, each of
its 5 parameters is a different unhandled part of the flow of data through
a pipe that you the user must "seal" or "fuse" using the other combinators in
this library.  For example, the operation `yield` can be thought of as:

```swift
/// Yield leaves a hole of type A that we need to fuse somehow.
func yield<A>(value : A) -> Producer<A, ()>.T
```

`yield` is an operation that returns a value with a "hole" in it that we need to
fill.  In fact, if we were simply to use `yield` by itself, our program would
block indefinitely waiting for the unfused hole to be filled!  A `yield` is
usually connected to, naturally, a `Consumer` pipe, which itself has a hole of
type `A`.  Here we'll hook up the function `stdinLn` (which returns
a `Producer<String, ()>` that `yield`s values from stdin) to the function
`stdoutLn` (which returns a `Consumer<String, ()>` that `await`s values from
some `Producer` and prints them to stdout) with one of many fusing operators `>->`

```swift
let pipe = stdinLn() >-> stdoutLn()
```

The thing to notice about `pipe` is that Swift believes it has the type

```swift
/// How do we know everything's been fused from this type signature alone?
///
///   +-- X indicates the output hole has been filled; fused.
///   |  +-- This pipe only accepts () as input; fused.
///   |  |   +-- This pipe only accepts () as input; fused.
///   |  |   |   +-- X indicates the ouput hole has been filled; fused.
///   |  |   |   |  +-- This pipe ultimately returns () i.e. performs an effect.
///   |  |   |   |  |
///   v  v   v   v  v
Proxy<X, (), (), X, ()>
```

By consulting the handy table of `typealias`es in [`Proxy`](Aquifer/Proxy.swift)'s
definition file it's easy to see that this corresponds to the `Effect` alias.  An 
`Effect` is *only* produced when every input and output from all parts of the pipe
have been fused away, leaving only a program that can be run with the `runEffect` 
combinator.  The practical effect of all of this is that `Aquifer` uses Swift's
type system to aid in the production of fully-formed pipes.  Failure to fuse any one
of the input or ouput holes with a concrete type results in a type error at compile
time.

Putting it all together yields

```swift
/// This program acts like `cat` by blitting any input from stdin to stdout.
runEffect <| stdinLn() >-> stdoutLn()
```

# System Requirements

Aquifer supports OS X 10.9+ and iOS 7.0+.

# Further Reading

