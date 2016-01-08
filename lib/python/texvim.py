import texoutline
import vim

def _get_indent(points, shiftwidth):
    section_order = { 'part'        : 0, 'chapter'      : 1, 'section'  : 2, 
                      'subsection'  : 3, 'subsubsection': 4, 'paragraph': 5, 
                      'subparagraph': 6 }
    sections = set()
    for point in points:
        sections.add(point[2])

    i = shiftwidth
    indent = {}
    for section in sorted(sections, lambda x, y: cmp(section_order[x], section_order[y])):
        indent[section] = i
        i += shiftwidth

    return indent

outlines = {}

def _curbufnr():
    return vim.eval("bufnr('')")

def reload():
    curbufnr = _curbufnr()
    if curbufnr not in outlines:
        return

    curline = vim.eval(r"substitute(getline('.'), '^\s\+', '', '')")
    outlines[curbufnr].create_outline()
    vim.command('silent normal 1G')
    vim.command(r"silent call search('^\s*\V' . escape('%s', '\'))" 
                % (curline.replace("'", "''"), ))

def goto(split = False, focus = True):
    curbufnr = _curbufnr()
    if curbufnr not in outlines:
        return
    
    curwin = vim.eval('winnr()')

    outline = outlines[curbufnr]
    curlnum = int(vim.eval("line('.')"))

    if curlnum == 1:
        filename = vim.current.buffer[0]
        lnum = 0
    else:
        point = outline.points[curlnum-2]
        filename = point[0]
        lnum = point[1]

    vim.command('winc p')
    filename = "escape('%s', '\"|%%# ')" % (filename.replace("'", "''"), )
    if split:
        vim.command("exe 'sp' " + filename)
    else:
        vim.command("exe (has('gui') ? 'dr' : 'hid e') " + filename)

    if not focus:
        vim.command("exe '%swinc w'" % (curwin, ))
    else:
        if lnum:
            vim.command('sil normal! %dG' % (lnum, ))

class Outline:
    def __init__(self, filename, shiftwidth = 2, win_width = 30):
        if isinstance(filename, type(vim.current.buffer)):
            self.filename = filename.name
        else:
            self.filename = filename

        self.shiftwidth = shiftwidth
        self.win_width  = win_width

    def create_outline(self):
        self.points = self._get_points()
        indent = _get_indent(self.points, self.shiftwidth)
        b = vim.current.buffer
        vim.command('setl ma')
        del b[:]
        b[0] = self.filename
        for point in self.points:
            b.append((' ' * indent[point[2]]) + point[3])
        vim.command('setl noma')

    def show(self):
        self.create_window()
        self.create_outline()

    def _get_points(self):
        return texoutline.outline_points(self.filename)

    def create_window(self):
        bufname = '__tex_toc__'
        vim.command("sil exe CreateTempBuffer('%s', 'vert to %d') . 'winc w'" 
                        % (bufname, self.win_width))
        curbufnr = _curbufnr()
        if curbufnr not in outlines:
            vim.command(("setl nowrap sw=%d nonu cul fdm=expr " +
                        "fde='>'.indent(v:lnum)/&sw " +
                        "fdt=getline(v:foldstart) fdc=2 fml=2 noma") % (self.shiftwidth, ))

            vim.command("nnoremap <buffer> <silent> o      :<C-U>py texvim.goto()<CR>")
            vim.command("nnoremap <buffer> <silent> go     :<C-U>py texvim.goto(focus=False)<CR>")
            vim.command("nnoremap <buffer> <silent> <Tab>  :<C-U>py texvim.goto(True)<CR>")
            vim.command("nnoremap <buffer> <silent> g<Tab> :<C-U>py texvim.goto(True, False)<CR>")

            vim.command(r"nnoremap <buffer> <silent> zj " + 
                        r":<C-U>call cursor(line('.'), 1)<Bar>" + 
                        r"call search(printf('^%s\S', repeat(' ', indent('.'))), 'W')<Bar>" + 
                        r"if v:count1 > 1<Bar>echom v:count1<Bar>call feedkeys((v:count1-1) . 'zj')<Bar>en<CR>")

            vim.command(r"nnoremap <buffer> <silent> zk " + 
                        r":<C-U>call cursor(line('.'), 1)<Bar>" + 
                        r"call search(printf('^%s\S', repeat(' ', indent('.'))), 'bW')<Bar>" + 
                        r"if v:count1 > 1<Bar>echom v:count1<Bar>call feedkeys((v:count1-1) . 'zk')<Bar>en<CR>")

            vim.command("nmap <buffer> <silent> <CR>  o")
            vim.command("nmap <buffer> <silent> g<CR> go")
            vim.command("nmap <buffer> <silent> <2-LeftMouse> o")

            vim.command("nnoremap <buffer> <silent> r :<C-U>py texvim.reload()<CR>")

            vim.command("syn match texTocFilename '\\%1l.*$'")

            for i in range(1, 8):
                vim.command("syn match texTocLevel%d '%s\S\+.*$'" % (i, ' ' * self.shiftwidth * i))

            vim.command("hi def link texTocFilename Constant")

            vim.command("hi def link texTocLevel1 Keyword")
            vim.command("hi def link texTocLevel2 String")
            vim.command("hi def link texTocLevel3 Function")
            vim.command("hi def link texTocLevel4 Comment")
            vim.command("hi def link texTocLevel5 Keyword")
            vim.command("hi def link texTocLevel6 String")
            vim.command("hi def link texTocLevel7 Function")

            outlines[curbufnr] = self

