#!/usr/bin/env th


--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                                 MADpixels ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

--           _____                    _____                    _____
--          /\    \                  /\    \                  /\    \
--         /::\____\                /::\    \                /::\    \
--        /::::|   |               /::::\    \              /::::\    \
--       /:::::|   |              /::::::\    \            /::::::\    \
--      /::::::|   |             /:::/\:::\    \          /:::/\:::\    \
--     /:::/|::|   |            /:::/__\:::\    \        /:::/  \:::\    \
--    /:::/ |::|   |           /::::\   \:::\    \      /:::/    \:::\    \
--   /:::/  |::|___|______    /::::::\   \:::\    \    /:::/    / \:::\    \
--  /:::/   |::::::::\    \  /:::/\:::\   \:::\    \  /:::/    /   \:::\ ___\
-- /:::/    |:::::::::\____\/:::/  \:::\   \:::\____\/:::/____/     \:::|    |
-- \::/    / ~~~~~/:::/    /\::/    \:::\  /:::/    /\:::\    \     /:::|____|
--  \/____/      /:::/    /  \/____/ \:::\/:::/    /  \:::\    \   /:::/    /
--              /:::/    /            \::::::/    /    \:::\    \ /:::/    /
--             /:::/    /              \::::/    /      \:::\    /:::/    /
--            /:::/    /               /:::/    /        \:::\  /:::/    /
--           /:::/    /               /:::/    /          \:::\/:::/    /
--          /:::/    /               /:::/    /            \::::::/    /
--         /:::/    /               /:::/    /              \::::/    /
--         \::/    /                \::/    /                \::/____/
--          \/____/                  \/____/                  ~~


--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                  Dependancy & Definitions ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

require 'sys'
require 'xlua'
require('pl.text').format_operator()
local gm = require 'graphicsmagick'
local col = require 'async.repl'.colorize
local pixels = require 'pixels'
local MADpixels = require 'MADpixels'

--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                                     TESTS ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

local dirout = 'TEMP.test/'
os.execute('mkdir '..dirout)
local functions = {
   shuffles = {
      'binedColorShuffle',
      'globalShuffle',
      'binedShuffle',
      'localShuffle',
   }
   transforms = {
      'invert',
      'boost',
      'apertureBlur',
      'gaussianFlou',
   }
   creations = {
      'dagrad',
      'ckograd',
      'uniform',
      'gradient',
   }
}


-- for _,fun in ipairs(MADpixelsFunctions) do
--    local i = MADpixels[fun](rick)
--    local f = dirout .. fun .. '.jpg'
--    h1(f)
--    pixels.save(f,i)
--    collectgarbage()
-- end

-- MADpixels.noise()
-- MADpixels.gradient()
