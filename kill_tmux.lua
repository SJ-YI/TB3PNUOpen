#!/usr/bin/env luajit
local ok = pcall(dofile,'../fiddle.lua')
if not ok then dofile'fiddle.lua' end

require'os'
os.execute'tmux kill-session'
