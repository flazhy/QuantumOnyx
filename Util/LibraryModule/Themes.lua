return {
    Themes = {
        Purple = {
            Body = Color3.fromRGB(10, 10, 10),
            Primary = Color3.fromRGB(5, 5, 5),
            Lit = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 90)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(90, 40, 130)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 160)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 100, 190)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 140, 200))
            },
            TextColor = Color3.fromRGB(255, 255, 255),
            SubTextColor = Color3.fromRGB(200, 200, 200),
            ButtonGradient = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
            },
            Accent = Color3.fromRGB(192, 132, 252),
            AccentDark = Color3.fromRGB(139, 92, 246),
            AccentLight = Color3.fromRGB(216, 180, 254),
            HeaderBtn = Color3.fromRGB(160, 100, 240),
            DisplayName = "Purple",
            PreviewColors = {Color3.fromRGB(190, 20, 255), Color3.fromRGB(139, 92, 246), Color3.fromRGB(60, 20, 90)}
        },
        Crimson = {
            Body = Color3.fromRGB(10, 8, 8),
            Primary = Color3.fromRGB(6, 4, 4),
            Lit = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 10, 30)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(180, 20, 50)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 50, 80)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(220, 80, 60)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 120, 80))
            },
            TextColor = Color3.fromRGB(255, 255, 255),
            SubTextColor = Color3.fromRGB(255, 200, 200),
            ButtonGradient = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 40, 80)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 10, 40))
            },
            Accent = Color3.fromRGB(252, 100, 132),
            AccentDark = Color3.fromRGB(180, 40, 80),
            AccentLight = Color3.fromRGB(255, 160, 180),
            HeaderBtn = Color3.fromRGB(220, 60, 100),
            DisplayName = "Crimson",
            PreviewColors = {Color3.fromRGB(220, 40, 80), Color3.fromRGB(180, 40, 80), Color3.fromRGB(120, 10, 30)}
        },
        Ocean = {
            Body = Color3.fromRGB(6, 10, 14),
            Primary = Color3.fromRGB(4, 8, 12),
            Lit = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 60, 100)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(20, 100, 150)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 150, 180)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 180, 200)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 220, 230))
            },
            TextColor = Color3.fromRGB(220, 245, 255),
            SubTextColor = Color3.fromRGB(180, 230, 255),
            ButtonGradient = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 160, 220)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 80, 160))
            },
            Accent = Color3.fromRGB(80, 200, 240),
            AccentDark = Color3.fromRGB(30, 130, 200),
            AccentLight = Color3.fromRGB(140, 230, 255),
            HeaderBtn = Color3.fromRGB(40, 170, 220),
            DisplayName = "Ocean",
            PreviewColors = {Color3.fromRGB(30, 160, 220), Color3.fromRGB(30, 130, 200), Color3.fromRGB(10, 60, 100)}
        },
        Emerald = {
            Body = Color3.fromRGB(6, 11, 8),
            Primary = Color3.fromRGB(4, 8, 5),
            Lit = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 80, 40)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(20, 130, 70)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 170, 100)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 200, 120)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 230, 150))
            },
            TextColor = Color3.fromRGB(220, 255, 230),
            SubTextColor = Color3.fromRGB(180, 240, 200),
            ButtonGradient = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 190, 100)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 110, 55))
            },
            Accent = Color3.fromRGB(80, 220, 130),
            AccentDark = Color3.fromRGB(30, 160, 85),
            AccentLight = Color3.fromRGB(140, 245, 180),
            HeaderBtn = Color3.fromRGB(50, 190, 110),
            DisplayName = "Emerald",
            PreviewColors = {Color3.fromRGB(40, 190, 100), Color3.fromRGB(30, 160, 85), Color3.fromRGB(10, 80, 40)}
        },
        Sunset = {
            Body = Color3.fromRGB(12, 9, 6),
            Primary = Color3.fromRGB(8, 6, 4),
            Lit = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 50, 10)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(200, 90, 20)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 140, 30)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(240, 180, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 80))
            },
            TextColor = Color3.fromRGB(255, 245, 220),
            SubTextColor = Color3.fromRGB(255, 220, 170),
            ButtonGradient = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 140, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 60, 10))
            },
            Accent = Color3.fromRGB(252, 180, 80),
            AccentDark = Color3.fromRGB(200, 110, 30),
            AccentLight = Color3.fromRGB(255, 220, 140),
            HeaderBtn = Color3.fromRGB(230, 150, 40),
            DisplayName = "Sunset",
            PreviewColors = {Color3.fromRGB(240, 140, 30), Color3.fromRGB(200, 110, 30), Color3.fromRGB(140, 50, 10)}
        },
    },
    Current = nil,
    _listeners = {}
}
