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

function! spec#FoldExpr() abort " {{{
    let l:fold_pattern = '\v^\%%(package|prep|build|install|check|clean' .
        \ '|%(pre|post)%(un|trans)?|files|changelog|description' .
        \ '|%(%(trans)?file)?trigger%(prein|postun|in|un)?|verifyscript' .
        \ '|sepolicy|end>)'

    if getline(v:lnum) =~? l:fold_pattern
        return '>1'
    endif

    return '='
endfunction " }}}

function! spec#FoldText() abort " {{{
    return foldtext() . ' '
endfunction " }}}

function! s:GetPackager() abort " {{{
    let l:groups = {}
    let l:packager_patterns = [
        \ [['name', 'email'], '\v(.*)\s+\<?(\S+\@[-.[:alnum:]]+)\>?'],
        \ [['email'],         '\v\<?(\S+\@[-.[:alnum:]]+)\>?'],
        \ [['name'],          '\v(.*)']
        \ ]

    let l:packager = executable('rpmdev-packager')
        \ ? system('rpmdev-packager')[:-2]
        \ : executable('rpm')
        \     ? system('rpm --eval="%packager"')[:-2]
        \     : ''
    if !empty(l:packager) && (l:packager !=# '%packager')
        for l:pattern in l:packager_patterns
            let l:match = matchlist(l:packager, l:pattern[1])
            if !empty(l:match)
                for l:group_name in l:pattern[0]
                    let l:groups[l:group_name] = l:match[index(l:pattern[0], l:group_name) + 1]
                endfor

                break
            endif
        endfor
    endif

    return l:groups
endfunction " }}}

function! spec#GetFullname() abort " {{{
    return get(s:GetPackager(), 'name', $USERNAME)
endfunction " }}}

function! spec#GetEmailAddress() abort " {{{
    return get(s:GetPackager(), 'email', hostname())
endfunction " }}}

function! spec#GetDate() abort " {{{
    if g:spec_changelog_use_utc
        return system('env LC_ALL=C date --utc +"%a %b %d %Y"')[:-2]
    endif

    let l:save_lang = v:lc_time
    language time C
    let l:date = strftime('%a %b %d %Y')
    execute 'language time ' . l:save_lang
    return l:date
endfunction " }}}

function! spec#GetTagValue(tag_line) abort " {{{
    let l:macro_pattern = '\v\%\{?(\w{3,})\}?'

    let l:tag_value = substitute(a:tag_line, '\v^\w+\s*:\s*([^[:blank:]]+)\s*', '\1', '')
    while l:tag_value =~? l:macro_pattern
        let l:macro = matchstr(l:tag_value, l:macro_pattern)
        let l:macro_name = substitute(l:macro, l:macro_pattern, '\1', '')
        let l:define_pattern = '\v^\%%(define|global)\s+' . l:macro_name . '\s+([^[:blank:]]+)\s*'
        let l:define_lnum = search(l:define_pattern, 'w')
        if !l:define_lnum
            call spec#util#Error('Cannot expand ' . l:macro . ' macro')
            return ''
        endif

        let l:macro_value = substitute(getline(l:define_lnum), l:define_pattern, '\1', '')
        let l:tag_value = substitute(l:tag_value, l:macro_pattern, l:macro_value, '')
    endwhile

    return l:tag_value
endfunction " }}}

function! spec#AddChangelogEntryItem() abort " {{{
    if g:spec_changelog_item_prepend
        let l:lnum = g:spec_changelog_format ==# 'multiline' ? line('.') + 1 : line('.')
        call append(l:lnum, '- ')
        call cursor(l:lnum + 1, 1)
    else
        let l:lnum = line('.') + 1
        while getline(l:lnum) !~? '\v^(\*.*|\s*)$'
            let l:lnum += 1
        endwhile

        call append(l:lnum - 1, '- ')
        call cursor(l:lnum, 1)
    endif

    if getline(line('.') + 1) =~? '\v^\*.*'
        call append(line('.'), '')
    endif

    startinser!
endfunction " }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: fenc=utf-8 ts=8 et sw=4 sts=4 fdm=marker
