module DaisyWorld

using LinearAlgebra

module ODE

function forward_euler(df, y0, t)
    result = Vector{typeof(y0)}(undef, length(t) + 1)
    result[1] = y = y0
    dt = step(t)

    for i in eachindex(t)
        y = y + df(y, t) * dt
        result[i+1] = y
    end
    
    return result
end

end

abstract type AbstractInput end
Broadcast.broadcastable(input::AbstractInput) = Ref(input)

@kwdef struct Daisy
    name::Symbol
    albedo::Float64
end

@kwdef struct Parameters <: AbstractInput
    daisies::Vector{Daisy} = Daisy[Daisy(:black, 0.25), Daisy(:white, 0.75)]
    barren_albedo::Float64 = 0.5
    optimal_temperature::Float64 = 295.5
    k::Float64 = 17.5^-2
    heat_transfer_coeff::Float64 = 2.06e9
    insolation::Float64 = 917.0
    luminosity::Float64 = 1.0
    boltzmann_constant::Float64 = 5.67e-8
    death_rate::Float64 = 0.1
end

birth_rate(p::Parameters, T) = let T_star_2 = (T - p.optimal_temperature)^2
    T_star_2 < (1/p.k) ? 1 - p.k * T_star_2 : 0.0
end

barren(q) = 1.0 - sum(q)

"""
    albedo(obj)

Returns the albedo of an object.
"""
albedo(p, q) = q ⋅ albedo.(p.daisies) + barren(q) * p.barren_albedo

albedo(d::Daisy) = d.albedo

local_temperature_4(p, q) =
    p.heat_transfer_coeff .* (albedo(p, q) .- albedo.(p.daisies)) .+
    planetary_temperature_4(p, q)

planetary_temperature_4(p, q) = p.insolation*p.luminosity / p.boltzmann_constant * (1 - albedo(p, q))

increase_rate(p, q) =
    q .* (barren(q) .* birth_rate.(p, local_temperature_4(p, q).^(1/4)) .- p.death_rate)

module Analysis
using Makie
using GeometryBasics
using ..DaisyWorld
using ..ODE: forward_euler

function plot_birth_rate()
    p = DaisyWorld.Parameters()
    t = 270.0:0.1:320.0
    lines(t, DaisyWorld.birth_rate.(p, t))
end

function luminosity_area_fraction()
    Ls = 0.6:0.01:1.4
    
    function asymptotic_value(L)
        q = 0.2 * 917 * L / 5.67e-8
        p = DaisyWorld.Parameters(luminosity=L, death_rate=0.5, heat_transfer_coeff=q)
        area = forward_euler(
            (y, t)->DaisyWorld.increase_rate(p, y),
            Vec2d(0.5, 0.5),
            0.0:1.0:1000.0) |> last
        temp = DaisyWorld.planetary_temperature_4(p, area)^(1/4)
        (area=area, temp=temp)
    end

    areas = asymptotic_value.(Ls)
    fig = Figure()
    ax1 = Axis(fig[1,1])
    ax2 = Axis(fig[2,1])
    lines!(ax1, Ls, [a.area[1] for a in areas])
    lines!(ax1, Ls, [a.area[2] for a in areas])
    lines!(ax1, Ls, [sum(a.area) for a in areas])

    lines!(ax2, Ls, [a.temp for a in areas])
    fig
end

end

end


