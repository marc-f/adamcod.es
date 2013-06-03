#!/usr/bin/env bash

# git executable
git="git"

# site generation executable
generate="jekyll"
# options for the generator
opts=(--no-safe --no-server --no-auto --kramdown)

# branch from which to generate site
origbranch="master"

# branch holding the generated site
destbranch="gh-pages"

# directory holding the generated site -- should be outside this repo
site="$("mktemp" -d /tmp/_site.XXXXXXXXX)"

# the current branch
currbranch="$(grep "^*" < <("$git" branch) | cut -d' ' -f2)"

if [[ $currbranch == $origbranch ]]; then # we should generate the site
    # go to root dir of the repo
    cd "$("$git" rev-parse --show-toplevel)"

    # generate the site
    "$generate" ${opts[@]} . "$site"

    # add any new files
    "$git" add .

    # commit all changes with a default message
    "$git" commit -a -m "updated cache @ $(date +"%F %T")"

    # switch to branch the site will be stored
    "$git" checkout "$destbranch"

    # overwrite existing files
    builtin shopt -s dotglob
    cp -rf "$site"/* .
    builtin shopt -u dotglob

    # add any new files
    "$git" status

    # add any new files
    "$git" add .

    # commit all changes with a default message
    "$git" commit -a -m "updated site @ $(date +"%F %T")"

    # push changes to github
    "$git" push origin "$destbranch"

    # cleanup
    rm -rfv "$site"

    # return
    "$git" checkout "$origbranch"
fi
