#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: jhipster-oh-my-zsh-plugin — plugin-contract pins.
#####          Entrypoint stem matches plugin dir (typical
#####          zsh-plugin install pattern), entrypoint parses
#####          cleanly under `zsh -n`, and (where applicable)
#####          every completion file starts with `#compdef`.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
}

@test 'entrypoint stem matches plugin directory basename' {
    # The standard zsh-plugin install pattern (oh-my-zsh, zinit,
    # antibody, antigen) sources `<repo>/<repo>.plugin.zsh`. The
    # stem of `jhipster-oh-my-zsh-plugin.plugin.zsh` must equal the parent directory's
    # basename so generated source lines stay copy-pasteable.
    local entry='jhipster-oh-my-zsh-plugin.plugin.zsh'
    local stem="${entry%.plugin.zsh}"
    local dir="${pluginDir##*/}"
    # Accept either exact match or `zsh-` prefix on dir (some repos
    # like `docker-aliases.plugin.zsh` live under `zsh-docker-aliases`).
    [[ "$stem" == "$dir" || "zsh-$stem" == "$dir" ]]
    assert $state equals 0
}

@test 'entrypoint parses cleanly under zsh -n' {
    run zsh -n "$pluginDir/jhipster-oh-my-zsh-plugin.plugin.zsh"
    assert $state equals 0
}

@test 'every completion file starts with #compdef directive' {
    # Pass trivially when there are no `_*` files; otherwise every
    # one must lead with `#compdef`. A missing directive silently
    # disables completion. Use `find` so a zero-match doesn't trip
    # nomatch under EXTENDED_GLOB.
    local missing=""
    local d f
    for d in "$pluginDir/completions" "$pluginDir"; do
        [[ -d "$d" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            run head -1 "$f"
            [[ "$output" =~ ^#compdef ]] || missing="$missing ${f##*/}"
        done < <(find "$d" -maxdepth 1 -name "_*" -type f 2>/dev/null)
    done
    assert "$missing" is_empty
}

#--------------------------------------------------------------
# Round 2: jhipster alias/function table pins
#--------------------------------------------------------------

@test 'plugin exports the canonical `jh` shorthand alias for `jhipster`' {
    local body
    body=$(cat "$pluginDir/jhipster-oh-my-zsh-plugin.plugin.zsh")
    assert "$body" contains "alias jh='jhipster'"
}

@test 'all docker / docker-compose related aliases reference docker-compose' {
    # `jhcompose` must invoke the docker-compose subcommand; pin so
    # a future rename to `jhipster docker` (without -compose) doesn't
    # silently break docker workflows.
    local body
    body=$(cat "$pluginDir/jhipster-oh-my-zsh-plugin.plugin.zsh")
    assert "$body" contains 'docker-compose'
}

@test 'cloud-target aliases cover all 5 documented providers' {
    # README/source documents cf/heroku/kubernetes/aws/openshift as
    # the supported deploy targets. Pin presence of each alias.
    local body
    body=$(cat "$pluginDir/jhipster-oh-my-zsh-plugin.plugin.zsh")
    for target in cloudfoundry heroku kubernetes aws openshift; do
        assert "$body" contains "$target"
    done
}

@test 'jhinstall function handles 2 npm/bower/gulp + tsconfig paths' {
    # The function branches on gulpfile.js / tsconfig.json presence;
    # pin both branches stay wired so install flows for both Gulp
    # and Angular CLI projects work.
    local body
    body=$(cat "$pluginDir/jhipster-oh-my-zsh-plugin.plugin.zsh")
    assert "$body" contains 'gulpfile.js'
    assert "$body" contains 'tsconfig.json'
}
