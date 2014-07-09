#!/usr/bin/env th
require 'trepl'
require 'sys'
require 'pl'
require 'image'
require 'nnx'
require 'xlua'
local pixels = require 'pixels'
local rick = pixels.load('img/rick.jpg')
local gm = require 'graphicsmagick'
local col = require 'async.repl'.colorize
function h1(text) print(col._black(text)) end
function h2(text) print(col._red(text)) end
function h3(text) print(col._cyan(text)) end
local s = 512
local g = 16
local MADpixels = {
   test = {}
}

--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                              IMG shuffles ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
function MADpixels.globalShuffle(opt)
   local o = o or {}
   local h = o.h or s
   local w = o.w or s
   local i = o.i or rick
   local i1 = image.scale(i,h,w)[{{1,3}}]
   local i2 = i1:reshape(3, h*w):transpose(2,1)
   local idx = torch.randperm((#i2)[1])
   local i3 = i2:clone()
   for x = 1, (#i2)[1] do
      i3[x] = i2[idx[x]]
   end
   local i4 = i3:transpose(2,1):reshape(3,h,h)
   h1(
      [[
         _______________________
         MADpixels.globalShuffle
         =======================
      ]]
   )
   h2('Dimensions * i ')print(#i)
   h2('Dimensions * i2')print(#i2)
   h2('Dimensions * i3')print(#i3)
   h2('Dimensions * i4')print(#i4)
   return i4
end

function MADpixels.binedShuffle(opt)
   h1('MADpixels.binedShuffle')
   local opt  = opt or {}
   local img  = opt.img or rick
   local imgh = opt.imgh or s
   local imgw = opt.imgw or s

   local wBlocksNo   = opt.wBlocksNo or 16
   local hBlocksNo   = opt.hBlocksNo or 16
   local img         = image.scale(img,imgh,imgw)[{{1,3}}]
   local imgdims     = #img
   local blockw      = imgdims[3]/wBlocksNo
   local blockh      = imgdims[2]/hBlocksNo
   local imgHSL      = image.rgb2hsv(img)*0.99
   local blocks      = imgHSL:unfold(3,blockw,blockw):unfold(2,blockh,blockh)
   local allBlocks   = blocks:reshape((#blocks)[1],
                                   (#blocks)[2]*(#blocks)[3],
                                   (#blocks)[4]*(#blocks)[5])
   h1('Bins tensors Dimensions = ')
   print(imgw..'*'..imgh..'*'.. wBlocksNo..'*'..wBlocksNo..'*'..hBlocksNo)
   for i = 1, (#allBlocks)[2] do
      xlua.progress(i,(#allBlocks)[2])
      local rdmPositions = torch.randperm((#allBlocks)[3]) --Randomize Bins
      for j = 1, (#allBlocks)[3] do
         allBlocks[{ 1,i,j }] = allBlocks[{ 1,i,rdmPositions[j] }]
         allBlocks[{ 2,i,j }] = allBlocks[{ 2,i,rdmPositions[j] }]
         allBlocks[{ 3,i,j }] = allBlocks[{ 3,i,rdmPositions[j] }]
      end
   end
   img = allBlocks:reshape((#blocks)[1],
                           (#blocks)[2],
                           (#blocks)[3],
                           (#blocks)[4],
                           (#blocks)[5])
   print('Shuffle -> #img=',#img)
   img = image.hsv2rgb(img:transpose(3,4):reshape(3,imgh,imgw))
   print('Reorganize -> #img=',#img)
   return img
end

function MADpixels.localShuffle(opt)
   opt = opt or {}
   -- Potential Arguments
   local img = opt.img or rick
   img = img:clone()
   local maxSpread = math.max( (#img)[1], (#img)[2], (#img)[3])
   local meanMaxSpread = maxSpread/4
   local spread = opt.spread or meanMaxSpread
   -- Spread == 0?
   if spread == 0 then
       return img
   end
   -- Img Geometry
   local width = (#img)[3]
   local height = (#img)[2]
   local channels = (#img)[1]
   local npixels = width*height
   -- Fast & Furious Computation
   local raw = torch.data(img)
   local offsets_x = torch.data( torch.Tensor(npixels):normal(0, spread) )
   local offsets_y = torch.data( torch.Tensor(npixels):normal(0, spread) )
   local i = 0
   for y = 0,height-1 do
      for x = 0,width-1 do
         local dx = math.floor(0.5 + math.max(math.min(width-1,  x+offsets_x[i]), 0))
         local dy = math.floor(0.5 + math.max(math.min(height-1, y+offsets_y[i]), 0))
         local di = width*dy + dx
         for c = 0,channels-1 do
            local buffer = raw[ npixels*c + i ]
            raw[ npixels*c + i ] = raw[ npixels*c + di ]
            raw[ npixels*c + di ] = buffer
         end
         i = i + 1
      end
   end
   collectgarbage()
   return img
end

function MADpixels.binedColorShuffle(opt)
   local opt = opt or {}
   local img = opt.img or rick
   local imgh = opt.imgh or s h2('imgh') print(imgh)
   local imgw = opt.imgw or s h2('imgh') print(imgw)
   local imgc = opt.imgc or 3 h2('imgc') print(imgh)
   local imgb = opt.imgb or 32 h2('imgb')print(imgw) -- == 16 bins
   local img = image.scale(img,imgh,imgw)[{{1,3}}]
   local img = image.rgb2hsl(img)
   local img = img:reshape(3,imgh*imgw)
   local img = img:transpose(2,1)
   local colors = torch.Tensor(100,3)
   for i = 1, 100 do
      colors[{i}] = img[torch.random(1,imgh*imgw)]
   end
   local wBlocksNo = imgw / imgb
   local hBlocksNo = imgh / imgb
   local blockPixelsNo = imgb * imgb
   local totalBlocksNo = wBlocksNo * hBlocksNo
   local blocksHSL = torch.Tensor(totalBlocksNo,blockPixelsNo,imgc)
   for i = 1,(#blocksHSL)[1] do
      xlua.progress(i,(#blocksHSL)[1])
      local inHSL   = colors[math.floor(torch.uniform(1,(#colors)[1]+1))]
      local ssclaor = torch.uniform(1,1)
      local lscalor = torch.uniform(1,1)
      for j = 1,(#blocksHSL)[2] do
         blocksHSL[i][j][1] = 1
         blocksHSL[i][j][2] = torch.uniform(1,1.5)
         blocksHSL[i][j][3] = torch.uniform(0,1.5)
         blocksHSL[i][j]:cmul(inHSL)
      end
   end
   local img = blocksHSL:transpose(2,3)
                        :transpose(1,2)
                        :reshape(imgc,wBlocksNo,hBlocksNo,imgb,imgb)
                        :transpose(3,4)
                        :reshape(3,imgw,imgh)
   local img = image.hsl2rgb(img)
   return img
end


--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                             IMG transforms┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

function MADpixels.invert(opt)
   h1('Inverting image colors')
   local opt = opt or {}
   local img  = opt.img or rick
   return -img +1
end

function MADpixels.boost (opt)
   h1('Boosting image colors')
   local opt = opt or {}
   local imgSize = opt.imgSize or 512
   local img = opt.img or rick
   local i0, i1, i2, i3
   i0 = img
   i1 = i0:clone()
   i2 = i1:add(-i1:mean()) -- (0) normalize the image energy to be 0 mean:
   i3 = i2:div(i2:std())   -- (1) normalize all channels to have unit standard deviation:
                           -- (2) boost indivudal channels differently (here we give an orange
   --     boost, to warm up the image):
   i3[1]:mul(0.4)
   i3[2]:mul(0.3)
   i3[3]:mul(0.2)
   local pixels = torch.data(i3) -- (3) soft clip the image between 0 and 1
   for i = 0,i3:nElement()-1 do
      pixels[i] = math.min(1, math.max(0, (math.tanh(pixels[i]*4)+1)/2))
   end
   return i3
end

function MADpixels.apertureBlur(opt)
   -- options:
   local opt = opt or {}
   local apertureSize = opt.apertureSize or 32
   local imgsize = opt.imgsize or 512
   local img = opt.img or rick

   -- load aperture:
   local aperture = pixels.load('img/aperture.png', {maxSize = apertureSize})
   aperture:div(aperture:max())

   -- convolve
   return image.convolve(img,aperture[1],'same')
end

function MADpixels.gaussianFlou(opt)
   opt = opt or {}
   local imgsize = opt.imgsize or 512
   local img = opt.img or rick
   local kernelsize = opt.kernelsize or 100
   -- Gaussian Kernel + Transpose
   local g1 = image.gaussian1D(kernelsize):resize(1,kernelsize):float()
   local g2 = g1:t() --transpose(1,2)
   -- Check Dimensiosn
   print(#g1)
   print(#g2)
   -- Resize & Clone
   local i = image.scale(img, imgsize)
   c = i:clone():fill(1)
   print{c,g1}
   -- Convolution
   c = image.convolve(c, g1, 'same')
   c = image.convolve(c, g2, 'same')
   i = image.convolve(i, g1, 'same')
   i = image.convolve(i, g2, 'same')
   -- Component-wise division + retransform
   i:cdiv(c)
   return i
end

--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                              IMG creations┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


function MADpixels.dagrad(opt)
   local function R() return torch.random(0,255)/255 end
   local function G() return torch.random(0,255)/255 end
   local function B() return torch.random(0,255)/255 end
   opt = opt or {}
   local w = opt.w or s
   local h = opt.h or s

   local colors = {
      {R(),G(),B()},
      {R(),G(),B()},
      {R(),G(),B()},
      {R(),G(),B()},
   }
   local tl = opt.tl or colors[1]
   local tr = opt.tr or colors[2]
   local br = opt.br or colors[3]
   local bl = opt.bl or colors[4]

   local img = torch.FloatTensor({{tl,tr},{br,bl}})
   img = img:transpose(1,3)
   img = img:transpose(2,3)
   img = image.scale(img,w,h)
   return img
end

function MADpixels.ckograd()
   -- gradient
   local img = MADpixels.dagrad()

   -- load mask:
   local cko = pixels.load('img/cko.png')
   image.scale(cko, img:size(3), img:size(2))

   -- mul
   return img:cmul(cko)
end

function MADpixels.uniform(opt)
   opt = opt or {}
   local size = opt.size or 256
   local nb = opt.nb or  1000

   local t = torch.ByteTensor(3,size,size)

   dir.makepath('TX.uniform')

   for i = 1,nb do
      xlua.progress(i,nb)
      -- uniform colors
      t[1] = torch.uniform(0,255)
      t[2] = torch.uniform(0,255)
      t[3] = torch.uniform(0,255)

      -- force gray (statistically too low otherwise)
      if i % 20 == 0 then
         t[2] = t[1]
         t[3] = t[1]
      end

      -- save
      pixels.save('TX.uniform/'..t[1][1][1]..'-'..t[2][1][1]..'-'..t[3][1][1]..'.jpg', t)
   end
end

function MADpixels.gradient(opt)
   opt = opt or {}
   local size = opt.size or 256
   local nb = opt.nb or  1000
   dir.makepath('TX.gradient')
   local t = torch.ByteTensor(3,size,size)

   for i = 1,nb do
      xlua.progress(i,nb)
      -- uniform colors
      local colors = {}
      for a = 1,4 do
         colors[a] = {
            torch.uniform(0,255),
            torch.uniform(0,255),
            torch.uniform(0,255),
         }
      end

      -- generate 4 quadrants:
      local quadrants = torch.ByteTensor(colors):transpose(1,2):reshape(3,2,2)

      -- upscale:
      image.scale(t, quadrants)

      -- save
      pixels.save('TX.gradient/'..i..'.jpg', t)
   end
end


--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                            IMG collection ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

function MADpixels.mosaic(opt)
   local opt = opt or {}
   local directory = opt.directory or error('d MISSING')
   local params = opt.params
   local imgsize = opt.imgsize or 1024
   local padding = opt.padding or 0
   local files = fun.permute(dir.getfiles(directory, '*.jpg'))
   local name = path.basename(directory:gsub('%/$',''))
   local nfiles = #files

   -- Adiitionnal parameter
   local nw
   local nh
   local tile
   local width
   local height

   if params  then
      nw     = params.nw
      nh     = params.nh
      tile   = params.tile
      width  = params.width
      height = params.height
   else
      nw = math.floor(math.min(math.sqrt(nfiles),32))
      nh = nw
      tile = math.ceil(imgsize/nw)
      width = (tile+padding*2) * nw + padding * 2
      height = (tile+padding*2) * nh + padding * 2
   end
   local map = torch.FloatTensor(3, height, width):zero()
   local n = 1
   for i = 1,nh do
      xlua.progress(i,nh)
     for j = 1,nw do
       local file = files[n]
       if file then
         -- progx
         io.write(' '..n..'/'..nfiles..'\r') io.flush()

         -- load
         local img = gm.Image(file,tile):size(nil,tile):toTensor('float','RGB','DHW')

         -- crop
         local oh = math.floor( (img:size(2) - tile) / 2 )
         local ow = math.floor( (img:size(3) - tile) / 2 )
         img  = img[{ {},{1+oh,oh+tile},{1+ow,ow+tile} }]

         -- dest coords:
         local t = (i-1)*(tile+padding*2) + 1 + padding*2
         local l = (j-1)*(tile+padding*2) + 1 + padding*2
         local b = t+tile-1
         local r = l+tile-1

         -- insert:
         map[{ {},{t,b},{l,r} }] = img
       end
       n = n + 1
     end
   end
   return map
end

--┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
--┃                                                                           ┃
--┃                                                                           ┃
--┃                                                                           ┃
--┃                                                                           ┃
--┃                                                                           ┃
--┃                                                                           ┃
--┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

return MADpixels

