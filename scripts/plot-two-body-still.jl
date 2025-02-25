# ~/~ begin <<episodes/060-simulating-solar-system.md#scripts/plot-two-body-still.jl>>[init]
#| classes: ["task"]
#| file: scripts/plot-two-body-still.jl
#| creates: episodes/fig/random-orbits.svg
#| collect: figures
module Script

using Unitful
using CairoMakie
using EfficientJulia.Gravity

function main()
    fig = Figure(size=(1000, 500))
    ax1 = Axis3(fig[1, 1])

    orbits = run_simulation(
        set_still!(random_particles(2)), 1.0u"s", 5000)
    for i in 1:2
        orbit = position.(getindex.(orbits, i))
        lines!(ax1, orbit / u"m")
    end

    ax2 = Axis3(fig[1, 2])
    orbits = run_simulation(
        set_still!(random_particles(3, seed=3)), 1.0u"s", 5000)
    for i in 1:3
        orbit = position.(getindex.(orbits, i))
        lines!(ax2, orbit / u"m")
        scatter!(ax2, orbit[end] / u"m")
    end
    save("episodes/fig/random-orbits.svg", fig)
end

end

Script.main()
# ~/~ end
