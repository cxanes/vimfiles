" Inflector.vim: A wrapper for Python module 'Inflector'
"
" Last Modified: 2009-03-02 23:19:26
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Url: http://www.bermi.org/inflector
" Version: 0.1
" Description:
"
" The Text Inflector is a handy piece of code that transforms words from
" singular to plural, class names to table names, modularized class names
" to ones without and class names to foreign keys etc.

" Load Once {{{
if exists('loaded_Inflector')
  finish
endif
let loaded_Inflector = 1

if !has('python')
  echohl ErrorMsg
  echom 'Inflector: this script needs +python feature'
  echohl None
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}
let s:import_error = ''
python << EOF
try:
  import vim
  from Inflector.Inflector import Inflector
except ImportError, e:
  vim.command("let s:import_error = 'error'")
  vim.command('echohl ErrorMsg')
  vim.command("echom 'Inflector: %s'" % (str(str(e).replace("'", "''"))))
  vim.command('echohl None')

g_inflector = None
def GetInflector(): #{{{
    global g_inflector
    if g_inflector is not None:
        return g_inflector
    else:
        g_inflector = Inflector()
    return g_inflector
#}}}
def InflectorCallRaw(method, *args): #{{{
  if vim.eval('s:import_error'):
    vim.command('return ""')
    return
  vim.command("return '%s'" % getattr(GetInflector(), method)(*args).replace("'", "''"))
#}}}
def InflectorCall(method, *args): #{{{
  args = map(lambda arg: vim.eval(arg), args)
  InflectorCallRaw(method, *args)
#}}}
EOF
"=============================================================
" Pluralizes nouns.
function! Inflector#Pluralize(word) "{{{
  py InflectorCall('pluralize', 'a:word')
endfunction
    "}}}
" Singularizes nouns.
function! Inflector#Singularize(word) "{{{
  py InflectorCall('singularize', 'a:word')
endfunction
    "}}}
" Returns the plural form of a word if first parameter is greater than 1
function! Inflector#ConditionalPlural(numer_of_records, word) "{{{
  py InflectorCallRaw('conditionalPlural', int(vim.eval('a:numer_of_records')), vim.eval('a:word'))
endfunction
"}}}
" Converts an underscored or CamelCase word into a sentence.
" The titleize function converts text like "WelcomePage",
" "welcome_page" or  "welcome page" to this "Welcome Page".
" If the "uppercase" parameter is set to 'first' it will only
" capitalize the first character of the title.
function! Inflector#Titleize(word, ...) " ... = uppercase_first {{{
  let uppercase = a:0 > 0 && !empty(a:1) ? 'first' : ''
  py InflectorCall('titleize', 'a:word', 'uppercase')
endfunction
"}}}
" Returns given word as CamelCased
" Converts a word like "send_email" to "SendEmail". It
" will remove non alphanumeric character from the word, so
" "who's online" will be converted to "WhoSOnline"
function! Inflector#Camelize(word) "{{{
  py InflectorCall('camelize', 'a:word')
endfunction
"}}}
" Converts a word "into_it_s_underscored_version"
" Convert any "CamelCased" or "ordinary Word" into an
" "underscored_word".
" This can be really useful for creating friendly URLs.
function! Inflector#Underscore(word) "{{{
  py InflectorCall('underscore', 'a:word')
endfunction
"}}}
" Returns a human-readable string from word
" Returns a human-readable string from word, by replacing
" underscores with a space, and by upper-casing the initial
" character by default.
" If you need to uppercase all the words you just have to
" pass 'all' as a second parameter.
function! Inflector#Humanize(word, ...) " ... = uppercase_all {{{
  let uppercase = a:0 > 0 && !empty(a:1) ? '' : 'first'
  py InflectorCall('humanize', 'a:word', 'uppercase')
endfunction
"}}}
" Same as camelize but first char is lowercased
" Converts a word like "send_email" to "sendEmail". It
" will remove non alphanumeric character from the word, so
" "who's online" will be converted to "whoSOnline"
function! Inflector#Variablize(word) "{{{
  py InflectorCall('variablize', 'a:word')
endfunction
"}}}
" Converts a class name to its table name according to rails
" naming conventions. Example. Converts "Person" to "people" 
function! Inflector#Tableize(class_name) "{{{
  py InflectorCall('tableize', 'a:class_name')
endfunction
"}}}
" Converts a table name to its class name according to rails
" naming conventions. Example: Converts "people" to "Person" 
function! Inflector#Classify(table_name) "{{{
  py InflectorCall('classify', 'a:table_name')
endfunction
"}}}
" Converts number to its ordinal form.
" This method converts 13 to 13th, 2 to 2nd ...
function! Inflector#Ordinalize(number) "{{{
  py InflectorCallRaw('ordinalize', int(vim.eval('a:number')))
endfunction
"}}}
" Transforms a string to its unaccented version. 
" This might be useful for generating "friendly" URLs
function! Inflector#Unaccent(text) "{{{
  py InflectorCall('unaccent', 'a:text')
endfunction
"}}}
" Transform a string its unaccented and underscored
" version ready to be inserted in friendly URLs
function! Inflector#Urlize(text) "{{{
  py InflectorCall('urlize', 'a:text')
endfunction
"}}}
function! Inflector#Demodulize(module_name) "{{{
  py InflectorCall('demodulize', 'a:module_name')
endfunction
"}}}
function! Inflector#Modulize(module_description) "{{{
  py InflectorCall('modulize', 'a:module_description')
endfunction
"}}}
" Returns class_name in underscored form, with "_id" tacked on at the end. 
" This is for use in dealing with the database.
function! Inflector#ForeignKey(class_name, ...) "{{{
  " ... = separate_class_name_and_id_with_underscore
  let separate_class_name_and_id_with_underscore = a:0 > 0 && !empty(a:1) ? 'true' : ''
  py InflectorCall('foreignKey', 'a:class_name', 'separate_class_name_and_id_with_underscore')
endfunction
"}}}
"=============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
