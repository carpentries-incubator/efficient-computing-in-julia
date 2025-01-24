# ~/~ begin <<episodes/130-functional-techniques.md#src/CA.jl>>[init]
#| file: src/CA.jl
module CA
    using GLMakie
    using StaticArrays
    
    # ~/~ begin <<episodes/130-functional-techniques.md#ca>>[init]
    #| id: ca
    abstract type BoundaryType{dim} end

    struct Periodic{dim} <: BoundaryType{dim} end
    struct Constant{dim, val} <: BoundaryType{dim} end

    get_bounded(::Type{Periodic{dim}}, arr, idx) where {dim} =
        arr[mod1.(Tuple(idx), size(arr))...]

    get_bounded(::Type{Constant{dim, val}}, arr, idx) where {dim, val} =
        checkbounds(Bool, arr, idx) ? arr[idx] : val
    # ~/~ end
    # ~/~ begin <<episodes/130-functional-techniques.md#ca>>[1]
    #| id: ca
    """
        stencil(f, BoundaryType{dim}, size)

    The function `f` should take an `AbstractArray` with size `size` as input
    and return a single value, and `size` should be a tuple of length `dim` giving
    the size of the stencil. Then, `stencil` returns a function of two arguments
    `in` and `out` that should be arrays of the same shape.
    """
    function stencil(f, ::Type{BT}, stencil_size) where {dim, BT <: BoundaryType{dim}}
        center = CartesianIndex((div.(stencil_size, 2) .+ 1)...)
        function (inp::AbstractArray{T}, out) where {T}
            @assert size(inp) == size(out)
            nb = zeros(MArray{Tuple{stencil_size...}, T})
            for i in eachindex(IndexCartesian(), inp)
                for j in eachindex(IndexCartesian(), nb)
                    nb[j] = get_bounded(BT, inp, i - center + j)
                end
                out[i] = f(nb)
            end
        end
    end
    # ~/~ end
    # ~/~ begin <<episodes/130-functional-techniques.md#ca>>[2]
    #| id: ca
    game_of_life(a) = let s = sum(a) - a[2, 2]
        s == 3 || (a[2, 2] && s == 2)
    end

    function tic(f, dt, running_)
        running::Observable{Bool} = running_

        @async begin
            while running[]
                sleep(dt)
                f()
            end
        end
    end

    function run_life()
        fig = Figure()

        sz = (64, 64)
        state = Observable(rand(Bool, sz...))
        temp = Array{Bool, 2}(undef, sz...)
        foo = stencil(game_of_life, Periodic{2}, (3, 3))

        function next()
            foo(state[], temp)
            state[], temp = temp, state[] # copy(temp)
        end

        ax = Axis(fig[1, 1], aspect=1)
        gb = GridLayout(fig[2, 1], tellwidth=false)

        playing = Observable(false)

        play_button_text = lift(p->(p ? "Pause" : "Play"), playing)
        play_button = gb[1,1] = Button(fig, label=play_button_text)
        rand_button = gb[1,2] = Button(fig, label="Randomize")

        on(play_button.clicks) do _
            p = !playing[]
            playing[] = p
            if p
                tic(next, 0.01, playing)
            end
        end

        on(rand_button.clicks) do _
            state[] = rand(Bool, sz...)
        end

        heatmap!(ax, state)

        fig
    end
    # ~/~ end
end
# ~/~ end
