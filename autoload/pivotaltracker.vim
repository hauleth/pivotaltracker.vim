let s:cache = []

func! pivotaltracker#build_cache() abort
    let s:cache = s:fetch()

    if exists('s:timer')
        call timer_stop(s:timer)

        silent! unlet! s:timer
    endif
endfunc

func! pivotaltracker#clear_cache(...) abort
    silent! unlet! s:timer

    let s:cache = []
endfunc

func! pivotaltracker#complete(findstart, base) abort
    if a:findstart
        let l:line = getline('.')
        let l:start = col('.') - 1
        while l:start > 0 && l:line[l:start - 1] isnot# '#'
            let l:start -= 1
        endwhile

        return l:start
    endif

    if empty(s:cache)
        call pivotaltracker#build_cache()

        " Defaults to 1 minute
        let l:delay = get(g:, 'pivotaltracker_cache_ttl', 60 * 1000)

        " Clear cache after 1 minute
        "
        " This should provide enough time for finishing completion, but at the
        " same time this will prevent stale stories from being visible in
        " completions
        let s:timer = timer_start(l:delay, function('pivotaltracker#clear_cache'))
    endif

    return filter(copy(s:cache), function('s:filter', [a:base]))
endfunc

func! s:filter(base, _, value) abort
    let l:pattern = '^'.a:base

    return a:value.word =~? l:pattern || a:value.menu =~? l:pattern
endfunc

func! s:fetch() abort
    let l:pt_token = get(g:, 'pivotaltracker_token', $PT_TOKEN)
    let l:pt_id = get(g:, 'pivotaltracker_id', $PT_ID)

    let l:mywork = get(g:, 'pivotaltracker_name')
    let l:filter = get(g:, 'pivotaltracker_filter', '-state:accepted -state:unscheduled')

    if l:mywork
        let l:filter .= ' mywork:'.l:mywork
    endif

    if l:pt_token is# '' || l:pt_id is# ''
        echoerr 'No Pivotal Tracker config'

        return []
    endif

    let l:cmd = ['curl',
                \'-sfG',
                \'-X', 'GET',
                \'-H', 'X-TrackerToken:'.l:pt_token,
                \'--data-urlencode', 'filter='.l:filter,
                \'--data-urlencode', 'fields=name',
                \'https://www.pivotaltracker.com/services/v5/projects/'.l:pt_id.'/stories']

    return s:parse(system(l:cmd))
endfunc

func! s:parse(raw) abort
    return map(json_decode(a:raw), function('s:build_result'))
endfunc

func! s:build_result(_, val) abort
    return {'word': a:val.id, 'abbr': '#'.a:val.id, 'menu': a:val.name}
endfunc
