"Author Mathew Yeates
"Based on gdbvim by Tomas Zellerin
let g:runargs=""

if exists("loaded_pdbvim")
	finish
endif

" If you dont have signs and clientserver, complain.
function Pdb_interf_init(fifo_name)
  echo "Can not use pdbvim plugin - your vim must have +signs and +clientserver features"
endfunction

if !(has("clientserver") && has("signs"))
  finish
endif

let loaded_pdbvim = 1
let s:having_partner=0

highlight DebugBreak guibg=darkred guifg=white ctermbg=darkred ctermfg=white
highlight DebugStop guibg=darkgreen guifg=white ctermbg=darkgreen ctermfg=white
sign define breakpoint linehl=DebugBreak
sign define current linehl=DebugStop

" Get ready for communication
function! Pdb_interf_init(fifo_name)
  echo 'Here'
  
  if s:having_partner " sanity check
    echo "Oops, one communication is already running"
    return
  endif
  let s:having_partner=1
  
  let s:fifo_name = a:fifo_name " Make use of parameters
"  execute "cd ". a:pwd

  if !exists("g:loaded_pdbvim_mappings")
    call s:Pdb_shortcuts()
  endif
  let g:loaded_pdbvim_mappings=1

  if !exists(":Pdb")
    command -nargs=+ Pdb	:call Pdb_command(<q-args>, v:count)
  endif

endfunction

function Pdb_interf_close()
	sign unplace *
	let s:having_partner=0
endfunction

function Pdb_Bpt(id, file, linenum)
	if !bufexists(a:file)
		execute "bad ".a:file
	endif
	execute "sign unplace ". a:id
	execute "sign place " .  a:id ." name=breakpoint line=".a:linenum." file=".a:file
endfunction

function Pdb_CurrFileLine(file, line)
        echo a:file
	if !bufexists(a:file)
		if !filereadable(a:file)
			return
		endif
		execute "e ".a:file
	else
	execute "b ".a:file
	endif
	let s:file=a:file
	execute "sign unplace ". 3
	execute "sign place " .  3 ." name=current line=".a:line." file=".a:file
	execute a:line
	:silent! foldopen!
endf
function Pdb_Done()
	sign unplace *
endfunction

noremap <unique> <script> <Plug>SetBreakpoint :call <SID>SetBreakpoint()<CR>

function Pdb_Run()
python << EOF
prompt="Enter run args "
runargs=vim.eval("g:runargs")
vim.command("let g:runargs=inputdialog" + "(\"" + prompt + "\"," + "\"" + runargs +   "\")")
runargs=vim.eval("g:runargs")

EOF
if (g:runargs!= "")
silent exec ":redir! >".s:fifo_name ."|echon \""."import mypdb;mypdb.run(\\\"".g:runargs."\\\")\n\"|redir END "
endif
endfunction
function Pdb_python()
python << EOF
prompt="Enter run args "
runargs=vim.eval("g:runargs")
vim.command("let g:runargs=inputdialog" + "(\"" + prompt + "\"," + "\"" + runargs +   "\")")
runargs=vim.eval("g:runargs")

EOF
if (g:runargs!= "")
silent exec ":redir! >".s:fifo_name ."|echon \"".g:runargs."\n\"|redir END "
endif

endfunction
function Pdb_command(cmd, ...)
  if match (a:cmd, '^\s*$') != -1
    return
  endif
  let suff=""
  if 0<a:0 && a:1!=0
    let suff=" ".a:1
  endif
  silent exec ":redir! >".s:fifo_name ."|echon \"".a:cmd.suff."\n\"|redir END "
  echo 
endfun



" Mappings are dependant on Leader at time of loading the macro.
function s:Pdb_shortcuts()
    nmap <unique> <C-F8> :call Pdb_command("break ".bufname("%").":".line("."))<CR>
    nmap <unique> <F2> :Pdb run<CR>
    nmap <unique> <F5> :<C-U>Pdb step<CR>
    nmap <unique> <F6> :<C-U>Pdb next<CR>
    nmap <unique> <F7> :Pdb finish<CR>
    nmap <unique> <F8> :<C-U>Pdb continue<CR>
    vmap <unique> <C-P> "gy:Pdb print <C-R>g<CR>
    nmap <unique> <C-P> :call Pdb_command("print ".expand("<cword>"))<CR> 
    nmenu Pdb.Execution.Run :call Pdb_Run()<CR>
    nmenu Pdb.Execution.Step :<C-U>Pdb step<CR>
    nmenu Pdb.Execution.Next :<C-U>Pdb next<CR>
    nmenu Pdb.Execution.Return :Pdb return<CR>
    nmenu Pdb.Execution.Continue :<C-U>Pdb cont<CR>
    nmenu Pdb.Execution.Quit :<C-U>Pdb q<CR>
    nmenu Pdb.Frame.Up :Pdb u<CR>
    nmenu Pdb.Frame.Down :Pdb d<CR>
    nmenu Pdb.Set\ break :call Pdb_command("b ".bufname("%").":".line("."))<CR>
    nmenu Pdb.-Sep- :
    nmenu Pdb.Command :<C-U>Pdb 
    nmenu Pdb.Python :call Pdb_python()<CR>

endfunction


" vim: set sw=2 ts=8 smarttab : "
