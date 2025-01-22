module Plotter

using ColorSchemes
using Images
using ImageIO

struct BoundingBox
    limits::NTuple{2,NTuple{2,Float64}}
    size::NTuple{2,Int}
end

xaxis(bb::BoundingBox) = LinRange(bb.limits[1]..., bb.size[1]+1)
yaxis(bb::BoundingBox) = LinRange(bb.limits[2]..., bb.size[2]+1)

function scalar_image(raw::AbstractMatrix{F}, scale, clip, cmap, reversed=false) where {F <: Real}
    rescale(a, b) = v -> (v - a) / (b - a)
    clip_unit(v) = v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v)
    to_range(l) = v -> let n = Int(floor(v * l)) + 1
        n > l ? l : n
    end
    cs = reversed ? reverse(colorschemes[cmap]) : colorschemes[cmap]
    csi = get(cs, range(0.0, 1.0, 256))
    v = scale.(raw)
    n = v .|> rescale(extrema(v)...) .|> rescale(clip...) .|> clip_unit
    csi[n .|> to_range(256)]
end

module Bifurcation
using ..Plotter: BoundingBox, xaxis, yaxis, scalar_image
using ColorSchemes
using GLMakie

function plot_column!(column, r, ylims, n_skip, n_take)
    column .= 0
    p = 0.5
    for _ in 1:n_skip
        p = r * p * (1 - p)
    end

    for _ in 1:n_take
        p = r * p * (1 - p)
        y = (p - ylims[1]) / (ylims[2] - ylims[1]) * length(column) + 0.5
        yn = Int(floor(y))
        yf = y - floor(y)

        if yn >= 1 && yn <= length(column)
            column[yn] += (1.0 - yf)
        end

        if yn >= 0 && yn <= length(column)-1
            column[yn+1] += yf
        end
    end
end

function plot_image!(result, column, limits, rs, n_skip, n_take)
    xlims, ylims = limits
    sz = size(result)
    for r in rs
        x = (r - xlims[1]) / (xlims[2] - xlims[1]) * sz[1] + 0.5
        xn = Int(floor(x))
        xf = x - floor(x)
    
        plot_column!(column, r, ylims, n_skip, n_take)

        if xn >= 1 && xn <= sz[1]
            @views result[xn, :] .+= (1.0 - xf) .* column
        end
        if xn >= 0 && xn <= sz[1]-1
            @views result[xn+1, :] .+= xf .* column
        end
    end
end

function plot_image(bb::BoundingBox, rnum, n_skip, n_take)
    result = zeros(Float64, bb.size...)
    column = zeros(Float64, bb.size[2])
    plot_image!(result, column, bb.limits, LinRange(bb.limits[1]..., rnum), n_skip, n_take)
    result
end

function plot_image!(bb::BoundingBox, result, rnum, n_skip, n_take)
    column = zeros(Float64, bb.size[2])
    plot_image!(result, column, bb.limits, LinRange(bb.limits[1]..., rnum), n_skip, n_take)
    result
end

function explorer()
    limits = Observable(((2.6, 4.0), (0.0, 1.0)))
    bb = lift(l->BoundingBox(l, (3840, 2160)), limits)
    img = Observable(plot_image(bb[], 5*10^4, 1000, 10^4))
    xax = lift(xaxis, bb)
    yax = lift(yaxis, bb)

    fig = Figure()
    slx = IntervalSlider(fig[2, 1], range=xax)
    sly = IntervalSlider(fig[1, 2], range=yax, horizontal=false)

    sg = SliderGrid(fig[3,1],
        (label = "log10(#skip)", range = 0.0:0.1:5,  format = "{:.1f}", startvalue = 3.0),
        (label = "log10(#points)", range = 3:0.1:5, format = "{:.1f}", startvalue = 4.0),
        (label = "contrast", range = 0.01:0.01:4, startvalue=1.0),
    )

    clip_slider = IntervalSlider(fig[4, 1], range=0.0:0.01:1.0)

    butgrid = GridLayout(fig[5, 1], tellwidth=false)
    button = butgrid[1, 1] = Button(fig, label="replot")
    show_range = butgrid[1, 2] = Checkbox(fig, checked=false)
    Label(butgrid[1,3], "show selection")

    # palette_entry = Menu(butgrid[2, 1], options=colsel, width=300)
    rev_pallete_cb = Checkbox(butgrid[2, 2], checked=false)
    Label(butgrid[2, 3], "reverse")
    palette_tb = Textbox(butgrid[2, 1], width=300, stored_string="viridis", validator=s->Symbol(s) ∈ keys(colorschemes))

    filename_entry = Textbox(butgrid[3, 2], width=300, stored_string="bifurcation.png")
    save_button = butgrid[3, 1] = Button(fig, label="save")

    skip_obs = sg.sliders[1].value
    take_obs = sg.sliders[2].value
    contrast_obs = sg.sliders[3].value

    on(button.clicks) do _
        limits[] = (slx.interval[], sly.interval[])
        println("Recomputing: ", bb)
        n_take = Int(round(10^(take_obs[])))
        n_skip = Int(round(10^(skip_obs[])))
        newimg = plot_image(bb[], 5*10^4, n_skip, n_take)
        img[] = newimg
    end

    ax = Makie.Axis(fig[1, 1], limits=limits)
    logimg = lift(img, contrast_obs, clip_slider.interval, palette_tb.stored_string, rev_pallete_cb.checked) do img, c, clip, pal, rev
        scalar_image(img, x->log10(x+c), clip, Symbol(pal), rev)
    end
    image!(ax, xax, yax, logimg)
    pts = lift(slx.interval, sly.interval) do (x1, x2), (y1, y2)
        Point2f[(x1, y1), (x2, y1), (x2, y2), (x1, y2)]
    end
    poly!(pts, alpha=0.3, color=:red, visible=show_range.checked)

    on(save_button.clicks) do _
        save(filename_entry.stored_string[], logimg[][:,end:-1:1]')
    end

    fig
end

end # module Bifurcation

end # module Plotter
