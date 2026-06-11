#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: jhipster.plugin.zsh build-wrapper DISPATCH behaviour.
#####          jhclean/jhrun/jhpack/jhsonar/jhdock all branch on the
#####          presence of `mvnw` vs `gradlew` via `if [[ -a mvnw ]]
#####          … elif [[ -a gradlew ]]`. These tests exercise the
#####          actual runtime dispatch in an isolated temp project —
#####          NOT a grep of the body — so they catch:
#####            * branch-ORDER regressions (mvnw must win over gradlew),
#####            * the no-build-file INVARIANT (must be a silent no-op,
#####              never run a stray ./mvnw or ./gradlew),
#####            * the gradlew branch carrying `--no-daemon` (dropping it
#####              leaks a daemon into CI shells).
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/jhipster.plugin.zsh"

    # Build an isolated project dir, drop the requested executable build
    # wrappers (each echoes a unique marker + its args), source the
    # plugin, run $fn, and echo whatever wrapper got dispatched. Wrappers
    # live in the cwd because the functions invoke them as `./mvnw` /
    # `./gradlew`. Defined in @setup so each @test inherits it (zunit
    # does not expose file-scope functions to test bodies).
    _dispatch() {
        local fn="$1"; shift   # remaining args = wrapper names to create
        local tmp; tmp=$(mktemp -d)
        local w
        for w in "$@"; do
            print -r -- "#!/bin/sh"        >  "$tmp/$w"
            print -r -- "echo ${w}: \$*"   >> "$tmp/$w"
            chmod +x "$tmp/$w"
        done
        zsh -c "
            emulate zsh
            cd '$tmp' || exit 99
            source '$pluginFile'
            $fn
        "
        local rc=$?
        command rm -rf "$tmp"
        return $rc
    }
}

@test 'jhclean dispatches ./mvnw clean when only mvnw is present' {
    run _dispatch jhclean mvnw
    assert $state equals 0
    assert "$output" same_as 'mvnw: clean'
}

@test 'jhclean dispatches ./gradlew clean --no-daemon when only gradlew is present' {
    # `--no-daemon` must ride along — without it a gradle daemon
    # survives the build and pins JVM memory in long-lived CI shells.
    run _dispatch jhclean gradlew
    assert $state equals 0
    assert "$output" same_as 'gradlew: clean --no-daemon'
}

@test 'jhclean prefers mvnw over gradlew when BOTH wrappers exist' {
    # The if/elif order makes Maven win. A refactor that flips the
    # branches (or turns elif into a second if) would silently run the
    # Gradle path in a Maven project. Pin the precedence.
    run _dispatch jhclean mvnw gradlew
    assert $state equals 0
    assert "$output" same_as 'mvnw: clean'
}

@test 'jhrun is a silent no-op with neither mvnw nor gradlew present' {
    # INVARIANT: outside a JHipster project the wrappers must do
    # nothing and exit clean — never error, never dispatch a stray
    # build. A future `else` clause that fell through to a bare
    # `./mvnw`/`gradle` would break this.
    run _dispatch jhrun
    assert $state equals 0
    assert "$output" is_empty
}

@test 'jhpack selects the prod Maven verify, not the gradle bootJar, in a Maven project' {
    # jhpack must run `./mvnw -Pprod verify` for Maven; the Gradle
    # branch (`bootJar -Pprod`) is a different artifact path. Pin that
    # a Maven project never accidentally takes the Gradle branch.
    run _dispatch jhpack mvnw gradlew
    assert $state equals 0
    assert "$output" same_as 'mvnw: -Pprod verify'
}
