scriptencoding utf-8

" ============================================================================
" Vim plugin for creating/editing RPM spec files
" Last Change: 2016 Dec 17
" Maintainer: Filip Szymański <fszymanski at, fedoraproject.org>
" License: Use of this source code is governed by an MIT license that can be
"          found in the LICENSE file.
" ============================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

function! spec#util#SetUndoFtplugin(command) abort " {{{
    if exists('b:undo_ftplugin')
        let b:undo_ftplugin .= '|' . a:command
    else
        let b:undo_ftplugin = a:command
    endif
endfunction " }}}

function! spec#util#Error(message) abort " {{{
    echohl ErrorMsg
    echo 'vim-spec: ' . a:message
    echohl None
endfunction " }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: fenc=utf-8 ts=8 et sw=4 sts=4 fdm=marker
