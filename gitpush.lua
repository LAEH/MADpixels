#!/usr/bin/env th

local command = {
   'sudo rm -rf testMADpixels/',
   'git add -A',
   'git commit -a -m "Better"',
   'git pull',
   'git push',
}

for i, c in ipairs(command) do
   os.execute(c)
end
