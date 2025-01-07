# ~/~ begin <<episodes/a03-lorenz-attractor.md#examples/Lorenz/src/Lorenz.jl>>[init]
module Lorenz

@kwdef struct Parameters
    sigma::Float64
    rho::Float64
    beta::Float64
end

mutable struct State
    x::Float64
    y::Float64
    z::Float64
end



end
# ~/~ end
