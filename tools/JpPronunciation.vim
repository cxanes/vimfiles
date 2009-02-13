" JpPronunciation.vim
" Last Modified: 2008-04-11 06:11:01
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" JpPronunciation requires Vim to have +multi_byte and +iconv supports. {{{
" (+iconv feature is needed only if the encoding is not utf-8)
if !has('multi_byte')
  echohl ErrorMsg | echo 'JpPronunciation requires Vim to have +multi_byte support.' | echohl None
  finish
endif

if &enc != 'utf-8' && !has('iconv')
  echohl ErrorMsg
  echo 'The encoding is not "utf-8", and Vim doesn''t support +iconv feature.'
  echohl None
  finish
endif
" }}}
" Load Once {{{
if exists('loaded_JpPronunciation_plugin')
  finish
endif
let loaded_JpPronunciation_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"====================================================================== 
" Variables {{{
" JP_PRONUNCIATION {{{
" Ref: http://bbs.cc-sky.com/simple/index.php?t13950.html
let s:encoding = &enc
if s:encoding != 'utf-8'
  set enc=utf-8
endif

let s:JP_PRONUNCIATION = {'あ': 'A', 'ア': 'A', 'い': 'I', 'イ': 'I', 'う': 'U', 'ウ': 'U', 'え': 'E', 'エ': 'E', 'お': 'O', 'オ': 'O' , 'か': 'Ka', 'カ': 'Ka', 'き': 'Ki', 'キ': 'Ki', 'く': 'Ku', 'ク': 'Ku', 'け': 'Ke', 'ケ': 'Ke', 'こ': 'Ko', 'コ': 'Ko' , 'さ': 'Sa', 'サ': 'Sa', 'し': 'Shi/Si', 'シ': 'Shi/Si', 'す': 'Su', 'ス': 'Su', 'せ': 'Se', 'セ': 'Se', 'そ': 'So', 'ソ': 'So' , 'た': 'Ta', 'タ': 'Ta', 'ち': 'Chi/Ti', 'チ': 'Chi/Ti', 'つ': 'Tsu/Tu', 'ツ': 'Tsu/Tu', 'て': 'Te', 'テ': 'Te', 'と': 'To', 'ト': 'To' , 'な': 'Na', 'ナ': 'Na', 'に': 'Ni', 'ニ': 'Ni', 'ぬ': 'Nu', 'ヌ': 'Nu', 'ね': 'Ne', 'ネ': 'Ne', 'の': 'No', 'ノ': 'No' , 'は': 'Ha', 'ハ': 'Ha', 'ひ': 'Hi', 'ヒ': 'Hi', 'ふ': 'Hu/Fu', 'フ': 'Hu/Fu', 'へ': 'He', 'ヘ': 'He', 'ほ': 'Ho', 'ホ': 'Ho' , 'ま': 'Ma', 'マ': 'Ma', 'み': 'Mi', 'ミ': 'Mi', 'む': 'Mu', 'ム': 'Mu', 'め': 'Me', 'メ': 'Me', 'も': 'Mo', 'モ': 'Mo' , 'や': 'Ya', 'ヤ': 'Ya', 'ゆ': 'Yu', 'ユ': 'Yu', 'よ': 'Yo', 'ヨ': 'Yo' , 'ら': 'Ra', 'ラ': 'Ra', 'り': 'Ri', 'リ': 'Ri', 'る': 'Ru', 'ル': 'Ru', 'れ': 'Re', 'レ': 'Re', 'ろ': 'Ro', 'ロ': 'Ro' , 'わ': 'Wa', 'ワ': 'Wa', 'を': 'O/Wo', 'ヲ': 'O/Wo' , 'ん': 'N', 'ン': 'N' , 'っ': 'Q', 'ッ': 'Q' , 'が': 'Ga', 'ガ': 'Ga', 'ぎ': 'Gi', 'ギ': 'Gi', 'ぐ': 'Gu', 'グ': 'Gu', 'げ': 'Ge', 'ゲ': 'Ge', 'ご': 'Go', 'ゴ': 'Go' , 'ざ': 'Za', 'ザ': 'Za', 'じ': 'Ji/Zi', 'ジ': 'Ji/Zi', 'ず': 'Zu', 'ズ': 'Zu', 'ぜ': 'Ze', 'ゼ': 'Ze', 'ぞ': 'Zo', 'ゾ': 'Zo' , 'だ': 'Da', 'ダ': 'Da', 'ぢ': 'Ji/Di', 'ヂ': 'Ji/Di', 'づ': 'Zu/Du', 'ヅ': 'Zu/Du', 'で': 'De', 'デ': 'De', 'ど': 'Do', 'ド': 'Do' , 'ば': 'Ba', 'バ': 'Ba', 'び': 'Bi', 'ビ': 'Bi', 'ぶ': 'Bu', 'ブ': 'Bu', 'べ': 'Be', 'ベ': 'Be', 'ぼ': 'Bo', 'ボ': 'Bo' , 'ぱ': 'Pa', 'パ': 'Pa', 'ぴ': 'Pi', 'ピ': 'Pi', 'ぷ': 'Pu', 'プ': 'Pu', 'ぺ': 'Pe', 'ペ': 'Pe', 'ぽ': 'Po', 'ポ': 'Po'}

let s:JP_PRONUNCIATION2 = {'きゃ': 'Kya', 'きゅ': 'Kyu', 'きょ': 'Kyo' , 'しゃ': 'Sha/Sya', 'しゅ': 'Shu/Syu', 'しょ': 'Sho/Syo' , 'ちゃ': 'Cha', 'ちゅ': 'Chu', 'ちょ': 'Cho' , 'にゃ': 'Nya', 'にゅ': 'Nyu', 'にょ': 'Nyo' , 'ひゃ': 'Hya', 'ひゅ': 'Hyu', 'ひょ': 'Hyo' , 'みゃ': 'Mya', 'みゅ': 'Myu', 'みょ': 'Myo' , 'りゃ': 'Rya', 'りゅ': 'Ryu', 'りょ': 'Ryo' , 'ぎゃ': 'Gya', 'ぎゅ': 'Gyu', 'ぎょ': 'Gyo' , 'じゃ': 'Ja/Jya/Zya', 'じゅ': 'Ju/Jyu/Zyu', 'じょ': 'Jo/Jyo/Zyo' , 'ぢゃ': 'Dya', 'ぢゅ': 'Dyu', 'ぢょ': 'Dyo' , 'びゃ': 'Bya', 'びゅ': 'Byu', 'びょ': 'Byo' , 'ぴゃ': 'Pya', 'ぴゅ': 'Pyu', 'ぴょ': 'Pyo'}

if s:encoding != 'utf-8'
  exec 'set enc=' . s:encoding
endif
silent! unlet s:encoding
"}}}
let s:col_offset = 0
" }}}
" Commands {{{
command! -range ShowJpPronunciation call s:ShowJpPronunciation(<line1>, <line2>)
" }}}
"====================================================================== 
function! s:Choose(pronunciation) "{{{
  let pronunciation = matchstr(a:pronunciation, '^[^\/]\+')
  let strlen = strlen(pronunciation)
  if strlen > 2
    let s:col_offset += strlen - 2
  endif
  return pronunciation
endfunction
"}}}
function! s:Pronunciation(ch1, ch2) "{{{
  if a:ch2 != ''
    let ch = a:ch1 . a:ch2
    if has_key(s:JP_PRONUNCIATION2, ch)
      return [2, printf('%4s', s:Choose(s:JP_PRONUNCIATION2[ch]))]
    endif
  endif

  let new_ch = ''
  if has_key(s:JP_PRONUNCIATION, a:ch1)
    let new_ch .= printf('%2s', s:Choose(s:JP_PRONUNCIATION[a:ch1]))
  else
    let space_cnt = strlen(a:ch1) > 1 ? 2 : 1
    if s:col_offset != 0
      if s:col_offset == 1 || space_cnt == 1
        let space_cnt  -= 1
        let s:col_offset -= 1
      else 
        let space_cnt  -= 2
        let s:col_offset -= 2
      endif
    endif
    let new_ch .= repeat(' ', space_cnt)
  endif

  return [1, new_ch]
endfunction
"}}}
function! s:ShowJpPronunciation(line1, line2) "{{{
  let line2 = min([a:line2, line('$')])
  if a:line1 < 1 || a:line1 > line2
    return
  endif

  let lnum = a:line1
  let total_lines = line2 - a:line1 + 1

  while total_lines > 0
    let s:col_offset   = 0
    let pronounce_line = ''

    let line = getline(lnum)

    if line !~ '^[[:alnum:][:space:][:punct:]]*$'
      let line   = iconv(line, &enc, 'utf-8')
      let chars  = split(line, '\zs')
      let strlen = len(chars)

      let idx = 0
      while idx < strlen
        let [offset, char] = s:Pronunciation(chars[idx], (idx + 1 < strlen ? chars[idx + 1] : ''))
        let pronounce_line .= char
        let idx += offset
      endwhile
    endif

    let pronounce_line = substitute(pronounce_line, '\s\+$', '', 'g')
    if pronounce_line == ''
      let lnum += 1
    else
      call append(lnum, pronounce_line)
      let lnum += 2
    endif

    let total_lines -= 1
  endwhile
endfunction
"}}}
"====================================================================== 
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
