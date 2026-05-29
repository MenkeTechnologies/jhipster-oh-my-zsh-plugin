#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: jhipster.plugin.zsh alias + function contract pins.
#####          The plugin is pure aliases over the jhipster CLI plus
#####          docker-compose stack ops. Tests pin the surface so a
#####          regen or oh-my-zsh upstream sync does not silently
#####          drop / rename any.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/jhipster.plugin.zsh"
}

@test 'oh-my-zsh entry point is a symlink to jhipster.plugin.zsh' {
    # Pin: oh-my-zsh sources <plugin>.plugin.zsh by convention; this
    # repo's directory name is jhipster-oh-my-zsh-plugin so the entry
    # MUST be a symlink (or copy) to keep oh-my-zsh + zinit + antigen
    # users happy. Compare via md5 since same_as on multi-kilobyte
    # bodies is fragile under zunit.
    local link="$pluginDir/jhipster-oh-my-zsh-plugin.plugin.zsh"
    assert "$link" is_file
    local a b
    a=$(md5 -q "$link" 2>/dev/null || md5sum "$link" | awk '{print $1}')
    b=$(md5 -q "$pluginFile" 2>/dev/null || md5sum "$pluginFile" | awk '{print $1}')
    assert "$a" same_as "$b"
}

@test 'jh is the canonical 2-char shortcut for jhipster' {
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jh
    ")
    assert "$body" same_as "jh=jhipster"
}

@test 'jhskip carries --skip-install AND --skip-checks (both must stay)' {
    # Pin: dropping either flag silently changes generator behaviour —
    # --skip-install alone still runs version compat checks that fail
    # on cold clones; --skip-checks alone still tries to npm install.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhskip
    ")
    assert "$body" contains '--skip-install'
    assert "$body" contains '--skip-checks'
}

@test 'jhfe is --force --with-entities (regen-with-entities shortcut)' {
    # Pin: the most common destructive shortcut. --force without
    # --with-entities skips the entity files; --with-entities without
    # --force prompts on every conflict.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhfe
    ")
    assert "$body" contains '--force'
    assert "$body" contains '--with-entities'
}

@test 'jhyarn forces yarn install (NOT npm) — wire flag' {
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhyarn
    ")
    assert "$body" same_as "jhyarn='jhipster --yarn'"
}

@test 'jhlink is npm link generator-jhipster (the canonical dev-link)' {
    # Pin: the only alias that intentionally bypasses `jhipster` to
    # call npm directly. If a refactor sends it through jhipster, dev
    # workflow breaks.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhlink
    ")
    assert "$body" same_as "jhlink='npm link generator-jhipster'"
}

@test 'jhupgrade is jhipster upgrade (the version-migration subcommand)' {
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhupgrade
    ")
    assert "$body" same_as "jhupgrade='jhipster upgrade'"
}

@test 'jhjdl is jhipster import-jdl (the schema-import path, NOT export)' {
    # Pin: jdl/jhipster has both import-jdl and export-jdl; jhjdl must
    # stay on import (the destructive path).
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhjdl
    ")
    assert "$body" same_as "jhjdl='jhipster import-jdl'"
}

@test 'jhcontroller is jhipster spring-controller (NOT jhipster controller)' {
    # Pin: the actual generator name is spring-controller; a refactor
    # that drops the prefix would silently fail with "unknown command".
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhcontroller
    ")
    assert "$body" contains 'jhipster spring-controller'
}

@test 'blueprint aliases route through --blueprint (NOT --generator)' {
    # Pin: --blueprint is the post-v6 mechanism; --generator is dead.
    local kot vue
    kot=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhkot
    ")
    vue=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhvue
    ")
    assert "$kot" contains '--blueprint kotlin'
    assert "$vue" contains '--blueprint vuejs'
}

@test 'docker-compose stack-up family lives under src/main/docker/*.yml' {
    # Pin: the path src/main/docker/ is JHipster's canonical layout.
    # If a refactor flips to docker/ root or src/docker/, every stack
    # alias breaks silently with `no such file`.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhmysqlup
    ")
    assert "$body" contains 'src/main/docker/mysql.yml'
    assert "$body" contains 'up -d'
}

@test 'docker-compose stack-down family uses bare `down` (no -v / no --rmi)' {
    # Pin: `down` alone preserves volumes; `down -v` would wipe the DB.
    # A regen that adds -v silently is catastrophic.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhpostgresqldown
    ")
    assert "$body" contains 'docker-compose'
    assert "$body" contains 'postgresql.yml'
    assert "$body" contains ' down'
    # negative pin
    [[ "$body" != *"-v"* ]]
    assert $? equals 0
}

@test 'jh*logs aliases use --follow (NOT --tail) for live tailing' {
    # Pin: --follow streams forever; --tail N grabs and exits.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias jhkafkalogs
    ")
    assert "$body" contains 'kafka.yml'
    assert "$body" contains 'logs --follow'
}

@test 'jhinstall function dispatches on gulpfile.js vs tsconfig.json' {
    # Pin: the dispatch keys are the JHipster v3 (gulp) vs v4+
    # (TypeScript) project markers. Renaming either marker silently
    # routes both eras to the wrong install path.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'jhinstall()'
    assert "$body" contains 'gulpfile.js'
    assert "$body" contains 'tsconfig.json'
    assert "$body" contains 'npm install && bower install && gulp install'
}

@test 'maven/gradle dispatch checks mvnw vs gradlew (NOT pom.xml vs build.gradle)' {
    # Pin: the wrappers (mvnw / gradlew) are the source of truth for
    # the chosen build tool — checking pom.xml/build.gradle is wrong
    # in JHipster monorepos with mixed modules.
    local body
    body=$(cat "$pluginFile")
    for fn in jhclean jhsonar jhrun jhpack jhdock; do
        assert "$body" contains "$fn()"
    done
    assert "$body" contains 'mvnw'
    assert "$body" contains 'gradlew'
}

@test 'jhrun routes to mvnw spring-boot:run (NOT mvn nor ./mvn — wrappers only)' {
    # Pin: spring-boot:run starts the in-place dev server; `mvn run`
    # is wrong. ./mvnw is mandatory — keeps version pinned via wrapper.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains './mvnw spring-boot:run'
    assert "$body" contains './gradlew bootRun'
}

@test 'jhpack uses -Pprod for both maven and gradle (production profile)' {
    # Pin: omitting -Pprod produces a dev-mode jar that boots into
    # H2 + ng serve — useless for deployment.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains './mvnw -Pprod verify'
    assert "$body" contains './gradlew -Pprod bootJar'
}

@test 'jhdock builds with jib (NOT docker build) for the container image' {
    # Pin: jib is the JHipster-blessed builder — produces image without
    # needing a local Docker daemon. `docker build` would fail in CI.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'jib:dockerBuild'
    assert "$body" contains 'jibDockerBuild'
}

@test 'gradle functions stay --no-daemon (test/CI environments)' {
    # Pin: --no-daemon is critical in CI; daemon leaks RAM and confuses
    # process supervisors. JHipster's recommended pattern.
    local body
    body=$(cat "$pluginFile")
    local count
    count=$(printf '%s\n' "$body" | grep -c -- '--no-daemon')
    local result=$([[ "$count" -ge 4 ]] && echo yes || echo "no:$count")
    assert "$result" same_as 'yes'
}

@test 'jhgatling targets src/test/gatling/user-files/simulations (the JHipster default)' {
    # Pin: hardcoded path matches what JHipster's generator emits.
    # Refactor to test/gatling/ would silently fail with "no scenarios".
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'gatling -sf src/test/gatling/user-files/simulations'
}

@test 'docker-compose database stack covers MySQL + MariaDB + PostgreSQL + Mongo + Cassandra + Couchbase' {
    # Pin: catastrophic-shrink guard — JHipster supports all six DBs
    # via docker-compose, this plugin must continue to alias all of them.
    local body
    body=$(cat "$pluginFile")
    for db in mysql mariadb postgresql mongodb cassandra couchbase; do
        # at least the up alias must exist for each
        printf '%s\n' "$body" | grep -q "docker-compose -f src/main/docker/$db.yml up -d"
        assert $? equals 0
    done
}

@test 'platform-cloud aliases cover all 5 JHipster targets (cf/heroku/k8s/aws/openshift)' {
    # Pin: the cloud target set is part of the JHipster public surface.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'jhipster cloudfoundry'
    assert "$body" contains 'jhipster heroku'
    assert "$body" contains 'jhipster kubernetes'
    assert "$body" contains 'jhipster aws'
    assert "$body" contains 'jhipster openshift'
}

@test 'plugin registers >55 jh* aliases total' {
    # Floor count — current is 60-ish. If a refactor drops below 55
    # somebody almost certainly removed a stack family by accident.
    local count
    count=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias | grep -cE '^jh[a-zA-Z]*='
    ")
    local result=$([[ "$count" -ge 55 ]] && echo yes || echo "no:$count")
    assert "$result" same_as 'yes'
}

@test 're-sourcing is idempotent (alias count stable)' {
    local first second
    first=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        alias | grep -cE '^jh'
    ")
    second=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        source '$pluginFile'
        alias | grep -cE '^jh'
    ")
    assert "$first" same_as "$second"
}
