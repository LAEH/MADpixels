#!/usr/bin/env th
require 'sys'
require 'xlua'
require('pl.text').format_operator()
local gm = require 'graphicsmagick'
local col = require 'async.repl'.colorize
local pixels = require 'pixels'
local MADpixels = require './MADpixels' -- load local version

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
--┃                                                                     TESTS ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

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

function test()
   local dirout = 'TEMP.test/'
   os.execute('mkdir -p '..dirout)
   for _,group in ipairs(functions) do
      for _,fun in ipairs(group) do
         local i = MADpixels[fun](rick)
         local f = dirout .. fun .. '.jpg'
         pixels.save(f,i)
         collectgarbage()
      end
   end
end

--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                                      RUNS ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

function ckoiaGrlobalShuffle()
   local time = os.time()
   local files = dir.getfiles('digilux/', '*.JPG')
   local dirout = 'run'..time..'/'
   os.execute('mkdir -p '..dirout)
   for i,file in ipairs(files) do
      local img = pixels.load(file)
      local name = path.basename(file)
      print(col.yellow(name))
      local shuffled = MADpixels['globalShuffle'](img)
      local file = dirout..name
      pixels.save(file,shuffled)
      -- xlua.progress(i,#files)
      collectgarbage()
   end
end

ckoiaGrlobalShuffle()
