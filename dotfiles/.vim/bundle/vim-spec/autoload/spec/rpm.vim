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

" Keeps track of all running jobs
let s:jobs = {}

function! s:ShowOutput(output) abort " {{{
    if bufexists('__Rpmbuild__')
        let l:rpmbuild_winnr = bufwinnr('__Rpmbuild__')
        if l:rpmbuild_winnr == -1
            execute 'sbuffer ' . bufnr('__Rpmbuild__')
        else
            execute l:rpmbuild_winnr . 'wincmd w'
        endif

        execute 'normal! gg"_dG'
    else
        botright new __Rpmbuild__

        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal noswapfile

        nnoremap <silent> <buffer> q :quit<CR>
    endif

    call append(0, a:output)
    call append(line('$'), "Press 'q' to quit")
    normal! G
endfunction " }}}

function! spec#rpm#IsAsyncAvailable() abort " {{{
    return has('nvim') || (has('channel') && has('job'))
endfunction " }}}

function! s:GetChannelId(channel) abort " {{{
    return ch_info(a:channel)['id']
endfunction " }}}

function! s:JobStarted(id) abort " {{{
    let s:jobs[a:id] = {'output': []}
endfunction " }}}

function! s:JobFinished(id) abort " {{{
    if has_key(s:jobs, a:id)
        call remove(s:jobs, a:id)
    endif
endfunction " }}}

function! s:AccumulateJobOutput(id, line) abort " {{{
    if has('nvim')
        let s:jobs[a:id]['output'] += filter(a:line, '!empty(v:val)')
    else
        call add(s:jobs[a:id]['output'], a:line)
    endif
endfunction " }}}

function! s:GetJobOutput(id) abort " {{{
    if has_key(s:jobs, a:id)
        return s:jobs[a:id]['output']
    endif

    return ''
endfunction " }}}

function! spec#rpm#NeovimJobHandler(job_id, data, event) abort " {{{
      if (a:event ==# 'stdout') || (a:event ==# 'stderr')
          call s:AccumulateJobOutput(a:job_id, a:data)
      else  " exit
          call s:ShowOutput(s:GetJobOutput(a:job_id))
          call s:JobFinished(a:job_id)
      endif
endfunction " }}}

function! spec#rpm#VimJobHandler(channel, line) abort " {{{
    call s:AccumulateJobOutput(s:GetChannelId(a:channel), a:line)
endfunction " }}}

function! spec#rpm#VimJobCloseHandler(channel) abort " {{{
    let l:channel_id = s:GetChannelId(a:channel)
    call s:ShowOutput(s:GetJobOutput(l:channel_id))
    call s:JobFinished(l:channel_id)
endfunction " }}}

function! spec#rpm#AsyncBuild(command) abort " {{{
    if has('nvim')
        let l:job_id = jobstart(a:command, {
            \ 'on_stdout': 'spec#rpm#NeovimJobHandler',
            \ 'on_stderr': 'spec#rpm#NeovimJobHandler',
            \ 'on_exit':   'spec#rpm#NeovimJobHandler'
            \ })
        if l:job_id < 1
            throw 'Job failed to start'
        endif

        call s:JobStarted(l:job_id)
    else
        let l:job = job_start(a:command, {
            \ 'out_cb':   'spec#rpm#VimJobHandler',
            \ 'err_cb':   'spec#rpm#VimJobHandler',
            \ 'close_cb': 'spec#rpm#VimJobCloseHandler'
            \ })
        if job_status(l:job) ==# 'fail'
            throw 'Job failed to start'
        endif

        call s:JobStarted(s:GetChannelId(job_getchannel(l:job)))
    endif
endfunction " }}}

function! spec#rpm#Build(command) abort " {{{
    let l:output = split(system(a:command), "\n")
    call s:ShowOutput(l:output)
endfunction " }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: fenc=utf-8 ts=8 et sw=4 sts=4 fdm=marker
