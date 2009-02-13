" Account.vim
" Last Modified: 2008-09-10 13:41:20
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_PIM_Account_plugin')
  finish
endif
let loaded_PIM_Account_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" ==========================================================
" Constant variables {{{
" ----------------------------------------------------------
let s:CATEGORY_SEP = '|'
let s:SUB_CATEGORY_DELIMITER = '.'
let s:DATE_DELIMITER = '/'
let s:EXPENSE_FIELD_WIDTH = 6
let s:DATE_PAT = '\%(\V' . join(['\d\{4}', '\d\{2}', '\d\{2}'], escape(s:DATE_DELIMITER, '\')) . '\m\)' 
let s:WEEKDAY = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
" }}}
" ==========================================================
" Global Utilities {{{
" ----------------------------------------------------------
function! PIM#Account#Open(file, ...) " ... = new_tab, category_file {{{
  exec (a:0 > 0 && a:1 ? 'tabe' : 'e') a:file
  call s:AccountInit(a:0 > 1 ? a:2 : '')
endfunction
"}}}
function! PIM#Account#Sum(date, ...) " ... = category {{{
  let query    = printf('{%s%s}', a:date, a:0 > 0 ? (','.a:1) : '')
  let date_pat = s:GetDatePat(a:date)
  let category = a:0 > 0 ? a:1 : '*'
  let category_pat = s:GetCategoryPat(category)
  if exists('g:PIM_Account_Use_Glob') && g:PIM_Account_Use_Glob != 0 
        \ && exists('g:PIM_Account_Glob') && !empty(g:PIM_Account_Glob)
    let expense = s:AccountIter(1, split(glob(g:PIM_Account_Glob)), 's:CheckExpense', [date_pat, category_pat], 's:Add', expense)
  else
    let expense = s:AccountIter(0, s:Getline(1, '$'), 's:CheckExpense', [date_pat, category_pat], 's:Add', 0)
  endif
  echo query 'TOTAL:' expense
endfunction
"}}}
function! PIM#Account#ExpenseSummary(show_elapsed_day, date, ...)  " ... = category {{{
  let date_pat = s:GetDatePat(a:date)
  let date_pat = s:GetDatePat(a:date)
  let category = a:0 > 0 ? a:1 : '*'
  let category_pat = s:GetCategoryPat(category)
  if exists('g:PIM_Account_Use_Glob') && g:PIM_Account_Use_Glob != 0 
        \ && exists('g:PIM_Account_Glob') && !empty(g:PIM_Account_Glob)
    let items = s:AccountIter(1, split(glob(g:PIM_Account_Glob)), 's:CheckExpense', [date_pat, category_pat], 's:Add', items)
  else
    let items = s:AccountIter(0 ,s:Getline(1, '$'), 's:CheckItemAndExpense', [date_pat, category_pat], 's:AddItems', [[], 0])
  endif
  call sort(items[0], 's:DateCompare')
  let winnum = CreateSharedTempBuffer('__account_expense_summary__', '<SNR>'.s:SID().'_AccountSummaryInit')
  exe winnum . 'wincmd w'
  silent %d_
  let expense = items[1]
  call append(line('$'), [
        \     printf('%-12s %' . s:EXPENSE_FIELD_WIDTH . 'd <%s> TOTAL'
        \             ,'(' . a:date . ')', expense, category)
        \     ,repeat('-', &columns)])
  let items = items[0]
  if a:show_elapsed_day
    let i = 0
    let len = len(items)
    if len != 0
      let item = items[i]
      call append(line('$'), s:ShowItem(item))
      let i += 1
      while i < len
        let elased_day = items[i]['julian_day'] - item['julian_day']
        call append(line('$'), printf('| %d day%s', elased_day, (elased_day > 1 ? 's' : '')))
        let item = items[i]
        call append(line('$'), s:ShowItem(item))
        let i += 1
      endwhile
    endif
  else
    for item in items
      call append(line('$'), s:ShowItem(item))
    endfor
  endif
  silent 1d_
endfunction
"}}}
function! s:DateStrCompare(i1, i2) "{{{
  if a:i1 == s:CATEGORY_SEP && a:i2 == s:CATEGORY_SEP
    return 0
  elseif a:i1 == s:CATEGORY_SEP
    return 1
  elseif a:i2 == s:CATEGORY_SEP
    return -1
  endif

  let date_pat = '^' . s:DATE_PAT
  let [i1, i2] = map(copy([a:i1, a:i2])
        \ ,'s:JulianDayFromDate(matchstr(v:val, date_pat))')
  return i1 == i2 ? 0 : i1 > i2 ? 1 : -1
endfunction
"}}}
function! s:Center(str, width) "{{{
  let width = a:width < 0 ? -a:width : a:width
  let len = strlen(a:str)
  if width <= len
    return a:str
  endif
  let sw = width - len
  let sp = repeat(' ', sw/2)
  return sp . a:str . sp . (sw % 2 == 0 ? '' : ' ')
endfunction
"}}}
" function! s:DatePartList(date_list) {{{
let s:DatePartList = {}
function! s:DatePartList.Total(date_list) "{{{
  return []
endfunction
"}}}
function! s:DatePartList.Daily(date_list) "{{{
  let date_part = [[], [], []]
  for date in a:date_list
    let part = s:ParseDate(date, 1)
    call add(date_part[0], part[0])
    call add(date_part[1], part[1] . s:DATE_DELIMITER . part[2])
    call add(date_part[2], '[' . s:WEEKDAY[s:DayOfTheWeekFromDate(date)] . ']')
  endfor

  return date_part
endfunction
"}}}
function! s:DatePartList.Weekly(date_list) "{{{
  let date_part = [[], [], [], [], [], []]
  for date in a:date_list
    let [dbeg, dend, weeknumber] = split(date, ':')
    let beg_part = s:ParseDate(dbeg, 1)
    let end_part = s:ParseDate(dend, 1)
    call add(date_part[0], beg_part[0])
    call add(date_part[1], beg_part[1] . s:DATE_DELIMITER . beg_part[2])
    call add(date_part[2], '|')
    call add(date_part[3], end_part[0])
    call add(date_part[4], end_part[1] . s:DATE_DELIMITER . end_part[2])
    call add(date_part[5], '(' . weeknumber . ')')
  endfor

  return date_part
endfunction
"}}}
function! s:DatePartList.Monthly(date_list) "{{{
  let date_part = [[], []]
  for date in a:date_list
    let part = s:ParseDate(date, 1)
    call add(date_part[0], part[0])
    call add(date_part[1], part[1])
  endfor

  return date_part
endfunction
"}}}
function! s:DatePartList.Annual(date_list) "{{{
  let date_part = [[]]
  for date in a:date_list
    let part = s:ParseDate(date, 1)
    call add(date_part[0], part[0])
  endfor

  return date_part
endfunction
"}}}
"}}}
" function! s:SortDateList(date_list) {{{
let s:SortDateList = {}
function! s:SortDateList.General(date_list) "{{{
  return sort(a:date_list, 's:DateStrCompare')
endfunction
"}}}
function! s:SortDateList.Total(date_list) "{{{
  return a:date_list
endfunction
"}}}
let s:SortDateList.Daily   = s:SortDateList.General
let s:SortDateList.Weekly  = s:SortDateList.General
let s:SortDateList.Monthly = s:SortDateList.General
let s:SortDateList.Annual  = s:SortDateList.General
"}}}
function! s:GetAccountGlob() "{{{
  if exists('g:PIM_Account_Use_Glob') && g:PIM_Account_Use_Glob != 0 
        \ && exists('g:PIM_Account_Glob') && !empty(g:PIM_Account_Glob)
    return [split(glob(g:PIM_Account_Glob), '\n')]
  else
    return []
  endif
endfunction
"}}}
" function! s:ShowCategorySummaryHeader(date_list, expense_width) {{{
let s:ShowCategorySummaryHeader = {}
function! s:ShowCategorySummaryHeader.General(freq, date_list, expense_width) "{{{
  call append(line('$'), repeat('-', &columns) . 'v')
  let date_part_list = s:DatePartList[a:freq](a:date_list)
  let expense_width = a:expense_width +2
  for list in date_part_list
    call append(line('$'), join(map(copy(list), 's:Center(v:val, expense_width)'), ''))
  endfor
  call append(line('$'), repeat('-', &columns) . '^')
endfunction
"}}}
function! s:ShowCategorySummaryHeader.Total(date_list, expense_width) "{{{
  call append(line('$'), repeat('-', &columns))
endfunction
"}}}
function! s:ShowCategorySummaryHeader.Daily(date_list, expense_width) "{{{
  call s:ShowCategorySummaryHeader.General('Daily', a:date_list, a:expense_width)
endfunction
"}}}
function! s:ShowCategorySummaryHeader.Weekly(date_list, expense_width) "{{{
  call s:ShowCategorySummaryHeader.General('Weekly', a:date_list, a:expense_width)
endfunction
"}}}
function! s:ShowCategorySummaryHeader.Monthly(date_list, expense_width) "{{{
  call s:ShowCategorySummaryHeader.General('Monthly', a:date_list, a:expense_width)
endfunction
"}}}
function! s:ShowCategorySummaryHeader.Annual(date_list, expense_width) "{{{
  call s:ShowCategorySummaryHeader.General('Annual', a:date_list, a:expense_width)
endfunction
"}}}
"}}}
function! PIM#Account#FreqCategorySummary(freq, date, ...)  " ... = category {{{
  let date_pat = s:GetDatePat(a:date)
  let category = a:0 > 0 ? a:1 : '*'
  let category_pat = s:GetCategoryPat(category)
  let ReduceFunc = s:AddCategoryExpense[a:freq]
  let glob = s:GetAccountGlob()
  if !empty(glob)
    let expense = s:AccountIter(1, glob[0], 's:CheckItem', [date_pat, category_pat], ReduceFunc, {})
  else
    let expense = s:AccountIter(0, s:Getline(1, '$'), 's:CheckItem', [date_pat, category_pat], ReduceFunc, {})
  endif

  let date_list = s:SortDateList[a:freq](keys(expense))
  let winnum = CreateSharedTempBuffer('__account_category_summary__', '<SNR>'.s:SID().'_AccountSummaryInit')
  exe winnum . 'wincmd w'
  silent %d_
  call append(line('$'), printf('%9s   <%s>', '(' . a:date .')', a:0 > 0 ? a:1 : '*'))
  let expense_width = 9
  call s:ShowCategorySummaryHeader[a:freq](date_list, expense_width)
  call s:ShowTotalCategoryExpense[a:freq](date_list, expense, category, expense_width)
  call s:ShowCategoryExpense[a:freq](date_list, g:category_list, expense, '', 0, expense_width)
  silent 1d_
endfunction
"}}}
" }}}
" ==========================================================
" Category completion {{{
" ----------------------------------------------------------
function! s:RemoveBlankLines(lines) "{{{
  while !empty(a:lines)
    let line = a:lines[0]
    if line =~ '^\s*$'
      call remove(a:lines, 0)
    else
      return
    endif
  endwhile
endfunction
" }}}
function! s:CreateCategoryList(lines)  "{{{
  call s:RemoveBlankLines(a:lines)
  if empty(a:lines)
    return {}
  endif

  let list = [[], []]
  call s:RemoveBlankLines(a:lines)
  let null = [[], []]
  while !empty(a:lines)
    let line = remove(a:lines, 0)
    let leading = matchend(line, '^\s*')
    let category = substitute(line, '^\s\+\|\s\+$', '', 'g')

    call s:RemoveBlankLines(a:lines)
    if empty(a:lines)
      break
    endif

    let line = a:lines[0]
    let next_leading = matchend(line, '^\s*')

    if next_leading < leading
      break
    else
      let idx = index(list[0], category)
      if idx == -1
        call add(list[0], category)
        call add(list[1], null)
      endif
      if next_leading > leading
        let list[1][idx] = s:CreateCategoryList(a:lines)
      endif
    endif
  endwhile

  if index(list[0], category) == -1
    call add(list[0], category)
    call add(list[1], null)
  endif

  return list
endfunction
" }}}
function! s:CategoryList(file) "{{{
  if !filereadable(a:file)
    return [[], []]
  endif

  return s:CreateCategoryList(readfile(a:file))
endfunction
"}}}
function! s:CompleteCategories(findstart, base) "{{{
  let start = col('.') - 2
  let line = start <= 0 ? '' : getline('.')[ : start]
  if a:findstart
    if line !~ '^\s*-\?\d\+\s*\[[^\]]*$'
      let s:complete_categories = 0
      return -1
    endif
    let s:complete_categories = 1
    let subcategory = matchstr(line, printf('\%%([\[%s%s]\)\@<=[^\[%s%s]*$'
          \ ,s:CATEGORY_SEP, s:SUB_CATEGORY_DELIMITER, s:CATEGORY_SEP, s:SUB_CATEGORY_DELIMITER))
    return start - len(subcategory) + 1
  else
    if s:complete_categories == 0
      return []
    endif

    let base = '^' . a:base
    let categories_str = matchstr(line, printf('\%%([\[%s]\)\@<=[^\[%s]*$'
          \, s:CATEGORY_SEP, s:CATEGORY_SEP))
    let categories = split(categories_str, '\.')
    let subcategories = s:GetSubCategories(g:category_list, categories)
    return filter(copy(subcategories), 'v:val =~ base')
  endif
endfunction
"}}}
function! s:GetSubCategories(list, categories) "{{{
  let list = a:list
  for category in a:categories
    if empty(list)
      return []
    endif
    let idx = index(list[0], category)
    if idx != -1
      if empty(list[1])
        return []
      endif
      let list = list[1][idx]
    else
      return []
    endif
  endfor

  return list[0]
endfunction
"}}}
" }}}
" ==========================================================
" Query {{{
" ----------------------------------------------------------
function! s:GetRegexPatAtom(pat, sep) "{{{
  if empty(a:pat)
    return a:pat
  elseif a:pat == '\'
    return '\\'
  endif

  let c = a:pat[0] 
  if c == '\'
    return escape(substitute(a:pat, '\\\(.\)', '\1', 'g'), '\')
  elseif c == '['
    return substitute(a:pat, '^\[', '\\&', 'g')
  elseif c == '*'
    return substitute(a:pat, '*', printf('\\[^%s]\\*', escape(escape(a:sep, '\'), '\')), 'g')
  elseif c == '?'
    return substitute(a:pat, '?', printf('\\[^%s]', escape(escape(a:sep, '\'), '\')), 'g')
  else
    return ''
  endif
endfunction
"}}}
function! s:GetRegexPat(pat, sep) "{{{
  return substitute(a:pat, '\%(\\.\)\+\|\[^\?\%(\\.\|[^\\\]]\+\)*\]\|\*\+\|?\|\\'
        \ ,'\=s:GetRegexPatAtom(submatch(0), a:sep)', 'g')
endfunction
"}}}
function! s:PatternExpand(pat, sep) "{{{
  let expanses = Braces#Expand(a:pat)
  call map(expanses, 's:GetRegexPat(v:val, a:sep)')
  return '^\V\%(' . join(expanses, '\|') . printf('\)\%%(\%%(%s\)\@=\|\$\)', escape(a:sep, '\'))
endfunction
"}}}
function! s:GetCategoryPat(query) "{{{
  if a:query == '*'
    return ''
  endif
  return s:PatternExpand(a:query, s:SUB_CATEGORY_DELIMITER)
endfunction
"}}}
function! s:GetDatePat(query) "{{{
  return s:PatternExpand(a:query, s:DATE_DELIMITER)
endfunction
"}}}
" }}}
" ==========================================================
" Account Iterator {{{
" ----------------------------------------------------------
function! s:AccountIter(type, elems, func, args, reduce, init) "{{{
  let a = a:init
  let item = {}
  let date_pat = '^\s*[#\*]\zs' . s:DATE_PAT . '\ze'
  if a:type == 0    " lines
    for line in a:elems
      if line =~ '^\s\*$' || line =~ '^\s*\$'
        continue
      endif

      let item['expense' ] = 0
      let item['category'] = []
      let item['comment' ] = ''
      let proc = 0
      if match(line, date_pat) != -1
        let proc = 0
        let item['date'] = matchstr(line, date_pat)
      elseif match(line, '^\s*-\?\d\+\s*\[[^\]]*\]') != -1
        let proc = has_key(item, 'date')
        if proc
          let list = matchlist(line, '^\s*\(-\?\d\+\)\s*\[\([^\]]*\)\]\s*\(.*\)$')
          let item['expense' ] = str2nr(list[1])
          let item['category'] = s:GetCategory(list[2])
          let item['comment' ] = list[3]
        endif
      else
        let proc = 0
      endif

      if proc
        let b = call(a:func, [copy(item)] + (type(a:args) == type([]) ? a:args : [a:args]), {})
        let a = call(a:reduce, [a, b], {})
      endif
    endfor
  else
    let a = a:init
    for file in a:elems
      if !filereadable(file)
        continue
      endif
      let a = s:AccountIter(0, readfile(file), a:func, a:args, a:reduce, a)
    endfor
  endif

  return a
endfunction
"}}}
function! s:GetCategory(categories) "{{{
  return split(a:categories, s:CATEGORY_SEP)
endfunction
"}}}
function! s:Check(item, date, category) "{{{
  if a:item['date'] !~ a:date
    return 0
  endif

  for category in a:item['category']
    if category !~ a:category
      return 0
    endif
  endfor

  return 1
endfunction
"}}}
function! s:CheckExpense(item, date, category) "{{{
  return s:Check(a:item, a:date, a:category)? a:item['expense'] : 0
endfunction
"}}}
function! s:Add(a, b) "{{{
  return a:a + a:b
endfunction
"}}}
function! s:CheckItemAndExpense(item, date, category) "{{{
  let a:item['julian_day'] = s:JulianDayFromDate(a:item['date'])
  return s:Check(a:item, a:date, a:category) ? [a:item, a:item['expense']] : []
endfunction
" }}}
function! s:AddItems(a, b) "{{{
  if empty(a:b)
    return a:a
  endif

  call add(a:a[0], a:b[0])
  let a:a[1] += a:b[1]
  return a:a
endfunction
"}}}
function! s:CheckItem(item, date, category) "{{{
  return s:Check(a:item, a:date, a:category) ? a:item : {}
endfunction
" }}}
" function! s:GetDate(date) {{{
let s:GetDate = {}
function! s:GetDate.Total(date) "{{{
  return ''
endfunction
"}}}
function! s:GetDate.Daily(date) "{{{
  return a:date
endfunction
"}}}
function! s:GetDate.Weekly(date) "{{{
    let weeknumber = s:WeekNumberFromDate(a:date)
    return weeknumber['beg'] . ':' . weeknumber['end'] . ':' . weeknumber['weeknumber']
endfunction
"}}}
function! s:GetDate.Monthly(date) "{{{
  return join(s:ParseDate(a:date, 1)[ : 1], s:DATE_DELIMITER) . s:DATE_DELIMITER . '01'
endfunction
"}}}
function! s:GetDate.Annual(date) "{{{
  return s:ParseDate(a:date, 1)[0] . s:DATE_DELIMITER . join(['01', '01'], s:DATE_DELIMITER)
endfunction
"}}}
"}}}
function! s:AddFreqCategoryExpense(freq, a, b) "{{{
  if empty(a:b)
    return a:a
  endif
  
  for category in a:b['category']
    let date = has_key(s:GetDate, a:freq) ? s:GetDate[a:freq](a:b['date']) : ''

    if date != ''
      if !has_key(a:a, date)
        let a:a[date] = {}
      endif
      let a = a:a[date]
    else
      let a = a:a
    endif

    let first = 0
    let subcategories = split(category, '\V' . escape(s:SUB_CATEGORY_DELIMITER ,'\'))
    for i in range(len(subcategories))
      if first == 0
        let first = 1
        if !has_key(a, s:CATEGORY_SEP)
          let a[s:CATEGORY_SEP]  = a:b['expense']
        else
          let a[s:CATEGORY_SEP] += a:b['expense']
        endif
      endif

      let subcategory = join(subcategories[ : i], s:SUB_CATEGORY_DELIMITER)
      if !has_key(a, subcategory)
        let a[subcategory]  = a:b['expense']
      else
        let a[subcategory] += a:b['expense']
      endif
    endfor
  endfor
  return a:a
endfunction
"}}}
" function! s:AddCategoryExpense(a, b) {{{
let s:AddCategoryExpense = {}
function! s:AddCategoryExpense.Total(a, b) "{{{
  return s:AddFreqCategoryExpense('Total', a:a, a:b)
endfunction
"}}}
function! s:AddCategoryExpense.Daily(a, b) "{{{
  return s:AddFreqCategoryExpense('Daily', a:a, a:b)
endfunction
"}}}
function! s:AddCategoryExpense.Weekly(a, b) "{{{
  return s:AddFreqCategoryExpense('Weekly', a:a, a:b)
endfunction
"}}}
function! s:AddCategoryExpense.Monthly(a, b) "{{{
  return s:AddFreqCategoryExpense('Monthly', a:a, a:b)
endfunction
"}}}
function! s:AddCategoryExpense.Annual(a, b) "{{{
  return s:AddFreqCategoryExpense('Annual', a:a, a:b)
endfunction
"}}}
"}}}
"}}}
" ==========================================================
" Account Buffer  {{{
" ----------------------------------------------------------
function! s:MoveOrCompleteKey() "{{{
  if pumvisible()
    return "\<C-N>"
  else
    return "\<C-O>:call <SNR>".s:SID()."_MoveToNextField()\<CR>"
  endif
endfunction
"}}}
function! s:AccountInit(category_file) "{{{
  call s:AccountSyntaxInit()
  call s:LoadCategoryFile(a:category_file)
  exec 'setlocal completefunc='.'<SNR>'.s:SID().'_CompleteCategories'

  set nowrap
  exec 'lcd ' . expand('%:p:h')
  setl foldmethod=expr
  setl foldexpr=getline(v:lnum)=~'^\s*@'?'>1':getline(v:lnum)=~'^\s*#'?'>2':getline(v:lnum)=~'^\s*\\*'?'>0':'='
  nnoremap <silent> <buffer> <F6>  :<C-U>call <SID>NewEntry("$")<CR>
  imap     <silent> <buffer> <F6>  <C-O><F6>
  nnoremap <silent> <buffer> <F7>  :<C-U>call <SID>ShowExpense()<CR>
  nnoremap <silent> <buffer> <F8>  :<C-U>.s/^\(\s*\)\*/\1#/e\|let @/=""<CR>
  inoremap <silent> <buffer> <expr> <Tab> <SID>MoveOrCompleteKey()
  imap     <silent> <buffer> <Leader><Tab> <C-X><C-U>
  nnoremap <silent> <buffer> gd :<C-U>call search('^\s*[\*#]')<CR>za
  nnoremap <silent> <buffer> gD :<C-U>call search('^\s*[\*#]', 'b')<CR>za
  nnoremap <silent> <buffer> gm :<C-U>call search('^\s*@')<CR>za
  nnoremap <silent> <buffer> gM :<C-U>call search('^\s*@', 'b')<CR>za

  inoremap <silent> <buffer> <C-L> <C-X><C-U>

  if exists('*CompleteParenMap')
    call CompleteParenMap('[')
  endif

  if !exists('g:PIM_Account_Use_Glob')
    let g:PIM_Account_Use_Glob = 0
  endif

  let g:account_buf = bufnr('')
  command! -buffer -nargs=+       AccountSum call PIM#Account#Sum(<f-args>)
  command! -buffer -nargs=+ -bang AccountExpenseSummary  call PIM#Account#ExpenseSummary(<q-bang> == '!', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummary call PIM#Account#FreqCategorySummary('Total', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryDaily call PIM#Account#FreqCategorySummary('Daily', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryWeekly call PIM#Account#FreqCategorySummary('Weekly', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryMonthly call PIM#Account#FreqCategorySummary('Monthly', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryAnnual call PIM#Account#FreqCategorySummary('Annual', <f-args>)
  command! -buffer -nargs=?       AccountReloadCategoryFile call s:LoadCategoryFile(<f-args>)
endfunction
"}}}
function! s:AccountSyntaxInit() "{{{
  syntax clear

  syn region accountString start=/"/ skip=/\\"/ end=/"/

  syn match accountMemo              "^\s*$.*"
  syn match accountYear              "=\zs\d\+\ze="
  exec 'syn match accountMonth       "^\s*\zs@[0-9\' . s:DATE_DELIMITER . ']\+\ze"'
  exec 'syn match accountDate        "^\s*\zs#[0-9\' . s:DATE_DELIMITER . ']\+\ze"'
  syn match accountExpense           "^\s*-\?\d\+" nextgroup=accountCategory skipwhite
  syn match accountSum               "\s\+-\s\+\zs-\?\d\+\ze"
  syn match accountCategory          "\s*\zs\[[^\]]*\]\ze" contained

  hi def link accountYear            Todo
  hi def link accountMonth           Label
  hi def link accountDate            Todo
  hi def link accountExpense         Special
  hi def link accountSum             Special
  hi def link accountCategory        Identifier
  hi def link accountMemo            Exception

  let b:current_syntax = 'account'
endfunction
"}}}
function! s:ShowExpense() "{{{
  let line = getline('.')
  let pos  = match(line, '^\s*[@#\*][0-9\' . s:DATE_DELIMITER . ']\+')
  if pos == -1
    return
  endif
  let date    = matchstr(line, '^\s*[@#\*]\zs[0-9\' . s:DATE_DELIMITER . ']\+\ze')
  let expense = s:AccountIter(0, getline(1, '$'), 's:CheckExpense', [date, ''], 's:Add', 0)
  let line    = substitute(line, '\s*\%(-\d\+\|\d*\)\s*$', ' ' . expense, '')
  call setline('.',  line)
endfunction
"}}}
function! s:NewEntry(pos) "{{{
  let ins = line(a:pos)
  let [year, month, day] = [strftime('%Y')+0, strftime('%m')+0, strftime('%d')+0]
  let [prev_year, prev_month, prev_day] = [0, 0, 0]

  call cursor(line('$'), 1)
  let [lnum, col] = searchpos('^\s*[@#\*][0-9\' . s:DATE_DELIMITER . ']\+', 'cnbW')
  if lnum != 0
    let line = getline(lnum)
    let list = matchlist(line, '^\s*[@\*]\V' . join(['\(\d\+\)', '\(\d\+\)', '\(\d\+\)'], escape(s:DATE_DELIMITER, '\')))
    if !empty(list)
      let [prev_year, prev_month, prev_day] = map(list[1 : 3], 'v:val+0')
    else
      let list = matchlist(line, '^\s*#\V' . join(['\(\d\+\)', '\(\d\+\)'], escape(s:DATE_DELIMITER, '\')))
      if !empty(list)
        let [prev_year, prev_month] = map(list[1 : 2], 'v:val+0')
      endif
    endif
  endif

  let lines = []
  if (year >= prev_year && month > prev_month)
    call add(lines, printf('@%04d' . s:DATE_DELIMITER . '%02d - ', year, month))
  endif

  if (year >= prev_year && month >= prev_month && day > prev_day) 
        \ || (year >= prev_year && month > prev_month)
        \ || (year > prev_year)

    call extend(lines, [printf('*%04d' . s:DATE_DELIMITER . '%02d' . s:DATE_DELIMITER . '%02d - ', year, month, day)])
    call append(line(a:pos), lines)
  endif

  call append(line('$'), repeat(' ', s:EXPENSE_FIELD_WIDTH) . ' []')
  call cursor(line('$'), s:EXPENSE_FIELD_WIDTH + 1)
  startinsert
endfunction
"}}}
function! s:AdjustLine(line, col) "{{{
  let list  = matchlist(a:line, '^\(\s*-\?\d\+\)\s*\(\[[^\]]*\].*\)$')
  if empty(list)
    return [a:line, a:col]
  endif

  let expense = list[1]
  let list[1] = printf('%' . s:EXPENSE_FIELD_WIDTH . 's', substitute(expense, '^\s\+', '', ''))
  let line = list[1] . ' ' . list[2]
  if line == a:line
    return [a:line, a:col]
  endif

  let col = a:col
  if strlen(list[1]) < strlen(expense)
    let col -= strlen(expense) - strlen(list[1])
  endif
  call setline('.', line)
  return [line, col]
endfunction
"}}}
function! s:MoveToNextField() "{{{
  let line = getline('.')
  let [line, col] = s:AdjustLine(line, col('.'))
  let pos  = match(line, '^\s*-\?\d\+\s*\[[^\]]*\].*$')
  if pos == -1
    return
  endif
  let pos1 = matchend(line, '^\s*-\?\d\+\s*')
  let pos2 = matchend(line, '^\[[^\]]*\]', pos1)
  if col <= pos1
    call cursor(0, pos1+2)
  elseif col <= pos2
    call cursor(0, pos2+1)
  else
    call cursor(0, match(line, '-\?\d') + 1)
  endif
endfunction
"}}}
"}}}
" ==========================================================
" Account Summary Buffer  {{{
" ----------------------------------------------------------
function! s:AccountSummaryInit() "{{{
  call s:AccountSummarySyntaxInit()
  set nowrap

  command! -buffer -nargs=+       AccountSum call PIM#Account#Sum(<f-args>)
  command! -buffer -nargs=+ -bang AccountExpenseSummary  call PIM#Account#ExpenseSummary(<q-bang> == '!', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummary call PIM#Account#FreqCategorySummary('Total', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryDaily call PIM#Account#FreqCategorySummary('Daily', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryWeekly call PIM#Account#FreqCategorySummary('Weekly', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryMonthly call PIM#Account#FreqCategorySummary('Monthly', <f-args>)
  command! -buffer -nargs=+ -bang AccountCategorySummaryAnnual call PIM#Account#FreqCategorySummary('Annual', <f-args>)
  command! -buffer -nargs=?       AccountReloadCategoryFile call s:LoadCategoryFile(<f-args>)
endfunction
"}}}
function! s:AccountSummarySyntaxInit() "{{{
  syntax clear

  syn match accountSummaryDelimiter  "^-----\+$"
  syn region accountSummaryHeader matchgroup=accountSummaryDelimiter start='^----\+v$' end='^----\+\^$'

  syn match accountSummaryDate       "\%(^\s*\)\@<=([^\)]*)" nextgroup=accountSummaryExpense,accountSummaryCategory skipwhite
  syn match accountSummaryExpense    "-\?\d\+"   nextgroup=accountSummaryCategory,accountSummaryExpense contained skipwhite
  syn match accountSummaryExpense    "\%(^\s*\)\@<=-\?\d\+"   nextgroup=accountSummaryCategory,accountSummaryExpense skipwhite
  syn match accountSummaryCategory   "\[[^\]]*\]" contained 

  syn match accountSummaryCategoryQuery   "<[^>]*>"

  syn match accountSummaryElaspedKw  "^|" nextgroup=accountSummaryElasped skipwhite
  syn match accountSummaryElasped    "-\?\d\+" contained

  syn match accountSummaryDate       "\d\+" contained containedin=accountSummaryHeader
  exec 'syn match accountSummaryDate "\V\d\+' . escape(s:DATE_DELIMITER, '\') .'\d\+" contained containedin=accountSummaryHeader'
  syn match accountSummaryWeekNumber "(\d\+)" contained containedin=accountSummaryHeader
  syn match accountSummaryWeekDay    "\[\%(Sun\|Mon\|Tue\|Wed\|Thu\|Fri\|Sat\)\]" contained containedin=accountSummaryHeader

  hi def link accountSummaryDate          Statement
  hi def link accountSummaryWeekDay       Statement
  hi def link accountSummaryExpense       Special
  hi def link accountSummaryCategory      Identifier
  hi def link accountSummaryElaspedKw     Comment
  hi def link accountSummaryElasped       Number
  hi def link accountSummaryDelimiter     Function
  hi def link accountSummaryWeekNumber    Identifier
  hi def link accountSummaryCategoryQuery String

  let b:current_syntax = 'account_summary'
endfunction
"}}}
" }}}
" ==========================================================
" Local Utilities {{{
" ----------------------------------------------------------
function! s:SID() "{{{
  if !exists('s:SID')
    let s:SID = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
  endif
  return s:SID
endfun
"}}}
function! s:ShowItem(item) "{{{
  return printf('(%s) %' . s:EXPENSE_FIELD_WIDTH . 'd [%s] %s'
         \      , a:item['date'], a:item['expense'], join(a:item['category'], s:CATEGORY_SEP)
         \      , a:item['comment'])
endfunction
"}}}
function! s:ParseDate(date, ...) " ... = type {{{
  let list = matchlist(a:date, '^\V' . join(['\(\d\{4}\)', '\(\d\{2}\)', '\(\d\{2}\)'], escape(s:DATE_DELIMITER, '\')))
  if empty(list)
    return a:0 > 0 && a:1 != 0 ? ['1970', '01', '01'] : [1970, 1, 1]
  else
    return a:0 > 0 && a:1 != 0 ? list[1 : 3] : map(list[1 : 3], 'str2nr(v:val)')
  endif
endfunction
"}}}
function! s:DateCompare(item1, item2) "{{{
  let [i1, i2] = [a:item1['julian_day'], a:item2['julian_day']]
  return i1 == i2 ? 0 : i1 > i2 ? 1 : -1
endfunction
"}}}
function! s:LoadCategoryFile(...) "{{{
  if a:0 > 0
    let g:category_file = a:1
  endif
  let g:category_list = s:CategoryList(g:category_file)
endfunction
"}}}
" function! s:ShowTotalCategoryExpense(date_list, expense, category, expense_width) {{{
let s:ShowTotalCategoryExpense = {}
function! s:ShowTotalCategoryExpense.Total(date_list, expense, category, expense_width) "{{{
  let expense = has_key(a:expense, s:CATEGORY_SEP) ? a:expense[s:CATEGORY_SEP] : 0
  call append(line('$'), printf('%' . a:expense_width .'d   <%s>', expense, a:category))
endfunction
"}}}
function! s:ShowTotalCategoryExpense.General(date_list, expense, category, expense_width) "{{{
  let line = ''
  for date in a:date_list
    let expense = has_key(a:expense[date], s:CATEGORY_SEP) ? a:expense[date][s:CATEGORY_SEP] : 0
    let line .= printf('%' . a:expense_width . 'd  ', expense)
  endfor
  if !empty(line)
    let line .= printf('<%s>', a:category)
    call append(line('$'), line)
  endif
endfunction
"}}}
let s:ShowTotalCategoryExpense.Daily   = s:ShowTotalCategoryExpense.General
let s:ShowTotalCategoryExpense.Weekly  = s:ShowTotalCategoryExpense.General
let s:ShowTotalCategoryExpense.Monthly = s:ShowTotalCategoryExpense.General
let s:ShowTotalCategoryExpense.Annual  = s:ShowTotalCategoryExpense.General
"}}}
" function! s:ShowCategoryExpense(date_list, category_list, expense, category, level, expense_width) {{{
let s:ShowCategoryExpense = {}
function! s:ShowCategoryExpense.Total(date_list, category_list, expense, category, level, expense_width) "{{{
  let categories = a:category_list[0]
  for i in range(len(categories))
    let category = a:category . (empty(a:category) ? '' : '.') . categories[i]
    if has_key(a:expense, category)
      let expense = a:expense[category]
    else
      continue
    endif
    call append(line('$'), printf('%' . a:expense_width .'d   %s[%s]', expense, repeat('    ', a:level), categories[i]))
    if !empty(a:category_list[1][i][0])
      call s:ShowCategoryExpense.Total(a:date_list, a:category_list[1][i], a:expense, category, a:level+1, a:expense_width)
    endif
  endfor
endfunction
"}}}
function! s:ShowCategoryExpense.General(date_list, category_list, expense, category, level, expense_width) "{{{
  let categories = a:category_list[0]
  for i in range(len(categories))
    let category = a:category . (empty(a:category) ? '' : '.') . categories[i]
    let line = ''
    let all_zero = 1
    for date in a:date_list
      let expense = has_key(a:expense[date], category) ? a:expense[date][category] : 0
      let line .= printf('%' . a:expense_width . 'd  ', expense)
      let all_zero = all_zero && expense == 0
    endfor
    if !all_zero
      let line .= printf('%s[%s]', repeat('    ', a:level), categories[i])
      call append(line('$'), line)
    endif
    if !empty(a:category_list[1][i][0])
      call s:ShowCategoryExpense.General(a:date_list, a:category_list[1][i], a:expense, category, a:level+1, a:expense_width)
    endif
  endfor
endfunction
"}}}
let s:ShowCategoryExpense.Daily   = s:ShowCategoryExpense.General
let s:ShowCategoryExpense.Weekly  = s:ShowCategoryExpense.General
let s:ShowCategoryExpense.Monthly = s:ShowCategoryExpense.General
let s:ShowCategoryExpense.Annual  = s:ShowCategoryExpense.General
"}}}
function! s:Getline(lnum, ...) "{{{
  return exists('g:account_buf') && bufexists(g:account_buf) ? call('getbufline', [g:account_buf, a:lnum] + a:000) : a:0 > 0 ? [] : ''
endfunction
"}}}
function! s:DayOfTheWeekFromDate(date)  " {{{
  if !exists('s:day_of_the_week')
    let s:day_of_the_week = {}
  endif
  if has_key(s:day_of_the_week, a:date)
    return s:day_of_the_week[a:date]
  endif
  let day_of_the_week = call('s:DayOfTheWeek', s:ParseDate(a:date))
  let s:day_of_the_week[a:date] = day_of_the_week  
  return day_of_the_week
endfunction
"}}}
function! s:DayOfTheWeek(year, mon, day) "{{{
  exec printf('let today = [%s]', strftime('%Y, %m, %d, %w'))
  let today_jd = s:JulianDay(today[0], today[1], today[2])
  let jd = s:JulianDay(a:year, a:mon, a:day)
  return (today[3] - (today_jd - jd) % 7 + 7) % 7
endfunction
"}}}
function! s:WeekNumberFromDate(date, ...)  " ... = start_the_week_on {{{
  if !exists('s:weeknumber')
    let s:weeknumber = {}
  endif
  if has_key(s:weeknumber, a:date)
    return s:weeknumber[a:date]
  endif
  let weeknumber = call('s:WeekNumber', s:ParseDate(a:date) + a:000)
  let s:weeknumber[a:date] = weeknumber  
  return weeknumber
endfunction
"}}}
function! s:WeekNumber(year, mon, day, ...) " ... = start_the_week_on {{{
  let start_the_week_on = a:0 > 0 ? (((a:1 % 7) + 7) % 7) : 0
  exec printf('let today = [%s]', strftime('%Y, %m, %d, %w'))
  let today_jd = s:JulianDay(today[0], today[1], today[2])
  let year_jd = s:JulianDay(a:year, 1, 1)
  let year_dw = (today[3] - (today_jd - year_jd) % 7 + 7) % 7
  let jd = s:JulianDay(a:year, a:mon, a:day)
  let dw = (today[3] - (today_jd - jd) % 7 + 7) % 7
  let beg_jd = jd - dw + start_the_week_on
  return {
        \ 'beg': join(map(copy(s:Gregorian(beg_jd)), "printf('%02d', v:val)"), s:DATE_DELIMITER),
        \ 'end': join(map(copy(s:Gregorian(beg_jd+6)), "printf('%02d', v:val)"), s:DATE_DELIMITER),
        \ 'weeknumber': (jd - year_jd + (year_dw - start_the_week_on))/7 + 1
        \ }
endfunction
"}}}
"}}}
" ==========================================================
" Elapsed day {{{
" Copy from speeddating.vim 
" <http://www.vim.org/scripts/script.php?script_id=2120>
" ----------------------------------------------------------
function! s:Div(a, b) "{{{
  if a:a < 0 && a:b > 0
    return (a:a-a:b+1)/a:b
  elseif a:a > 0 && a:b < 0
    return (a:a-a:b-1)/a:b
  else
    return a:a / a:b
  endif
endfunction
"}}}
function! s:JulianDayFromDate(date) "{{{
  if !exists('s:julian_day')
    let s:julian_day = {}
  endif
  if has_key(s:julian_day, a:date)
    return s:julian_day[a:date]
  endif
  let julian_day = call('s:JulianDay', s:ParseDate(a:date))
  let s:julian_day[a:date] = julian_day
  return julian_day
endfunction
"}}}
" Julian day (always Gregorian calendar) {{{
function! s:JulianDay(year, mon, day)
  let y = a:year + 4800 - (a:mon <= 2)
  let m = a:mon + (a:mon <= 2 ? 9 : -3)
  let jul = a:day + (153*m+2)/5 + s:Div(1461*y,4) - 32083
  return jul - s:Div(y,100) + s:Div(y,400) + 38
endfunction
"}}}
function! s:Gregorian(jd) "{{{
  let l = a:jd + 68569
  let n = s:Div(4 * l, 146097)
  let l = l - s:Div(146097 * n + 3, 4)
  let i = ( 4000 * ( l + 1 ) ) / 1461001
  let l = l - ( 1461 * i ) / 4 + 31
  let j = ( 80 * l ) / 2447
  let d = l - ( 2447 * j ) / 80
  let l = j / 11
  let m = j + 2 - ( 12 * l )
  let y = 100 * ( n - 49 ) + i + l
  return [y, m, d]
endfunction
"}}}
"}}}
" ==========================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
