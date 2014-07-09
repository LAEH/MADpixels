package = "MADpixels"
version = "scm-1"

source = {
   url = "git://github.com/LAEH/MADpixels",
   branch = "master"
}

description = {
   summary = "MADpixels",
   detailed = [[
      pixels Text Developement Context
   ]],
   homepage = "https://github.com/LAEH/MADpixels",
   license = "BSD"
}

dependencies = {
}

build = {
   type = "builtin",
   modules = {
      ['MADpixels.init'] = 'init.lua',
      ['MADpixels.gitpush'] = 'gitpush.lua',
      ['MADpixels.mapixels'] = 'MADpixels.lua',
   }
}
