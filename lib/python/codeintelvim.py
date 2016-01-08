"""codeintelvim: a vim mode for using codeintel library"""
import vim
import os.path
import sys
import tempfile

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
    import codeintel2.environment
except ImportError:
    raise RuntimeError('Cannot find module codeintel2')

import logging
_logfile = os.path.join(tempfile.gettempdir(), "codeintelvim.log")
logging.basicConfig(filename = _logfile)

_instance = None

# create augroup
vim.command('augroup codeintel')
vim.command('augroup END')
vim.command('au! codeintel')

def _finalize():
    global _instance
    if _instance is not None:
        _instance.finalize()
        _instance = None


def CodeIntelVim(db_base_dir = None):
    global _instance
    if _instance is None:
        _instance = _VimCodeIntel(db_base_dir)
        vim.command('au codeintel VimLeavePre * py codeintelvim._finalize()')
    elif db_base_dir is not None:
        _instance.finalize()
        _instance = _VimCodeIntel(db_base_dir)

    return _instance


def _get_curr_pos():
    nl_cnt = vim.eval('&ff') == 'dos' and 2 or 1
    pos = 0
    # consider multibyte characters
    for lnum in range(1, int(vim.eval("line('.')"))):
        pos += int(vim.eval("strlen(substitute(getline(%d), '.', 'x', 'g'))" % (lnum, ))) + nl_cnt
    pos += int(vim.eval("col('.') < 2 ? 0 : strlen(substitute(getline('.')[: col('.')-2], '.', 'x', 'g'))"))
    return pos


def _get_bufnr(bufnr = None):
    if bufnr is None:
        bufnr = int(vim.eval("bufnr('%')"))
    else:
        if not isinstance(bufnr, int):
            return None

        if not int(vim.eval('bufexists(%d)' % (bufnr, ))):
            return None

    return bufnr


def _vimstr(s):
    return "'%s'" % (str(s).replace("'", "''"), )

class _Environment(codeintel2.environment.SimplePrefsEnvironment):
    """Our own environment
    """
    _default_prefs = {
        "codeintel_selected_catalogs": ["pywin32", "cpan"],
        "codeintel_max_recursive_dir_depth": 10,
    }

    def __init__(self):
        codeintel2.environment.SimplePrefsEnvironment.__init__(self, **self._default_prefs)


class _VimCodeIntel:
    def __init__(self, db_base_dir = None):
        self.mgr = codeintel2.manager.Manager(db_base_dir, env = _Environment())
        self.mgr.upgrade()
        self.mgr.initialize()


    def finalize(self):
        self.mgr.finalize()


    def scan_buf(self, buf, priority = PRIORITY_IMMEDIATE, force = False):
        self.mgr.idxr.add_request(codeintel2.indexer.ScanRequest(buf, priority, force))
        try:
            scan_time, scan_error, blob_from_lang = self.mgr.db.get_buf_data(buf)
            if scan_error:
                vim.command('echohl WarningMsg')
                vim.command("let g:codeintel_errmsg = %s . ': ' . %s" % (_vimstr(buf), _vimstr(scan_error)))
                vim.command("echom 'codeintel: ' . g:codeintel_errmsg")
                vim.command('echohl None')
        except (NotFoundInDatabase, DatabaseError):
            pass


    def buf_from_path(self, path):
        buf = self.mgr.buf_from_path(path)
        if not self.mgr.is_cpln_lang(buf.lang):
            return None
        return buf


    def buf_from_vimbuf(self, bufnr = None):
        bufnr = _get_bufnr(bufnr)
        getvar = lambda var: vim.eval("getbufvar(%d, '%s')" % (bufnr, var))

        lang = getvar('&ft')
        cpln_langs = self.mgr.get_cpln_langs()

        for cpln_lang in cpln_langs:
            if cpln_lang.lower() == lang.lower():
                lang = cpln_lang
                break
        else:
            return None

        # Cannot be special buffer
        buftype = getvar('&bt')
        if buftype:
            return None

        path = vim.eval("fnamemodify(bufname(%d), ':p')" % (bufnr, ))
        encoding = "utf-8"

        if path:
            encoding = getvar('&enc')
        else:
            if not int(vim.eval(getvar('&swapfile'))):
                return None

            vim.command(r'redir => g:_codeintel_swapname | silent sw | redir END')
            path = vim.eval('substitute(g:_codeintel_swapname, "\n", "", "g")')
            vim.command('unlet! g:_codeintel_swapname')

        content = unicode(
                vim.eval(r'iconv(join(getbufline(%d, 1, "$"), "\n"), &enc, "utf-8")' % (bufnr, )), 'utf-8')
        buf = self.mgr.buf_from_content(content, lang, path = path, encoding = encoding)

        return buf


    def _get_trg(self, buf):
        curr_pos = pos = _get_curr_pos()
        trg = buf.preceding_trg_from_pos(pos, curr_pos)

        return trg


    def get_cplns(self, buf):
        trg = self._get_trg(buf)
        if not trg:
            return ()

        return buf.cplns_from_trg(trg)

    def get_calltips(self, buf):
        trg = self._get_trg(buf)
        if not trg:
            return ()

        return buf.calltips_from_trg(trg)


def scan_vimbufs():
    for bufnr in range(1, int(vim.eval('bufnr("$")')) + 1):
        scan_vimbuf(bufnr, PRIORITY_BACKGROUND)


def scan_vimbuf(bufnr = None, priority = PRIORITY_IMMEDIATE):
    bufnr = _get_bufnr(bufnr)
    instance = CodeIntelVim()
    if int(vim.eval('buflisted({0}) && empty(getbufvar({0}, "&bt"))'.format(bufnr))):
        buf = instance.buf_from_vimbuf(bufnr)
        if buf:
            instance.scan_buf(buf, priority)


def get_trg_chars(var_name):
    vim.command("let %s = ''" % (var_name, ))
    buf = get_buf()
    if buf:
        vim.command("let %s = %s" 
                % (var_name, _vimstr(''.join(buf.langintel.trg_chars)), ))

def get_buf(bufnr = None, rescan = True):
    bufnr = _get_bufnr()
    if not bufnr:
        return None

    buf = CodeIntelVim().buf_from_vimbuf(bufnr)
    if buf and rescan:
        CodeIntelVim().scan_buf(buf)

    return buf


def get_cplns(var_name):
    vim.command('let %s = []' % (var_name, ))
    buf = get_buf()
    if buf is None:
        return

    cplns = CodeIntelVim().get_cplns(buf)
    if cplns:
        for (type, word) in cplns:
            vim.command("call add(%s, [%s, %s])" 
                    % (var_name, _vimstr(type), _vimstr(word)))

def get_calltips(var_name):
    vim.command('let %s = ""' % (var_name, ))
    buf = get_buf()
    if buf is None:
        return

    calltips = CodeIntelVim().get_calltips(buf)
    if calltips:
        vim.command('let %s = %s' % (var_name, _vimstr(('-' * 30).join(calltips))))


