" clang_complete/OmniCppComplete initialization
if !exists('g:clang_exec')
  let g:clang_exec = 'clang'
endif

if !exists('g:has_clang')
  let g:has_clang = executable(g:clang_exec)
endif

if g:has_clang
  call clang_complete#Init()
else
  call omni#cpp#complete#Init()
endif
