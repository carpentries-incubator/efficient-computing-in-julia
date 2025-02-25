# ~/~ begin <<episodes/060-simulating-solar-system.md#scripts/plot-two-body-drift.jl>>[init]
#| classes: ["task"]
#| file: scripts/plot-two-body-drift.jl
#| creates: episodes/fig/two-body-drift.svg
#| collect: figures
module Script

using Unitful
using CairoMakie
using EfficientJulia.Gravity

function main()
    fig = Figure()
    ax = Axis3(fig[1, 1])

    orbits = run_simulation(
        random_particles(2), 1.0u"s", 5000)
    for i in 1:2
        orbit = position.(getindex.(orbits, i))
        lines!(ax, orbit / u"m")
    end
    save("episodes/fig/two-body-drift.svg", fig)
end

end

Script.main()
# ~/~ end
