func! pivotaltracker#complete(findstart, base) abort
    if a:findstart
        let l:line = getline('.')
        let l:start = col('.') - 1
        while l:start > 0 && l:line[l:start - 1] isnot# '#'
            let l:start -= 1
        endwhile

        return l:start
    endif

    return pivotaltracker#fetch()
endfunc

func! pivotaltracker#fetch() abort
    if $PT_TOKEN is# '' || $PT_ID is# ''
        echohl WarningMsg
        echom 'No Pivotal Tracker config'
        echohl NONE

        return
    endif

    let l:stop = v:false
    let l:raw = ''
    func! Append(id, data, type) closure abort
        let l:raw .= join(a:data)
    endfunc
    func! Stop(...) closure abort
        let l:stop = s:parse(l:raw)
    endfunc

    let l:cmd = ['curl',
                \'-sf',
                \'-X', 'GET',
                \'-H', 'X-TrackerToken:'.$PT_TOKEN,
                \'https://www.pivotaltracker.com/services/v5/projects/'.$PT_ID.'/stories?fields=name&filter=-state:accepted%20-state:unscheduled']

    return s:parse(system(l:cmd))
endfunc

func! s:parse(raw) abort
    return map(json_decode(a:raw), function('s:build_result'))
endfunc

func! s:build_result(_, val) abort
    return {'word': a:val.id, 'abbr': '#'.a:val.id, 'menu': a:val.name}
endfunc
