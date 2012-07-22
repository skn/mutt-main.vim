"source ~/.vimrc
:start

" mutt: insert attachment with ranger
fun! RangerMuttAttach()
    if filereadable('/tmp/chosendir')
        silent !ranger --choosefile=/tmp/chosenfiles --choosedir=/tmp/chosendir "$(cat /tmp/chosendir)"
    else
        silent !ranger --choosefile=/tmp/chosenfiles --choosedir=/tmp/chosendir
    endif   
    if filereadable('/tmp/chosenfiles')
        "call system('sed "s/\(.*\)/Attach: \1/" /tmp/chosenfiles > /tmp/muttattach')
        call system('sed "s/[[:space:]]/\\\ /g" /tmp/chosenfiles | sed "s/\(.*\)/Attach: \1/" > /tmp/muttattach')
        exec 'read /tmp/muttattach'
        call system('rm /tmp/chosenfiles /tmp/muttattach')
    endif
    redraw!
endfun
map <C-a> magg/Reply-To<CR><ESC>:call RangerMuttAttach()<CR>`a

" mutt attach
" fun! RangerMuttAttach()
"    silent !ranger --choosefile=/tmp/chosenfile
"    if filereadable('/tmp/chosenfile')
"      call system('sed "s/\(.*\)/Attach: \1/" /tmp/chosenfile > /tmp/muttattach')
"      exec 'read /tmp/muttattach'
"      call system('rm /tmp/chosenfile /tmp/muttattach')
"    endif
"    redraw!
"  endfun
"  map <C-a> magg/Reply-To<CR><ESC>:call RangerMuttAttach()<CR>`a



" Don't use modelines in e-mail messages, avoid trojan horses
setlocal nomodeline

" many people recommend keeping e-mail messages 72 chars wide
if &tw == 0
  setlocal tw=72
endif

" Set 'formatoptions' to break text lines and keep the comment leader ">".
setlocal fo+=tcql

set expandtab
set wrap
set nocindent
set background=dark
set nomodeline
set ruler
set ttyfast
set history=50
" set formatoptions=tcql

function MailStart()
" Remove old signatures
  nnoremap <buffer> <LocalLeader>qs :/^> \?-- $/,/^-- $/-d<Bar>noh<CR>
:endfunction

" Tip: Place the cursor in the optimal position, editing email messages.
" Author: Davide Alberani
" Version: 0.1
" Date: 24 May 2006
" Description: if you use Vim to edit your emails, having to manually
" move the cursor to the right position can be quite annoying.
" This command will place the cursor (and enter insert mode)
" in the more logical place: at the Subject header if it's
" empty or at the first line of the body (also taking
" care of the attribution, to handle replies messages).
" Usage: I like to call the Fip command by setting the command that is used
" by my mail reader (mutt) to execute Vim. E.g. in my muttrc I have:
" set editor="vim -c ':Fip'"
" Obviously you can prefer to call it using an autocmd:
" " Modify according to your needs and put this in your vimrc:
" au BufRead mutt* :Fip
" Hints: read the comments in the code and modify it according to your needs.
" Keywords: email, vim, edit, reply, attribution, subject, cursor, place.

" Function used to identify where to place the cursor, editing an email.
function! FirstInPost (...) range
" Remove old signatures
  nnoremap <buffer> <LocalLeader>qs :/^> \?-- $/,/^-- $/-d<Bar>noh<CR>

  let cur = a:firstline
  while cur <= a:lastline
    let str = getline(cur)
    " Found an _empty_ subject in the headers.
    " NOTE: you can put similar checks to handle other empty headers
    " like To, From, Newgroups, ...
    if str == 'Subject: '
      execute cur
      :start!
      break
    endif
    " We have reached the end of the headers.
    if str == ''
      let cur = cur + 1
      " If the first line of the body is an attribution, put
      " the cursor _after_ that line, otherwise the cursor is
      " leaved right after the headers (assuming we're writing
      " a new mail, and not editing a reply).
      " NOTE: modify the regexp to match your mail client's attribution!
      if strlen(matchstr(getline(cur), '^On.*wrote:.*')) > 0
        let cur = cur + 1
      endif
      execute cur
      :start
      break
    endif
    let cur = cur + 1
  endwhile
endfunction

" TIP NUMBER 1241
" Tip: beautifully rearrange quotes in email replies using the fmt command.
" Author: Davide Alberani <da @ erlug.linux.it>  http://erlug.linux.it/~da/
" Version: 0.1
" Date: 24 May 2006
" Description: editing email replies, I often end up cutting the quoted text
"              to leave only a short meaningful part, but many times this
"              will leave blocks of quoted lines with very heterogeneous
"              lengths - and this looks really bad; moreover sometimes the
"              sender is writing lines longer than 72 chars, and I want to
"              split it maintaining the original quote.
"              Calling the Vbq command you can rearrange isolated blocks
"              of quoted lines so that they will look _really_ good.
"              Every single block of quoted lines is stripped of its quote
"              and reformatted calling the 'fmt' unix program (I suppose you
"              can use any other similar tool) and then restored in place,
"              adding the quote again.
" Usage: I normally start editing my reply, removing the unnecessary quoted
"        text (without caring about leaving too long or too short quoted
"        lines) and then, after I've finished writing the reply, I call
"        the :Vbq command.
" Hints: read the comments in the code and modify it according to your needs.
" Warning: you need the fmt (or a similar filter) command installed.
" Keywords: quote, email, formatting, fmt.
" My VIM pages: http://erlug.linux.it/~da/vim/

" The function used to beautifully rearrange quoted lines.
function VeryBeautyQuote (...) range
  " The regular expression used to match quoted lines.
  " NOTE: modify this regexp if you have special needs.
  let re_quote = '^>\(\a\{-,3}[>|]\|[> \t|]\)\{,5}'
  set report=30000 " do not report the number of changed lines.
  let cur = a:firstline
  while cur <= a:lastline
     let str = getline(cur)
     " Match the quote.
     let comm = matchstr(str, re_quote)
     let newcomm = comm
     let commlen = strlen(comm)
     let filelen = line('$')
     if commlen > 0
       let startl = cur
       while newcomm == comm
         " Strip the quote from this group of quoted lines.
         let txt = substitute(str, re_quote, '', '')
         call setline(cur, txt)
         let cur = cur + 1
         let str = getline(cur)
         let newcomm = matchstr(str, re_quote)
       endwhile
       let cur = cur - 1
       " Execute fmt for format the (un-)quoted lines.
       " NOTE: you can call any other formatter that act like a command line
       "       filter.
       " NOTE: 72 is the maximum length of a single line, including
       "       the length of the quote.
       execute startl . ',' . cur . '!fmt -' . (72 - commlen)
       " If the length of the file was changed, move the cursor accordingly.
       let lendiff = filelen - line('$')
       if lendiff != 0
         let cur = cur - lendiff
       endif
       " Restore the stripped quote.
       execute startl . ',' . cur . 's/^/' . comm . '/g'
     endif
   let cur = cur + 1
  endwhile
endfunction

" Execute this command to beautifully rearrange the quoted lines.
com Vbq :let strl = line('.')<Bar>:%call VeryBeautyQuote()<Bar>:exec strl


" Command to be called.
"com Fip :set tw=0<Bar>:%call FirstInPost()
com Fip :%call FirstInPost()

