"""codeintelvim: a vim mode for using codeintel library"""
import vim
import os.path
import sys

if not int(vim.eval('exists("g:codeintel_dir")')):
    raise RuntimeError("Please assign the full path of the lib dir of codeintel to a var named 'g:codeintel_dir'")

try:
    sys.path.append(vim.eval('g:codeintel_dir'))
    sys.path.append(os.path.join(vim.eval('g:codeintel_dir'), "python-sitelib"))
except Exception, e:
    raise RuntimeError(e)

try:
    from codeintel2.common import *
    import codeintel2.manager
    import codeintel2.indexer
except ImportError:
    raise RuntimeError('Cannot find module codeintel2')

import logging
logging.basicConfig()

_bufs = {}
_instance = None

def CodeIntelVim(db_base_dir = None):
    global _instance
    if _instance is None:
        _instance = _VimCodeIntel(db_base_dir)
    return _instance

class _VimCodeIntel:
    def __init__(self, db_base_dir = None):
        self.mgr = codeintel2.manager.Manager()
        self.mgr.upgrade()
        self.mgr.initialize()

        vim.command('au VimLeavePre * py codeintelvim.CodeIntelVim().finalize()')

    def get_curr_pos(self):
        nl_cnt = vim.eval('&ff') == 'dos' and 2 or 1
        pos = 0
        for lnum in range(1, int(vim.eval("line('.')"))):
            pos += int(vim.eval("strlen(substitute(getline(%d), '.', 'x', 'g'))" % (lnum, ))) + nl_cnt
        pos += int(vim.eval("col('.') < 2 ? 0 : strlen(substitute(getline('.')[ : col('.')-2 ], '.', 'x', 'g'))"))
        return pos

    def finalize(self):
        self.mgr.finalize()
        _instance = None

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

        return buf.calltips_from_trg(trg)


def update_bufs():
    global _bufs
    instance = CodeIntelVim()
    for buf in _bufs.itervalues():
        instance.mgr.idxr.add_request(codeintel2.indexer.ScanRequest(buf, PRIORITY_BACKGROUND))


def _to_vimstr(str):
    return "'%s'" % (str.replace("'", "''"), )


def get_trg_chars(var_name):
    vim.command("let %s = ''" % (var_name, ))
    buf = get_buf()
    if buf:
        vim.command("let %s = %s" 
                % (var_name, _to_vimstr(''.join(buf.langintel.trg_chars)), ))

def get_buf():
    global _bufs
    bufnr = vim.eval("bufnr('%')")
    buf = CodeIntelVim().get_buf()
    _bufs[bufnr] = buf
    CodeIntelVim().mgr.idxr.add_request(codeintel2.indexer.ScanRequest(buf, PRIORITY_IMMEDIATE))
    return buf

def get_cplns(var_name):
    vim.command('let %s = []' % (var_name, ))
    buf = get_buf()
    if buf is None:
        return

    cplns = CodeIntelVim().get_cplns()
    if cplns:
        for (type, word) in cplns:
            vim.command("call add(%s, [%s, %s])" 
                    % (var_name, _to_vimstr(type), _to_vimstr(word)))

def get_calltips(var_name):
    vim.command('let %s = ""' % (var_name, ))
    buf = get_buf()
    if buf is None:
        return

    calltips = CodeIntelVim().get_calltips()
    if calltips:
        vim.command('let %s = %s' % (var_name, _to_vimstr(('-' * 30).join(calltips))))


