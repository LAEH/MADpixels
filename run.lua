#!/usr/bin/env th
require 'sys'
require 'xlua'
require('pl.text').format_operator()
local testIMGdirectory = 'img/'
local gm = require 'graphicsmagick'
local col = require 'async.repl'.colorize
local pixels = require 'pixels'
local MADpixels = require './MADpixels' -- load local version
local run = {}

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

-- print(MADpixels.available)
function run.test()
   local dirout = 'results/'
   print('saving file @'..col.yellow(dirout))
   os.execute('mkdir -p '..dirout)
   for _,group in ipairs(MADpixels.available) do
      print(group)
      for _,fun in ipairs(group) do
         local i = MADpixels[fun](rick)
         local f = dirout .. fun .. '.jpg'
         print(f)
         pixels.save(f,i)
         -- collectgarbage()
      end
   end
end
--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                               RUN EXEMPLE ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

function run.globalShuffle()
   local time = os.time()
   local files = dir.getfiles(testIMGdirectory, '*.jpg')
   local dirout = 'resultsrun'..time..'/'
   os.execute('mkdir -p '..dirout)
   for i,file in ipairs(files) do
      local name = path.basename(file)
      print(col.green(name),col.yellow(name))
      local img = pixels.load(file)
      local shuffled = MADpixels['globalShuffle'](img)
      local file = dirout..name
      pixels.save(file,shuffled)
      collectgarbage()
   end
end

run.globalShuffle()

