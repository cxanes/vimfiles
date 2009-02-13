" File: table.vim
" Author: Frank Chang (frank.nevermind AT gmail.com)
" Version: 0.1
" Last Modified: 2008-02-26 11:19:21
"
" Emulate the function of table.el <http://table.sourceforge.net/>
"
" **UNFINISHED**
"
" Use it at your own risks.

" imap <silent> <buffer> <Leader>tb <C-R>=<SID>TableInsertI()<CR>
command! TableInsert      call <SID>TableInsertN()
command! -range TableRecognize   call <SID>TableRecognize(<line1>, <line2>)
command! TableUnrecognize call <SID>TableUnrecognize()

function! s:TableRecognize(top, bottom) "{{{
  let left = strlen(matchstr(getline(a:top), '^.\{-}\%(+-\+\)\@='))
  let start = [a:top - 1, left]
  call TableSetKeys(join(getline(a:top, a:bottom), "\n"), start)
endfunction
"}}}
function! s:TableUnrecognize() "{{{
  call TableUnsetKeys()
endfunction
"}}}
" CreateTable(): Generate a table. {{{1
function! CreateTable(...) "{{{
  let [cols, rows, width, height] = s:ParseArg(a:000)
  if cols <= 0 || rows <= 0
    return ''
  endif
  let hrule = '+' . repeat(repeat('-', width) . '+', cols)
  let vrule = '|' . repeat(repeat(' ', width) . '|', cols)
  let table = hrule . repeat(repeat("\<CR>" . vrule, height) . "\<CR>" . hrule, rows)
  return table
endfunction
"}}}
function! s:ParseArg(args) "{{{
  " default = [cols, rows, width, height]
  let default = [3, 3, 5, 1]

  if empty(a:args)
    return default
  elseif type(a:args[0]) == type([])
    return s:ParseArg(a:args[0])
  elseif type(a:args[0]) == type({})
    let args = a:args[0]
    return [ get(args, 'cols',   default[0]), 
          \  get(args, 'rows',   default[1]),
          \  get(args, 'width',  default[2]),
          \  get(args, 'height', default[3])]
  endif

  let len = len(a:args)
  for i in range(4)
    if i < len && type(a:args[i]) == type(0)
      let default[i] = a:args[i]
    endif
  endfor

  return default
endfunction
"}}}
"}}}1
function! s:GetSettings() "{{{
  let default = [3, 3, 5, 1]
  " settings: [cols, rows, width, height]
  let settings = copy(default)
  call inputsave()
  let settings[0] = input("Number of columns: ", default[0]) + 0
  let settings[1] = input("Number of rows: "   , default[1]) + 0
  let settings[2] = input("Cell width(s): "    , default[2]) + 0
  let settings[3] = input("Cell height(s): "   , default[3]) + 0
  call inputrestore()
  for i in range(len(settings))
    if settings[i] <= 0
      let settings[i] = default[i]
    endif
  endfor
  return settings
endfunction
"}}}
function! s:TableInsertN() "{{{
  let settings = s:GetSettings()
  let table = call('CreateTable', settings)
  if table == ''
    return
  endif
  let lines = split(table, "\<CR>")
  let [lnum, col] = [line('.'), col('.')]
  let indent = s:Indent(col - 1)
  for i in range(len(lines))
    if lnum > line('$') 
      call append(lnum-1, indent . lines[i])
    else
      let line = getline(lnum)
      let strlen = strlen(line)
      if col - 1 <= 0
        call setline(lnum, lines[i] . line)
      elseif strlen(line) <= col - 1
        let fmt = '%-' . (col-1) . 's'
        call setline(lnum, printf(fmt, line) . lines[i])
      else
        call setline(lnum, getline(lnum)[ : col-2] . lines[i] . getline(lnum)[col-1 : ])
      endif
    endif
    let lnum += 1
  endfor
endfunction
"}}}"}}}
function! s:TableInsertI() "{{{
  let settings = s:GetSettings()
  let table = call('CreateTable', settings)
  let indent = s:Indent(col('.') - 1)
  if indent != ''
    let table = join(split(table, "\<CR>"), "\<CR>" . indent)
  endif
  let move_right = repeat("\<Left>", (settings[2] + 1) * settings[0])
  let move_up    = repeat("\<Up>",   (settings[3] + 1) * settings[1] - 1)
  return table . move_right . move_up
endfunction
"}}}
" {{{ Indent(text)
function! s:Indent(number) "{{{
  if &expandtab
    return repeat(' ', a:number)
  else
    return repeat("\t", a:number/&shiftwidth) . repeat(' ', a:number%&shiftwidth) 
  endif
endfunction
"}}}
" Global Functions {{{1
function! Parse(parser, block)
  return a:parser.Parse(a:block)
endfunction
function! WhichCurrentCell(parser)
  return WhichCell(a:parser, line('.'), col('.'))
endfunction
function! WhichCell(parser, lnum, col)
  return a:parser.WhichCell(a:lnum, a:col)
endfunction
function! ExpandCurrentCell(parser, direction)
  call a:parser.ExpandCell(line('.'), col('.'), a:direction)
endfunction
function! ShrinkCurrentCell(parser, direction)
  call a:parser.ShrinkCell(line('.'), col('.'), a:direction)
endfunction
"}}}1
let s:NULL = [[[]]]
" Class: TableParser "{{{1
" Modified from docutils-0.4/docutils/parsers/rst/tableparser.py
" <http://docutils.sourceforge.net/>
"
" Parse a grid table using `parse()`.
" 
" Here's an example of a grid table::
" 
"     +------------------------+------------+----------+----------+
"     | row 1, column 1        | column 2   | column 3 | column 4 |
"     +------------------------+------------+----------+----------+
"     | row 2                  | Cells may span columns.          |
"     +------------------------+------------+---------------------+
"     | row 3                  | Cells may  | - Table cells       |
"     +------------------------+ span rows. | - contain           |
"     | row 4                  |            | - body elements.    |
"     +------------------------+------------+---------------------+
" 
" Intersections use '+', row separators use '-', and column separators use '|'.
" 
" Passing the above table to the `parse()` method will result in the
" following data structure::
" 
"     ([24, 12, 10, 10],
"      [[(0, 0, 1, ['row 1, column 1']),
"        (0, 0, 1, ['column 2']),
"        (0, 0, 1, ['column 3']),
"        (0, 0, 1, ['column 4'])],
"       [(0, 0, 3, ['row 2']),
"        (0, 2, 3, ['Cells may span columns.']),
"        None,
"        None],
"       [(0, 0, 5, ['row 3']),
"        (1, 0, 5, ['Cells may', 'span rows.', '']),
"        (1, 1, 5, ['- Table cells', '- contain', '- body elements.']),
"        None],
"       [(0, 0, 7, ['row 4']), None, None, None]])
" 
" The first item is a list containing column widths (colspecs). The second item
" is a list of rows. Each row contains a list of cells. Each cell is either
" None (for a cell unused because of another cell's span), or a tuple. A cell
" tuple contains four items: the number of extra rows used by the cell in a
" vertical span (morerows); the number of extra columns used by the cell in a
" horizontal span (morecols); the line offset of the first line of the cell
" contents; and the cell contents, a list of lines of text.
" Public  Method: Ctor {{{2
function! NewTableParser()
  let self = {
        \ 'Parse'     : function('TableParser_Parse'),
        \ 'Setup'     : function('s:TableParser_Setup'),
        \ 'ParseTable': function('TableParser_ParseTable'),
        \ 'MarkDone'  : function('s:TableParser_MarkDone'),
        \ 'CheckParseComplete': function('s:TableParser_CheckParseComplete'),
        \ 'ScanCell'  : function('s:TableParser_ScanCell'),
        \ 'ScanRight' : function('s:TableParser_ScanRight'),
        \ 'ScanDown'  : function('s:TableParser_ScanDown'),
        \ 'ScanLeft'  : function('s:TableParser_ScanLeft'),
        \ 'ScanUp'    : function('s:TableParser_ScanUp'),
        \ 'StructureFromCells': function('s:TableParser_StructureFromCells'),
        \ 'WhichCell' : function('TableParser_WhichCell'),
        \ 'ExpandCell': function('TableParser_ExpandCell'),
        \ 'ShrinkCell': function('TableParser_ShrinkCell'),
        \ }
  return self
endfunction
"}}}2
" Public  Method: Parse {{{2
function! TableParser_Parse(block, ...) dict
  if a:0 > 0
    call self.ParseTable(b:block, a:1)
  else
    call self.ParseTable(a:block)
  endif
  let structure = self.StructureFromCells()
  return structure
endfunction
"}}}2
" Public  Method: ParseTable {{{2
" Start with a queue of upper-left corners, containing the upper-left
" corner of the table itself. Trace out one rectangular cell, remember
" it, and add its upper-right and lower-left corners to the queue of
" potential upper-left corners of further cells. Process the queue in
" top-to-bottom order, keeping track of how much of each text column has
" been seen.
"
" We'll end up knowing all the row and column boundaries, cell positions
" and their dimensions.
function! TableParser_ParseTable(block, ...) dict
  if a:0 > 0
    call self.Setup(a:block, a:1)
  else
    call self.Setup(a:block)
  endif
  let corners = [[0, 0]]
  while !empty(corners)
    let [top, left] = remove(corners, 0)
    if top == self.bottom || left == self.right 
          \ || top <= self.done[left]
      continue
    endif
    let result = self.ScanCell(top, left)
    if s:IsNull(result)
      continue
    endif
    let [bottom, right, rowseps, colseps] = result
    call s:UpdateDictOfLists(self.rowseps, rowseps)
    call s:UpdateDictOfLists(self.colseps, colseps)
    call self.MarkDone(top, left, bottom, right)
    let cellblock = s:Get2DBlock(self.block, top + 1, left + 1, bottom - 1, right - 1)
    call add(self.cells, [top, left, bottom, right, cellblock])
    call extend(corners, [[top, right], [bottom, left]])
    call Sort(corners)
  endwhile
  if !self.CheckParseComplete()
    throw 'TableMarkupError: Malformed table; parse incomplete.'
  endif
endfunction
"}}}2
" Public  Method: WhichCell {{{2
function! TableParser_WhichCell(lnum, col) dict
  let rowseps = keys(self.rowseps)  " list of row boundaries
  call Sort(rowseps)
  let rowindex = {}
  for i in range(len(rowseps))
    let rowindex[rowseps[i]] = i    " row boundary -> row number mapping
  endfor
  let colseps = keys(self.colseps)  " list of column boundaries
  call Sort(colseps)
  let colindex = {}
  for i in range(len(colseps))
    let colindex[colseps[i]] = i    " column boundary -> col number map
  endfor
  let [lnum, col] = [a:lnum-1-self.start[0], a:col-1-self.start[1]]
  for cell in self.cells
    let [top, left, bottom, right, block] = cell
    if top < lnum && lnum <= bottom
          \ && left < col && col <= right
      return [[rowindex[top], colindex[left]], 
            \ [top+self.start[0], left+self.start[1], 
            \  bottom+self.start[0], right+self.start[1], block]]
    endif
  endfor
  return [[-1, -1], s:NULL]
endfunction
"}}}2
" Public  Method: ExpandCell {{{2
function! TableParser_ExpandCell(lnum, col, direction, ...) dict
  if a:direction == 0
    return
  endif
  let [index, cell] = self.WhichCell(a:lnum, a:col)
  if s:IsNull(cell)
    return
  endif
  let [bottom, right] = cell[2:3]

  if a:direction > 0 " horizontally
    let sep = repeat('-', a:direction)
    let space = repeat(' ', a:direction)
    let col = right
    let lnum = 1 + self.start[0]
    call setline(lnum, getline(1)[ : col-1] . sep . getline(1)[col : ])
    let lnum += 1
    while lnum < self.bottom + 1
      let [index, cell] = self.WhichCell(lnum, col-1)
      let [bottom, right] = cell[2:3]
      for i in range(lnum, bottom)
        call setline(i, getline(i)[ : right-1] . space . getline(i)[right : ])
      endfor
      let lnum = bottom + 1
      call setline(lnum, getline(lnum)[ : col-1] . sep . getline(lnum)[col : ])
      let lnum += 1
    endwhile

    call self.ParseTable(join(getline(1 + self.start[0], 
          \ self.bottom + 1 + self.start[0]), "\n"), self.start)
  else  " vertically
    let lnum = bottom
    let exp = ''
    let line = getline(lnum) 
    let len = strlen(line)
    for i in range(len)
      let exp .= line[i] =~ '[+|]' ? '|' : ' '
    endfor
    let pos = getpos('.')
    let exp = repeat(exp . "\n", -a:direction)
    exe lnum . 'put =exp'

    if a:0 == 0 || empty(a:1)
      let col = 2 + self.start[1]
      while col < self.right + 1 + self.start[1]
        let [index2, cell] = self.WhichCell(lnum, col)
        let [top, left, bottom, right, block] = cell
        let col = right + 2
        if a:0 > 0 && empty(a:1) && index2 == index 
          continue
        endif
        if bottom > lnum
          for j in range(lnum+1, bottom)
            call setline(j, getline(j)[ : left] . getline(j-a:direction)[left+1 : right-1] . getline(j)[right : ])
          endfor
          for j in range(bottom + 1, bottom - a:direction)
            call setline(j, getline(j)[ : left] . repeat(' ', right-left-1) . getline(j)[right : ])
          endfor
        endif
      endwhile
    endif
    call setpos('.', pos)

    call self.ParseTable(join(getline(1+self.start[0], 
          \ self.bottom-a:direction+1+self.start[0]), "\n"), self.start)
  endif
endfunction
"}}}2
" Public  Method: ShrinkCell {{{2
function! TableParser_ShrinkCell(lnum, col, direction) dict
  if a:direction == 0
    return
  endif
  let [index, cell] = self.WhichCell(a:lnum, a:col)
  if s:IsNull(cell)
    return
  endif
  let [bottom, right] = cell[2:3]
  if a:direction > 0 " horizontally
    let col = right
    let lnum = 2 + self.start[0]
    let minsep = self.right + 1 + self.start[1]
    while lnum < self.bottom + 1 + self.start[0]
      let [index, cell] = self.WhichCell(lnum, col-1)
      let [bottom, right] = cell[2:3]
      for i in range(lnum, bottom)
        let minsep = min([strlen(matchstr(getline(i)[ : right-1], '\s*$')), minsep])
        if minsep == 0
          return
        endif
      endfor
      let lnum = bottom + 2
    endwhile

    let lnum = 1 + self.start[0]
    let minsep = min([a:direction, minsep])
    call setline(lnum, getline(lnum)[ : col-minsep-1] . getline(lnum)[col : ])
    let lnum += 1
    while lnum < self.bottom + 1 + self.start[0]
      let [index, cell] = self.WhichCell(lnum, col-1)
      let [bottom, right] = cell[2:3]
      for i in range(lnum, bottom)
        call setline(i, getline(i)[ : right-minsep-1] . getline(i)[right : ])
      endfor
      let lnum = bottom + 1
      call setline(lnum, getline(lnum)[ : col-minsep-1] . getline(lnum)[col : ])
      let lnum += 1
    endwhile

    call self.ParseTable(join(getline(1+self.start[0], 
          \ self.bottom+1+self.start[0]), "\n"), self.start)
  else  " vertically
    let lnum = bottom
    let col = 2 + self.start[1]
    let minsep = self.bottom + 1 + self.start[0]
    while col < self.right + 1 + self.start[1]
      let [index, cell] = self.WhichCell(lnum, col)
      let [top, left, bottom, right, block] = cell
      let tlnum = bottom > lnum ? bottom : lnum
      let sep = 0
      while getline(tlnum)[left+1 : right-1] =~ '^\s*$'
        let sep += 1
        let tlnum -= 1
      endwhile
      let col = right + 2
      let minsep = min([sep, minsep])
    endwhile

    let minsep = min([minsep, -a:direction])
    if minsep == 0
      return 
    endif

    let col = 2 + self.start[1]
    while col < self.right + 1
      let [index, cell] = self.WhichCell(lnum, col)
      let [top, left, bottom, right, block] = cell
      if bottom > lnum
        for j in range(bottom, lnum, -1)
          call setline(j, getline(j)[ : left] . getline(j-minsep)[left+1 : right-1] . getline(j)[right : ])
        endfor
      endif
      let col = right + 2
    endwhile
    let pos = getpos('.')
    exec 'silent ' . (lnum - minsep + 1) . ',' . lnum . 'd _'
    call setpos('.', pos)
    call self.ParseTable(join(getline(1+self.start[0], 
          \ self.bottom+1+self.start[0]), "\n"), self.start)
  endif
endfunction
"}}}2
" Private Method: Setup {{{2
function! s:TableParser_Setup(block, ...) dict
  if ! s:IsValid(a:block)
    throw 'TableMarkupError: Malformed table.'
  endif
  let block = split(substitute(a:block, '^\%(\s*\n\)\+\|\%(\n\s*\)\+$', '', 'g'), "\n")
  call map(block, 'substitute(v:val, ''^\s\+\|\s\+$'', "", "g")')
  let self.block  = block
  let self.bottom = len(block) - 1
  let self.right  = strlen(block[0]) - 1
  let self.done   = repeat([-1], strlen(block[0]))
  let self.cells  = []
  let self.rowseps = {0: [0]}
  let self.colseps = {0: [0]}
  let self.start   = a:0 > 0 ? a:1 : [0, 0]
endfunction
"}}}2
" Private Method: MarkDone {{{2
" For keeping track of how much of each text column has been seen.
function! s:TableParser_MarkDone(top, left, bottom, right) dict
  let before = a:top - 1
  let after = a:bottom - 1
  for col in range(a:left, a:right - 1)
    call s:Assert(self.done[col] == before)
    let self.done[col] = after
  endfor
endfunction
"}}}2
" Private Method: CheckParseComplete {{{2
" Each text column should have been completely seen.
function! s:TableParser_CheckParseComplete() dict
  let last = self.bottom - 1
  for col in range(self.right)
    if self.done[col] != last
      return 0
    endif
  endfor
  return 1
endfunction
"}}}2
" Private Method: ScanCell {{{2
" Starting at the top-left corner, start tracing out a cell.
function! s:TableParser_ScanCell(top, left) dict
  call s:Assert(self.block[a:top][a:left] == '+')
  let result = self.ScanRight(a:top, a:left)
  return result
endfunction
"}}}
" Private Method: ScanRight {{{2
" Look for the top-right corner of the cell, and make note of all column
" boundaries ('+').
function! s:TableParser_ScanRight(top, left) dict
  let colseps = {}
  let line = self.block[a:top]
  for i in range(a:left + 1, self.right)
    if line[i] == '+'
      let colseps[i] = [a:top]
      let result = self.ScanDown(a:top, a:left, i)
      if !s:IsNull(result)
        let [bottom, rowseps, newcolseps] = result
        call s:UpdateDictOfLists(colseps, newcolseps)
        return [bottom, i, rowseps, colseps]
      endif
    elseif line[i] != '-'
      return s:NULL
    endif
  endfor
  return s:NULL
endfunction
"}}}2
" Private Method: ScanDown {{{2
" Look for the bottom-right corner of the cell, making note of all row
" boundaries.
function! s:TableParser_ScanDown(top, left, right) dict
  let rowseps = {}
  for i in range(a:top + 1, self.bottom)
    if self.block[i][a:right] == '+'
      let rowseps[i] = [a:right]
      let result = self.ScanLeft(a:top, a:left, i, a:right)
      if !s:IsNull(result)
        let [newrowseps, colseps] = result
        call s:UpdateDictOfLists(rowseps, newrowseps)
        return [i, rowseps, colseps]
      endif
    elseif self.block[i][a:right] != '|'
      return s:NULL
    endif
  endfor
  return s:NULL
endfunction
"}}}2
" Private Method: ScanLeft {{{2
" Noting column boundaries, look for the bottom-left corner of the cell.
" It must line up with the starting point.
function! s:TableParser_ScanLeft(top, left, bottom, right) dict
  let colseps = {}
  let line = self.block[a:bottom]
  for i in range(a:right - 1, a:left + 1, -1)
    if line[i] == '+'
      let colseps[i] = [a:bottom]
    elseif line[i] != '-'
      return s:NULL
    endif
  endfor
  if line[a:left] != '+'
    return s:NULL
  endif
  let result = self.ScanUp(a:top, a:left, a:bottom, a:right)
  if !s:IsNull(result)
    let rowseps = result
    return [rowseps, colseps]
  endif
  return s:NULL
endfunction
"}}}2
" Private Method: ScanUp {{{2
" Noting row boundaries, see if we can return to the starting point.
function! s:TableParser_ScanUp(top, left, bottom, right) dict
  let rowseps = {}
  for i in range(a:bottom - 1, a:top + 1, -1)
    if self.block[i][a:left] == '+'
      let rowseps[i] = [a:left]
    elseif self.block[i][a:left] != '|'
      return s:NULL
    endif
  endfor
  return rowseps
endfunction
"}}}2
" Private Method: StructureFromCells {{{2
" From the data collected by `scan_cell()`, convert to the final data
" structure.
function! s:TableParser_StructureFromCells() dict
  let rowseps = keys(self.rowseps)  " list of row boundaries
  call Sort(rowseps)
  let rowindex = {}
  for i in range(len(rowseps))
    let rowindex[rowseps[i]] = i    " row boundary -> row number mapping
  endfor
  let colseps = keys(self.colseps)  " list of column boundaries
  call Sort(colseps)
  let colindex = {}
  for i in range(len(colseps))
    let colindex[colseps[i]] = i    " column boundary -> col number map
  endfor
  let colspecs = [] " list of column widths
  for i in range(1, len(colseps) - 1)
    call add(colspecs, colseps[i] - colseps[i - 1] - 1)
  endfor
  " prepare an empty table with the correct number of rows & columns
  let onerow = []
  for i in range(len(colseps) - 1)
    call add(onerow, s:NULL)
  endfor
  let rows = []
  for i in range(len(rowseps) - 1)
    call add(rows, copy(onerow))
  endfor
  " keep track of # of cells remaining; should reduce to zero
  let remaining = (len(rowseps) - 1) * (len(colseps) - 1)
  for [top, left, bottom, right, block] in self.cells
    let rownum = rowindex[top]
    let colnum = colindex[left]
    call s:Assert(s:IsNull(rows[rownum][colnum]), 
          \ printf('Cell (row %s, column %s) already used.', rownum + 1, colnum + 1))
    let morerows = rowindex[bottom] - rownum - 1
    let morecols = colindex[right] - colnum - 1
    let remaining -= (morerows + 1) * (morecols + 1)
    " write the cell into the table
    let rows[rownum][colnum] = [morerows, morecols, top + 1, block]
  endfor
  call s:Assert(remaining == 0, 'Unused cells remaining.')
  return [colspecs, rows]
endfunction
"}}}2
" Utilities {{{2
function! s:IsNull(val) "{{{
  return a:val is s:NULL
  " return type(a:val) == type([]) && len(a:val) == 1
  "       \ && type(a:val[0]) == type([]) && len(a:val[0]) == 1
  "       \ && type(a:val[0][0]) == type([]) && len(a:val[0][0]) == 0
endfunction
"}}}
function! s:IsValid(table) "{{{
  let lines = split(a:table, "\n")
  if len(lines) < 2
    return 0
  endif

  call map(lines, 'substitute(v:val, ''\s\+$'', "", "g")')
  let hrule_pat = '^\s*+[-+]\++$'
  if lines[0] !~ hrule_pat || lines[len(lines)-1] !~ hrule_pat
    return 0
  endif

  let pre_space_len = strlen(matchstr(lines[0], '^\s*'))
  let len = strlen(lines[0])

  for line in lines
    if len != strlen(line)
      return 0
    elseif pre_space_len != strlen(matchstr(line, '^\s*'))
      return 0
    elseif line[pre_space_len] !~ '[|+]'
      return 0
    elseif line[strlen(line)-1] !~ '[|+]'
      return 0
    endif
  endfor

  return 1
endfunction
"}}}
function! s:Get2DBlock(block, top, left, bottom, right) "{{{
  let block = []
  for i in range(a:top, a:bottom)
    call add(block, substitute(a:block[i][a:left : a:right], '\s\+$', '', 'g'))
  endfor
  return block
endfunction
"}}}
function! s:Assert(test, ...) "{{{
  if !a:test
    if a:0 > 0
      throw 'Assert: ' . a:1
    else
      throw 'Assert.'
    endif
  endif
endfunction
"}}}
" UpdateDictOfLists() {{{
" Extend the list values of `master` with those from `newdata`.
" Both parameters must be dictionaries containing list values.
function! s:UpdateDictOfLists(master, newdata)
  for [key, values] in items(a:newdata)
    if !has_key(a:master, key)
      let a:master[key] = []
    endif
    call extend(a:master[key], values)
  endfor
endfunction
"}}}
function! Sort(list) "{{{
  call sort(a:list, "Compare")
  return a:list
endfunction

" Compare(): compared with number
function! Compare(v1, v2)
  if type(a:v1) != type([]) && type(a:v1) != type([]) 
    let [v1, v2] = [a:v1+0, a:v2+0]
    return v1 == v2 ? 0 : v1 > v2 ? 1 : -1
  else
    for i in range(len(a:v1))
      if i >= len(a:v2)
        return 1
      elseif (a:v1[i]+0) == (a:v2[i]+0)
        continue
      endif
      return a:v1[i] > a:v2[i] ? 1 : -1
    endfor
    return i < len(a:v2) ? -1 : 0
  endif
endfunction
"}}}
"}}}
"}}}2
"}}}1

" Insert Keys: (ASCII) from ' ' (32) to '~' (126) {{{
let s:InsKey = map(range(32, 126), 'nr2char(v:val)')
"}}}
function! TableSetKeys(block, ...) "{{{
  let s:parser = NewTableParser()
  try
    if a:0 > 0
      call s:parser.ParseTable(a:block, a:1)
    else
      call s:parser.ParseTable(a:block)
    endif
  catch
    echohl ErrorMsg | echo v:exception | echohl None
    unlet s:parser
    return ''
  endtry

  let b:InsMapSave = {}
  let cmd = 'inoremap <silent> <buffer> %s <C-\><C-O>:call <SID>Insert("%s")<CR>'
  for ch in s:InsKey
    let ch = ch == ' ' ? '<Space>' : ch == '|' ? '<Bar>' : ch
    if maparg(ch, 'i') != ''
      let b:InsMapSave[ch] = maparg(ch, 'i')
    endif
    exec printf(cmd, ch, escape(ch, '"\'))
  endfor
  exec printf(cmd, '<CR>', '\n')
  exec printf(cmd, '<BS>', '\<lt>BS>')
endfunction
"}}}
function! TableUnsetKeys() "{{{
  if !exists('s:parser')
    return
  endif
  unlet s:parser
  let cmd = 'silent! iunmap <buffer> %s'
  for ch in s:InsKey
    let ch = ch == ' ' ? '<Space>' : ch == '|' ? '<Bar>' : ch
    exec printf(cmd, ch)
  endfor
  exec printf(cmd, '<BS>')
  exec printf(cmd, '<CR>')

  if exists('b:InsMapSave')
    for [key, sav_map] in items(b:InsMapSave)
      if sav_map =~? '^\s*\%(\<[bwtglsav]:\|<[sS][iI][dD]>\)[#a-zA-Z0-9_.]\+\s*('
        let sav_map = '<expr> ' . sav_map
      endif
      exec 'silent! inoremap <silent> <buffer> ' . key . ' ' . sav_map
    endfor
    unlet b:InsMapSave
  endif
endfunction
"}}}
let g:TableFixedWidth = 1
function! s:SplitLine(line, width) "{{{
  let line = a:line
  let width = a:width + 0 <= 0 ? 1 : a:width
  let block = []
  if line =~ '^\s*$'
    call add(block, line)
  else
    while strlen(line) > width
      call add(block, line[ : width - 1])
      let line = line[width : ]
    endwhile
    call add(block, line)
  endif
  return block
endfunction
"}}}
function! s:GetNewBlock(cell, lnum, col, text, fixedWidth) "{{{
  let [top, left, bottom, right, block] = a:cell
  let [posy, posx] = [a:lnum - top - 2, a:col - left - 2]
  if posy >= len(block)
    call extend(block, repeat([''], posy - len(block) + 1))
  endif
  if posx >= strlen(block[posy])
    let block[posy] .= repeat(' ', posx - strlen(block[posy]) + 1)
  endif

  let width0 = right - left  - 1
  let isDelete = a:text == "\<BS>"
  if isDelete
    if posx > 0
      let block[posy] = (posx > 1 ? block[posy][ : posx-2] : '') . block[posy][posx :]
    elseif posy > 0
      let block[posy-1] = block[posy-1] . block[posy]
      call remove(block, posy)
    endif
  else
    let line = (posx > 0 ? block[posy][ : posx-1] : '')
          \ . a:text . block[posy][posx :]
    let block = (posy > 0 ? block[ : posy-1] : []) 
          \ + (line == "\n" ? [''] : split(line, "\n", 1)) + block[posy+1 : ]
  endif

  let width = isDelete || a:fixedWidth
        \ ? width0 
        \ : max(map(copy(block), 'strlen(v:val)'))

  let new_block = []
  let line = !empty(block) ? block[0] : ''
  for i in range(1, len(block))
    if i == len(block)
      call extend(new_block, s:SplitLine(line, width))
    elseif strlen(line) > width0 && line =~ '\S$' && block[i] =~ '^\S'
      let line .= block[i]
    else
      call extend(new_block, s:SplitLine(line, width))
      let line = block[i]
    endif
  endfor
      
  while len(new_block) > 0 && new_block[-1] == ''
    call remove(new_block, -1)
  endwhile

  return [width, new_block]
endfunction
"}}}
function! s:Insert(ch) "{{{
  if !exists('s:parser')
    exec 'normal! s' . a:ch . "\<Right>"
    return 
  endif

  let [lnum, col] = [line('.'), col('.')]
  call s:parser.ParseTable(join(getline(1+s:parser.start[0], 
        \ s:parser.bottom+1+s:parser.start[0]), "\n"), s:parser.start)
  let [index, cell] = s:parser.WhichCell(lnum, col)
  if s:IsNull(cell)
    exec 'normal! s' . a:ch . "\<Right>"
    return
  endif

  let [top, left, bottom, right, block] = cell
  let [height, width] = [bottom - top - 1, right - left - 1]
  let [new_width, new_block] = s:GetNewBlock(cell, lnum, col, a:ch, g:TableFixedWidth)

  let new_height = len(new_block)
  " echom string(new_block)
  if new_height > height
    call s:parser.ExpandCell(lnum, col, -1 * (new_height - height))
  endif

  if new_width > width
    call s:parser.ExpandCell(lnum, col, (new_width - width))
  endif

  let [index, cell] = s:parser.WhichCell(lnum, col)
  let [top, left, bottom, right, block] = cell
  let width = right - left - 1
  let fmt = '%' . (-1 * width) . 's'
  for i in range(top+2, bottom)
    let line = printf(fmt, !empty(new_block) ? remove(new_block, 0) : '')
    call setline(i, getline(i)[ : left] . line . getline(i)[right : ])
  endfor

  if col >= right && a:ch != "\<BS>"
    exec 'normal! ' . (right-left-2 <= 0 ? '' : (right-left-2 . 'h')) . 'j'
  elseif a:ch == "\n"
    exec 'normal! ' . (col-left-2 <= 0 ? '' : (col-left-2 . 'h')) . 'j'
  elseif a:ch == "\<BS>"
    if col <= left + 2
      exec 'normal! ' . (right-left-1 <= 0 ? '' : (right-left-1 . 'l')) . 'k'
    else
      normal! h
    endif
  else
    normal! l
  endif
endfunction
"}}}
" vim: fdm=marker :
