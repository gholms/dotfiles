scriptencoding utf-8

" ============================================================================
" Vim plugin for creating/editing RPM spec files
" Last Change: 2016 Dec 18
" Maintainer: Filip Szymański <fszymanski at, fedoraproject.org>
" License: Use of this source code is governed by an MIT license that can be
"          found in the LICENSE file.
" ============================================================================

if exists('b:did_ftplugin') || &compatible
    finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let g:spec_fullname                 = get(g:, 'spec_fullname', spec#GetFullname())
let g:spec_email_address            = get(g:, 'spec_email_address', spec#GetEmailAddress())
let g:spec_changelog_use_utc        = get(g:, 'spec_changelog_use_utc', 1)
" https://fedoraproject.org/wiki/Packaging:Guidelines#Changelogs
let g:spec_changelog_format         = get(g:, 'spec_changelog_format', 'normal')
let g:spec_changelog_item_prepend   = get(g:, 'spec_changelog_item_prepend', 0)
let g:spec_add_changelog_entry_map  = get(g:, 'spec_add_changelog_entry_map', '<LocalLeader>c')
let g:spec_increase_release_tag_map = get(g:, 'spec_increase_release_tag_map', '<LocalLeader>r')
let g:spec_rpm_build_args           = get(g:, 'spec_rpm_build_args', '-ba')
let g:spec_rpm_build_async          = get(g:, 'spec_rpm_build_async', 1)
let g:spec_build_rpm_package_map    = get(g:, 'spec_build_rpm_package_map', '<LocalLeader>b')
let g:spec_folding                  = get(g:, 'spec_folding', 0)

if has('folding') && g:spec_folding
    setlocal foldmethod=expr
    setlocal foldexpr=spec#FoldExpr()
    setlocal foldtext=spec#FoldText()

    call spec#util#SetUndoFtplugin('setlocal foldmethod< foldexpr< foldtext<')
endif

if !exists('no_plugin_maps') && !exists('no_spec_maps')
    if !hasmapto('<Plug>SpecAddchangelogentry')
        execute 'nmap <silent> <buffer> ' . g:spec_add_changelog_entry_map . ' <Plug>SpecAddchangelogentry'
    endif
    nnoremap <silent> <buffer> <Plug>SpecAddchangelogentry :call <SID>AddChangelogEntry()<CR>

    if !hasmapto('<Plug>SpecIncreasereleasetag')
        execute 'nmap <silent> <buffer> ' . g:spec_increase_release_tag_map . ' <Plug>SpecIncreasereleasetag'
    endif
    nnoremap <silent> <buffer> <Plug>SpecIncreasereleasetag :call <SID>IncreaseReleaseTag()<CR>

    if !hasmapto('<Plug>SpecBuildrpmpackage')
        execute 'nmap <silent> <buffer> ' . g:spec_build_rpm_package_map . ' <Plug>SpecBuildrpmpackage'
    endif
    nnoremap <silent> <buffer> <Plug>SpecBuildrpmpackage :call <SID>BuildRpmPackage()<CR>

    call spec#util#SetUndoFtplugin('silent! nunmap <buffer> ' . g:spec_add_changelog_entry_map .
        \ '|silent! nunmap <buffer> ' . g:spec_increase_release_tag_map .
        \ '|silent! nunmap <buffer> ' . g:spec_build_rpm_package_map)
endif

if !exists(':Rpmbuild')
    command -buffer -nargs=1 Rpmbuild call <SID>BuildRpmPackage(<q-args>)

    call spec#util#SetUndoFtplugin('silent! delcommand Rpmbuild')
endif

if !exists('*s:AddChangelogEntry')
    function s:AddChangelogEntry() abort " {{{
        let l:version = ''
        let l:release = ''
        let l:epoch = ''
        let l:changelog_lnum = 0

        let l:lnum = 1
        while l:lnum <= line('$')
            let l:line = getline(l:lnum)
            if l:line =~? '\v^Version\s*:\s*[^[:blank:]]+'
                let l:version = spec#GetTagValue(l:line)
            elseif l:line =~? '\v^Release\s*:\s*[^[:blank:]]+'
                let l:release = spec#GetTagValue(substitute(l:line, '\v\%\{\?dist\}', '', ''))
            elseif l:line =~? '\v^Epoch\s*:\s*[^[:blank:]]+'
                let l:epoch = spec#GetTagValue(l:line)
            elseif (l:line =~? '\v^Serial\s*:\s*[^[:blank:]]+') && empty(l:epoch)
                let l:epoch = spec#GetTagValue(l:line)
            elseif l:line =~? '\v^\%changelog'
                let l:changelog_lnum = l:lnum
                call cursor(l:lnum, 1)
                break
            endif

            let l:lnum += 1
        endwhile

        if !l:changelog_lnum
            let l:choice = confirm('Cannot find %changelog section. Create one?',
                \ "&End of file\n&Here\n&Cancel", 1, 'Question')
            if l:choice == 1
                call append(line('$'), ['', '%changelog'])
                call cursor(line('$'), 1)
            elseif l:choice == 2
                execute "normal! gI%changelog\<Esc>0"
                call append(line('.'), '')
            else
                return
            endif

            let l:changelog_lnum = line('.')
        endif

        if !empty(l:epoch)
            let l:epoch .= ':'
        endif

        if empty(l:version)
            let l:version = input('Please enter package version (default: 1.0): ', '1.0')
        endif

        if empty(l:release)
            let l:release = input('Please enter package release (default: 1): ', '1')
        endif

        let l:header = ['* ' . spec#GetDate() . ' ' . g:spec_fullname . ' <' . g:spec_email_address . '>']
        let l:evr = l:epoch . l:version . '-' . l:release
        if g:spec_changelog_format ==# 'nodash'
            let l:header = map(l:header, 'v:val . " " . l:evr')
        elseif g:spec_changelog_format ==# 'multiline'
            call add(l:header, '- ' . l:evr)
        else  " normal
            let l:header = map(l:header, 'v:val . " - " . l:evr')
        endif

        let l:latest_entry_lnum = search('\v^\*.*', 'W')
        if l:latest_entry_lnum
            if join(l:header, "\n") ==# (g:spec_changelog_format ==# 'multiline'
                    \ ? join(getline(l:latest_entry_lnum, l:latest_entry_lnum + 1), "\n")
                    \ : getline(l:latest_entry_lnum))
                call spec#AddChangelogEntryItem()
                return
            endif
        endif

        call append(l:changelog_lnum, l:header)
        call cursor(l:changelog_lnum +  1, 1)
        call spec#AddChangelogEntryItem()
    endfunction " }}}
endif

if !exists('*s:IncreaseReleaseTag')
    function s:IncreaseReleaseTag() abort " {{{
        " https://fedoraproject.org/wiki/Packaging:NamingGuidelines#Release_Tag
        let l:release_patterns = {
            \ 'minor':    '\v^(Release\s*:\s*[^[:blank:]]+\%\{\?dist\}\.)(\d+)\s*',
            \ 'final':    '\v^(Release\s*:\s*)(\d+)(\%\{\?dist\})\s*',
            \ 'pre_post': '\v^(Release\s*:\s*%(0\.)?)(\d+)(\.[%:?_{}[:alnum:]]+\%\{\?dist\})\s*'
            \ }

        let l:release_lnum = search('\v^Release\s*:\s*[^[:blank:]]+', 'w')
        if l:release_lnum
            let l:release_line = getline(l:release_lnum)
            if l:release_line =~? l:release_patterns['minor']
                let l:release_line = substitute(l:release_line, l:release_patterns['minor'],
                    \ '\=join([submatch(1), submatch(2) + 1], "")', '')
            elseif l:release_line =~? l:release_patterns['final']
                let l:release_line = substitute(l:release_line, l:release_patterns['final'],
                    \ '\=join([submatch(1), submatch(2) + 1, submatch(3)], "")', '')
            elseif l:release_line =~? l:release_patterns['pre_post']
                let l:release_line = substitute(l:release_line, l:release_patterns['pre_post'],
                    \ '\=join([submatch(1), submatch(2) + 1, submatch(3)], "")', '')
            else
                call spec#util#Error('Cannot increase release tag')
                return
            endif

            call append(l:release_lnum, l:release_line)
            execute 'normal! "_dd'
        endif
    endfunction " }}}
endif

if !exists('*s:BuildRpmPackage')
    function s:BuildRpmPackage(...) abort " {{{
        if getbufvar(bufnr('%'), '&modified')
            if confirm('Spec file has been modified. Save it?', "&Yes\n&No", 1, 'Question') == 1
                try
                    noautocmd write
                catch /\vE%(190|212)/
                    call spec#util#Error('Cannot save spec file')
                    return
                endtry
            endif
        endif

        if executable('rpmbuild')
            " FIXME: Package signing at build-time does not work in Vim
            let l:args = a:0 >= 1 ? a:1 : g:spec_rpm_build_args
            let l:command = 'rpmbuild ' . l:args . ' ' . expand('%:p:S')
            if g:spec_rpm_build_async && spec#rpm#IsAsyncAvailable()
                call spec#rpm#AsyncBuild(['/bin/sh', '-c', l:command])
            else
                call spec#rpm#Build(l:command)
            endif
        else
            call spec#util#Error('Cannot find rpmbuild binary')
        endif
    endfunction " }}}
endif

" Use the `matchit` plugin for easy navigation between the sepc file sections
" and triggers
" http://www.vim.org/scripts/script.php?script_id=39
if exists('loaded_matchit')
    let b:match_ignorecase = 0
    " From RPM 4.13.0-rc1 source, file build/parseSpec.c, partList[]
    let b:match_words = '^Name\s*\::^%package:^%prep:^%build:^%install:^%check:' .
        \ '^%clean:^%preun:^%postun:^%pretrans:^%posttrans:^%pre:^%post:' .
        \ '^%files:^%description:^%triggerpostun:^%triggerprein:^%triggerun:' .
        \ '^%triggerin:^%trigger:^%verifyscript:^%sepolicy:^%filetriggerin:' .
        \ '^%filetrigger:^%filetriggerun:^%filetriggerpostun:^%transfiletriggerin:' .
        \ '^%transfiletrigger:^%transfiletriggerun:^%transfiletriggerpostun:' .
        \ '^%end\>:^%changelog'

    call spec#util#SetUndoFtplugin('unlet! b:match_ignorecase b:match_words')
endif

if has('gui_running') && !exists('b:browsefilter')
    let b:browsefilter = "RPM Spec Files\t*.spec\nAll Files\t*\n"

    call spec#util#SetUndoFtplugin('unlet! b:browsefilter')
endif

augroup spec_menu
    autocmd!
    autocmd BufEnter *
        \ if &filetype ==# 'spec' |
        \     nnoremenu <silent> S&pec.&Add\ Changelog\ Entry\.\.\. :call <SID>AddChangelogEntry()<CR> |
        \     nnoremenu <silent> S&pec.&Increase\ Release\ Tag :call <SID>IncreaseReleaseTag()<CR> |
        \     nnoremenu <silent> S&pec.-Sep1- : |
        \     nnoremenu <silent> S&pec.&Build\ RPM\ Package(s) :call <SID>BuildRpmPackage()<CR> |
        \     nnoremenu <silent> S&pec.-Sep2- : |
        \     nnoremenu <silent> S&pec.Ab&out :echo 'vim-spec version 0.9' .
        \         ' by Filip Szymański <fszymanski at, fedoraproject.org>'<CR> |
        \ endif
    autocmd BufLeave * if &filetype ==# 'spec' | silent! aunmenu Spec | endif
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: fenc=utf-8 ts=8 et sw=4 sts=4 fdm=marker
