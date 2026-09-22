-- ~/.config/yazi/init.lua

-- Full border around panes (matches kitty split borders)
require("full-border"):setup {
	type = ui.Border.ROUNDED,
}

-- Git status signs in the file list
require("git"):setup {
	order = 1500,
}
