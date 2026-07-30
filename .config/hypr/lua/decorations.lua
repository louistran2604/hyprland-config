local colors = require("lua.wallust.colors")

hl.config({
    general = { border_size = 2, gaps_in = 2, gaps_out = 4,
        col = { active_border = colors.color12, inactive_border = colors.color10 } },
    decoration = { rounding = 10, active_opacity = 1.0, inactive_opacity = 0.975, fullscreen_opacity = 1.0,
        dim_inactive = true, dim_strength = 0.025, dim_special = 0.8,
        shadow = { enabled = true, range = 3, render_power = 1, color = colors.color12, color_inactive = colors.color10 },
        blur = { enabled = true, size = 6, passes = 3, new_optimizations = true, xray = true,
            ignore_opacity = true, special = true, popups = true } },
    group = { col = { border_active = colors.color15 }, groupbar = { col = { active = colors.color0 } } },
})
