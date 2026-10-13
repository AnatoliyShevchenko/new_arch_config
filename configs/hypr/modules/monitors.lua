hl.monitor({
    output   = "HDMI-A-2",
    mode     = "3840x2160@60",
    position = "auto-left",
    scale    = "1.25",
 --    bitdepth = 10,
	-- cm = "hdr",
	-- sdrbrightness = 20,
	-- sdrsaturation = 1,
	-- disabled = true
})
hl.monitor({
    output    = "DP-1",
    mode      = "1920x1080@144",
    position  = "auto",
    scale     = "1",
    transform = 1,  -- 90 deg clockwise (portrait). Use 3 for 90 deg counter-clockwise.
	-- disabled = true
})
