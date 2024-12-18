---
title: Dijkstra's shortest path algorithm
---

``` {.julia file=examples/Dijkstra/src/Dijkstra.jl}
module Dijkstra

<<generic-dijkstra>>

end
```

``` {.julia #grid-dijkstra}
using DataStructures

function grid_dijkstra(
  ::Type{T}, size::NTuple{Dim,Int},
  start::Vector{CartesianIndex{Dim}}, istarget::Function,
  neighbours::Function, dist_func::Function) where {T,Dim}

  visited = fill(false, size)
  distance = fill(typemax(T), size)
  for s in start
    distance[s] = zero(T)
  end
  queue = PriorityQueue{CartesianIndex{Dim},T}()
  prev = Array{CartesianIndex{Dim},Dim}(undef, size)
  for s in start
    enqueue!(queue, s, zero(T))
  end
  current = nothing
  while !isempty(queue)
    current = dequeue!(queue)
    istarget(current) && break
    visited[current] && continue
    for loc in neighbours(current)
      visited[loc] && continue
      d = distance[current] + dist_func(current, loc)
      if d < distance[loc]
        distance[loc] = d
        prev[loc] = current
        enqueue!(queue, loc, d)
      end
    end
    visited[current] = true
  end
  (distance=distance, route=prev, target=current)
end
```

``` {.julia #generic-dijkstra}
function dijkstra(neighbours, start, target)
    unvisited = Set()
    distance = Dict()
    distance[start] = 0

end
```
