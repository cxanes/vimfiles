" codeintel.vim
" Last Modified: 2009-03-05 11:12:31
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_codeintel')
  finish
endif

if !has('python')
  echohl ErrorMsg
  echom "codeintel: error: Required vim compiled with +python"
  echohl None
  finish
endif

if !exists("g:codeintel_dir")
  echohl ErrorMsg
  echom "codeintel: error: Please assign the full path of the library directory of codeintel to a variable named 'g:codeintel_dir'"
  echohl None
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
let s:import_error = 0
"}}}
" Python code {{{
py << PY_EOF
import vim
import os.path

sys.path.append(vim.eval('g:codeintel_dir'))
sys.path.append(os.path.join(vim.eval('g:codeintel_dir'), "python-sitelib"))

try:
  import codeintel2.manager
except ImportError, e:
  vim.command("let s:import_error = 1")
  vim.command('echohl ErrorMsg')
  vim.command("echom 'codeintel: error: Cannot find module codeintel2'")
  vim.command('echohl None')

PY_EOF

if s:import_error
  finish
endif

let loaded_codeintel = 1

py << PY_EOF
import sys
import os.path

import logging
logging.basicConfig()

_codeintel_buf = {}
_codeintel_instance = None
def VimCodeIntel(db_base_dir = None): #{{{
    global _codeintel_instance
    if _codeintel_instance is None:
        _codeintel_instance = _VimCodeIntel(db_base_dir)
    return _codeintel_instance

#}}}
class _VimCodeIntel: #{{{
    def __init__(self, db_base_dir = None):
        self.mgr = codeintel2.manager.Manager()
        self.mgr.upgrade()
        self.mgr.initialize()

        vim.command('au VimLeavePre * py VimCodeIntel().finalize()')

    def get_curr_pos(self): #{{{
        nl_cnt = vim.eval('&ff') == 'dos' and 2 or 1
        pos = 0
        for lnum in range(1, int(vim.eval("line('.')"))):
            pos += int(vim.eval("strlen(substitute(getline(%d), '.', 'x', 'g'))" % (lnum, ))) + nl_cnt
        pos += int(vim.eval("col('.') < 2 ? 0 : strlen(substitute(getline('.')[ : col('.')-2 ], '.', 'x', 'g'))"))
        return pos
    #}}}

    def finalize(self):
        self.mgr.finalize()
        _codeintel_instance = None

    def get_buf(self):
        lang = vim.eval('&ft')
        cpln_langs = self.mgr.get_cpln_langs()
        for l in cpln_langs:
            if l.lower() == lang.lower():
                lang = l
                break
        else:
            lang = None

        if not lang:
            return None

        path = vim.eval("expand('%:p')")
        encoding = "utf-8"

        if path:
            encoding = vim.eval('&fenc')
            if not encoding:
                encoding = "utf-8"
        else:
            vim.command(r'redir => b:_codeintel_sw | silent sw | redir END')
            path = vim.eval('substitute(b:_codeintel_sw, "\n", "", "g")')
            vim.command('unlet! b:_codeintel_sw')

        content = unicode(vim.eval(r'iconv(join(getline(1, "$"), "\n"), &enc, "utf-8")'), 'utf-8')
        buf = self.mgr.buf_from_content(content, lang, path = path, encoding = encoding)

        return buf


    def _get_trg(self, buf):
        pos = self.get_curr_pos()
        curr_pos = pos
        trg = buf.preceding_trg_from_pos(pos, curr_pos)

        return trg


    def get_cplns(self, buf = None):
        if buf is None:
            buf = self.get_buf()

        trg = self._get_trg(buf)
        if not trg:
            return ()

        return buf.cplns_from_trg(trg)

    def get_calltips(self, buf = None):
        if buf is None:
            buf = self.get_buf()

        trg = self._get_trg(buf)
        if not trg:
            return ()

        return buf.cplns_from_trg(trg)

#}}}
class CodeIntelComplete: #{{{
  @classmethod
  def get_trg_chars(cls, var_name):
    vim.command("let %s = ''" % (var_name, ))
    buf = cls.get_buf()
    if buf:
      vim.command("let %s = '%s'" 
                  % (var_name, ''.join(buf.langintel.trg_chars).replace("'", "''"), ))

  @classmethod
  def get_buf(cls):
    global _codeintel_buf
    bufnr = vim.eval("bufnr('%')")
    if bufnr not in _codeintel_buf:
      _codeintel_buf[bufnr] = VimCodeIntel().get_buf()
    return _codeintel_buf[bufnr]

  @classmethod
  def get_cplns(cls, var_name):
    vim.command('let %s = []' % (var_name, ))
    buf = cls.get_buf()
    if buf is None:
      return

    def to_vimstr(str):
      return "'%s'" % (str.replace("'", "''"), )

    cplns = VimCodeIntel().get_cplns()
    if cplns:
      for (type, word) in cplns:
        vim.command("call add(%s, [%s, %s])" % (var_name, to_vimstr(type), to_vimstr(word)))

#}}}
PY_EOF
"}}}
function! codeintel#Complete(findstart, base) "{{{
  if a:findstart
    let b:start = -1
    py CodeIntelComplete.get_trg_chars('trg_chars')

    if empty(trg_chars)
      return b:start
    endif

    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && stridx(trg_chars, line[start - 1]) == -1
      let start -= 1
    endwhile
    if start > 0
      let b:start = start
    endif
    return b:start
  else
    if b:start == -1
      return []
    endif

    py CodeIntelComplete.get_cplns('cplns')
    if empty(cplns)
      return []
    endif

    let res = []
    let pattern = '^\V' . escape(a:base, '\') 
    for [type, word] in cplns
      if word =~ pattern
        let item = { 'word': word, 'kind': strlen(type) ? type[0] : ' ' }
        call add(res, item)
      endif
    endfor
    return res
  endif
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
