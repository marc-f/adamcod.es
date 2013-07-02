#!/usr/bin/env bash

currbranch="$(grep "^*" < <(git branch) | cut -d' ' -f2)"
if [[ $currbranch == "master" ]]; then # we should generate the site
    # go to root dir of the repo
    cd "$(git rev-parse --show-toplevel)"

    site="$("mktemp" -d /tmp/_site.XXXXXXXXX)"

    # generate the site
    jekyll build -d $site

    # add any new files
    git add -A

    # commit all changes with a default message
    git commit -a -m "updated cache @ $(date +"%F %T")"

    # switch to branch the site will be stored
    git checkout gh-pages

    # overwrite existing files
    builtin shopt -s dotglob
    cp -rf "$site"/* .
    builtin shopt -u dotglob

    # add any new files
    git status

    # add any new files
    git add -A

    # commit all changes with a default message
    git commit -a -m "updated site @ $(date +"%F %T")"

    # push changes to github
    git push origin gh-pages

    # cleanup
    rm -rfv "$site"

    # return
    git checkout master
fi
