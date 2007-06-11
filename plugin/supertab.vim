" Author:
"   Original: Gergely Kontra <kgergely@mcl.hu>
"   Current:  Eric Van Dewoestine <ervandew@yahoo.com> (as of version 0.4)
"   Please direct all correspondence to Eric.
" Version: 0.42
"
" Description: {{{
"   Use your tab key to do all your completion in insert mode!
"   You can cycle forward and backward with the <Tab> and <S-Tab> keys
"   (<S-Tab> will not work in the console version)
"   Note: you must press <Tab> once to be able to cycle back
" History:
"   0.42 Added g:SuperTabMidWordCompletion variable to determine if completion
"        should be done within a word (enabled by default).  (based on request
"        by Charles Gruenwald)
"        Applied patch to fix <s-tab> cycling through completion results
"        (submitted by Lukasz Krotowski)
"   0.41 Fixed couple bugs introduced in last version.
"   0.4  Added the following functionality
"        - support for vim 7 omni, user, and spelling completion modes
"          (should be backwards compatible with vim 6.x).
"        - command :SuperTabHelp which opens a window with available
"          completion types that the user can choose from.
"        - variable g:SuperTabRetainCompletionType setting for determining if
"          and for how long to retain completion type.
"        - variable g:SuperTabDefaultCompletionType for determining the
"          user's preferred default completion type.
"   0.32 Corrected tab-insertion/completing decision (thx to: Lorenz Wegener)
"   0.31 Added <S-Tab> for backward cycling. (req by: Peter Chun)
"   0.3  Back to the roots. Autocompletion is another story...
"        Now the prompt appears, when showmode is on
" }}}

if !exists('complType') "Integration with other completion functions.

" Global Variables {{{

  " Used to set the default completion type.
  " There is no need to escape this value as that will be done for you when
  " the type is set.
  " Ex.  let g:SuperTabDefaultCompletionType = "<C-X><C-U>"
  if !exists("g:SuperTabDefaultCompletionType")
    let g:SuperTabDefaultCompletionType = "<C-P>"
  endif

  " Determines if, and for how long, the current completion type is retained.
  " The possible values include:
  " 0 - The current completion type is only retained for the current completion.
  "     Once you have chosen a completion result or exited the completion
  "     mode, the default completion type is restored.
  " 1 - The current completion type is saved for the duration of your vim
  "     session or until you enter a different completion mode.
  "     (SuperTab default).
  " 2 - The current completion type is saved until you exit insert mode (via
  "     ESC).  Once you exit insert mode the default completion type is
  "     restored.
  if !exists("g:SuperTabRetainCompletionType")
    let g:SuperTabRetainCompletionType = 1
  endif

  " Sets whether or not mid word completion is enabled.
  " When enabled, <tab> will kick off completion when ever a word character is
  " to the left of the cursor.  When disabled, completion will only occur if
  " the char to the left is a word char and the char to the right is not (you
  " are at the end of the word).
  if !exists("g:SuperTabMidWordCompletion")
    let g:SuperTabMidWordCompletion = 1
  endif

" }}}

" Script Variables {{{

  " construct the help text.
  let s:tabHelp =
    \ "Hit <CR> or CTRL-] on the completion type you wish to switch to.\n" .
    \ "Use :help ins-completion for more information.\n" .
    \ "\n" .
    \ "|<C-N>|      - Keywords in 'complete' searching down.\n" .
    \ "|<C-P>|      - Keywords in 'complete' searching up (SuperTab default).\n" .
    \ "|<C-X><C-L>| - Whole lines.\n" .
    \ "|<C-X><C-N>| - Keywords in current file.\n" .
    \ "|<C-X><C-K>| - Keywords in 'dictionary'.\n" .
    \ "|<C-X><C-T>| - Keywords in 'thesaurus', thesaurus-style.\n" .
    \ "|<C-X><C-I>| - Keywords in the current and included files.\n" .
    \ "|<C-X><C-]>| - Tags.\n" .
    \ "|<C-X><C-F>| - File names.\n" .
    \ "|<C-X><C-D>| - Definitions or macros.\n" .
    \ "|<C-X><C-V>| - Vim command-line."
  if v:version >= 700
    let s:tabHelp = s:tabHelp . "\n" .
      \ "|<C-X><C-U>| - User defined completion.\n" .
      \ "|<C-X><C-O>| - Omni completion.\n" .
      \ "|<C-X>s|     - Spelling suggestions."
  endif

  " set the available completion types and modes.
  let s:types =
    \ "\<C-E>\<C-Y>\<C-L>\<C-N>\<C-K>\<C-T>\<C-I>\<C-]>\<C-F>\<C-D>\<C-V>\<C-N>\<C-P>"
  let s:modes = '/^E/^Y/^L/^N/^K/^T/^I/^]/^F/^D/^V/^P'
  if v:version >= 700
    let s:types = s:types . "\<C-U>\<C-O>\<C-N>\<C-P>s"
    let s:modes = s:modes . '/^U/^O/s'
  endif
  let s:types = s:types . "np"
  let s:modes = s:modes . '/n/p'

" }}}

" CtrlXPP() {{{
" Handles entrance into completion mode.
function! CtrlXPP()
  if &smd
    echo '' | echo '-- ^X++ mode (' . s:modes . ')'
  endif
  let complType = nr2char(getchar())
  if stridx(s:types, complType) != -1
    if stridx("\<C-E>\<C-Y>", complType) != -1 " no memory, just scroll...
      return "\<C-x>" . complType
    elseif stridx('np', complType) != -1
      let complType = nr2char(char2nr(complType) - 96)  " char2nr('n')-char2nr("\<C-n")
    else
      let complType="\<C-x>" . complType
    endif

    if g:SuperTabRetainCompletionType
      let g:complType = complType
    endif

    return complType
  else
    echohl "Unknown mode"
    return complType
  endif
endfunction " }}}

" SuperTabSetCompletionType(type) {{{
" Globally available function that user's can use to create mappings to
" quickly switch completion modes.  Useful when a user wants to restore the
" default or switch to another mode without having to kick off a completion
" of that type or use SuperTabHelp.
" Example mapping to restore SuperTab default:
"   nmap <F6> :call SetSuperTabCompletionType("<C-P>")<cr>
function! SuperTabSetCompletionType (type)
  exec "let g:complType = \"" . escape(a:type, '<') . "\""
endfunction " }}}

" s:Init {{{
" Initializes super tab according to user defined settings.
function! s:Init ()
  " set the default completion type.
  call SuperTabSetCompletionType(g:SuperTabDefaultCompletionType)

  " Setup mechanism to restore orignial completion type upon leaving insert
  " mode if g:SuperTabDefaultCompletionType == 2
  if g:SuperTabRetainCompletionType == 2
    " pre vim 7, must map <esc>
    if v:version < 700
      im <silent> <ESC>
        \ <ESC>:call SuperTabSetCompletionType(g:SuperTabDefaultCompletionType)<cr>

    " since vim 7, we can use InsertLeave autocmd.
    else
      augroup supertab
        autocmd InsertLeave *
          \ call SuperTabSetCompletionType(g:SuperTabDefaultCompletionType)
      augroup END
    endif
  endif
endfunction " }}}

" s:SuperTab(command) {{{
" Used to perform proper cycle navigtion as the user request the next or
" previous entry in a completion list, and determines whether or not so simply
" retain the normal usage of <tab> based on the cursor position.
function! s:SuperTab(command)
  if s:WillComplete()
    " exception: if in <c-p> mode, then <c-n> should move up the list, and
    " <c-p> down the list.
    if a:command == 'p' && g:complType == "\<C-P>"
      return "\<C-N>"
    endif
    return g:complType
  else
    return "\<Tab>"
  endif
endfunction " }}}

" s:SuperTabHelp() {{{
" Opens a help window where the user can choose a completion type to enter.
function! s:SuperTabHelp()
  if bufwinnr("SuperTabHelp") == -1
    botright split SuperTabHelp

    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete

    let saved = @"
    let @" = s:tabHelp
    silent put
    call cursor(1, 1)
    silent 1,delete
    call cursor(4, 1)
    let @" = saved
    exec "resize " . line('$')

    syntax match Special "|.\{-}|"

    setlocal readonly
    setlocal nomodifiable

    nmap <silent> <buffer> <cr> :call <SID>SetCompletionType()<cr>
    nmap <silent> <buffer> <c-]> :call <SID>SetCompletionType()<cr>
  else
    exec bufwinnr("SuperTabHelp") . "winc w"
  endif
endfunction " }}}

" s:SetCompletionType() {{{
" Sets the completion type based on what the user has chosen from the help
" buffer.
function! s:SetCompletionType ()
  let chosen = substitute(getline('.'), '.*|\(.*\)|.*', '\1', '')
  if chosen != getline('.')
    call SuperTabSetCompletionType(chosen)
    close
    winc p
  endif
endfunction " }}}

" s:WillComplete () {{{
" Determines if completion should be kicked off at the current location.
function! s:WillComplete ()
  let line = getline('.')
  let cnum = col('.')

  " Start of line.
  let prev_char = strpart(line, cnum - 2, 1)
  if prev_char =~ '^\s*$'
    return 0
  endif

  " Within a word, but user does not have mid word completion enabled.
  let next_char = strpart(line, cnum - 1, 1)
  if !g:SuperTabMidWordCompletion && s:IsWordChar(next_char)
    return 0
  endif

  " In keyword completion mode and no preceding word characters.
  "if (g:complType == "\<C-N>" || g:complType == "\<C-P>") && !s:IsWordChar(prev_char)
  "  return 0
  "endif

  return 1
endfunction " }}}

" s:IsWordChar(char) {{{
" Determines if the supplied character is a word character or matches value
" defined by 'iskeyword'.
function! s:IsWordChar (char)
  if a:char =~ '\w'
    return 1
  endif

  " check against 'iskeyword'
  let values = &iskeyword
  let index = stridx(values, ',')
  while index > 0 || values != ''
    if index > 0
      let value = strpart(values, 0, index)
      let values = strpart(values, index + 1)
    else
      let value = values
      let values = ''
    endif

    " exception case for '^,'
    if value == '^'
      let value = '^,'

    " execption case for ','
    elseif value =~ '^,,'
      let values .= strpart(value, 2)
      let value = ','

    " execption case after a ^,
    elseif value =~ '^,'
      let value = strpart(value, 1)
    endif

    " keyword values is an ascii number range
    if value =~ '[0-9]\+-[0-9]\+'
      let charnum = char2nr(a:char)
      exec 'let start = ' . substitute(value, '\([0-9]\+\)-.*', '\1', '')
      exec 'let end = ' . substitute(value, '.*-\([0-9]\+\)', '\1', '')

      if charnum >= start && charnum <= end
        return 1
      endif

    " keyword value is a set of include or exclude characters
    else
      let include = 1
      if value =~ '^\^'
        let value = strpart(value, 1)
        let include = 0
      endif

      if a:char =~ '[' . escape(value, '[]') . ']'
        return include
      endif
    endif
    let index = stridx(values, ',')
  endwhile

  return 0
endfunction " }}}

" Key Mappings {{{
  im <C-X> <C-r>=CtrlXPP()<CR>

  " From the doc |insert.txt| improved
  im <Tab> <C-n>
  im <S-Tab> <C-p>

  " After hitting <Tab>, hitting it once more will go to next match
  " (because in XIM mode <C-n> and <C-p> mappings are ignored)
  " and wont start a brand new completion
  " The side effect, that in the beginning of line <C-n> and <C-p> inserts a
  " <Tab>, but I hope it may not be a problem...
  ino <C-n> <C-R>=<SID>SuperTab('n')<CR>
  ino <C-p> <C-R>=<SID>SuperTab('p')<CR>
" }}}

" Command Mappings {{{
  if !exists(":SuperTabHelp")
    command SuperTabHelp :call <SID>SuperTabHelp()
  endif
" }}}

call <SID>Init()

endif

" vim:ft=vim:fdm=marker
