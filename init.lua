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
local MADpixels = require 'MADpixels.MADpixels'

--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                                     TESTS ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

local dirout = 'TEMP.test/'
os.execute('mkdir -p '..dirout)
local functions = {
   shuffles = {
      'binedColorShuffle',
      'globalShuffle',
      'binedShuffle',
      'localShuffle',
   },
   transforms = {
      'invert',
      'boost',
      'apertureBlur',
      'gaussianFlou',
   },
   creations = {
      'dagrad',
      'ckograd',
      'uniform',
      'gradient',
   }
}


-- for _,group in ipairs(functions) do
--    for _,fun in ipairs(group) do
--       local i = MADpixels[fun](rick)
--       local f = dirout .. fun .. '.jpg'
--       pixels.save(f,i)
--       collectgarbage()
--    end
-- end

--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                                      RUNS ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


local files = dir.getfiles('mosaics/', '*.jpg')
print(files)
for i,file in ipairs(files) do
   local img = pixels.load(file)
   local name = path.basename(file)
   local shuffled = MADpixels['globalShuffle'](img)
   local file = 'mosaicsshuffled/'..name
   pixels.save(file,shuffled)
   xlua.progress(i,#files)
   collectgarbage()
end


