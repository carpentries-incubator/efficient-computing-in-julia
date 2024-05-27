# ~/~ begin <<episodes/a01-collatz.md#examples/Collatz/src/Collatz.jl>>[init]
module Collatz

# ~/~ begin <<episodes/a01-collatz.md#count-until>>[init]
function count_until_fn(pred, fn, init)
  n = 1
  x = init
  while true
    if pred(x)
      return n
    end
    x = fn(x)
    n += 1
  end
end
# ~/~ end
# ~/~ begin <<episodes/a01-collatz.md#count-until>>[1]
function count_until(pred, iterator)
  for (i, e) in enumerate(iterator)
    if pred(e)
      return i
    end
  end
  return -1
end
# ~/~ end
# ~/~ begin <<episodes/a01-collatz.md#iterated>>[init]
struct Iterated{Fn,T}
  fn::Fn
  init::T
end

iterated(fn) = init -> Iterated(fn, init)
iterated(fn, init) = Iterated(fn, init)

function Base.iterate(i::Iterated{Fn,T}) where {Fn,T}
  i.init, i.init
end

function Base.iterate(i::Iterated{Fn,T}, state::T) where {Fn,T}
  x = i.fn(state)
  x, x
end

Base.IteratorSize(::Iterated) = Base.IsInfinite()
Base.IteratorEltype(::Iterated) = Base.HasEltype()
Base.eltype(::Iterated{Fn,T}) where {Fn,T} = T
# ~/~ end
# ~/~ begin <<episodes/a01-collatz.md#a-collatz>>[init]
collatz(x) = iseven(x) ? x ÷ 2 : 3x + 1
# ~/~ end
# ~/~ begin <<episodes/a01-collatz.md#a-collatz>>[1]
collatz_stopping_time_v1(n::Int) = count_until_fn(==(1), collatz, n)
# ~/~ end
# ~/~ begin <<episodes/a01-collatz.md#a-collatz>>[2]
collatz_stopping_time_v2(n::Int) = count_until(==(1), recurse(collatz, n))
# ~/~ end

end # module Collatz
# ~/~ end