# ~/~ begin <<episodes/100-introduction-performance.md#src/PopulationModel.jl>>[init]
module PopulationModel
    # ~/~ begin <<episodes/100-introduction-performance.md#population-model>>[init]
    abstract type LogisticModel end
    
    struct LogisticModelUntyped <: LogisticModel
        reproduction_factor
        carrying_capacity
    end
    # ~/~ end
    # ~/~ begin <<episodes/100-introduction-performance.md#population-model>>[1]
    ode(model::LogisticModel) = function (x, t)
        let r = model.reproduction_factor,
            k = model.carrying_capacity
    
            x * r * (1 - x / k)
        end
    end
    # ~/~ end
    # ~/~ begin <<episodes/100-introduction-performance.md#population-model>>[2]
    function forward_euler(df, y0::T, t) where {T}
        result = Vector{T}(undef, length(t))
        result[1] = y = y0
        dt = step(t)
    
        for i in 2:length(t)
            y = y + df(y, t[i-1]) * dt
            result[i] = y
        end
    
        return result
    end
    # ~/~ end
    # ~/~ begin <<episodes/100-introduction-performance.md#population-model-main>>[init]
    function main(r)
        t = 0.0:0.01:1.0
        y0 = 0.01
        y = forward_euler(ode(LogisticModelUntyped(r, 1.0)), y0, t)
        return t, y
    end
    # ~/~ end
end
# ~/~ end
