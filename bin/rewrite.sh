#!/bin/sh

##
#
#
##

echo "This has the solution, but needs some love"

exit 0;

old_email="ernesto@mugo.ca"
correct_email="neto.buenrostro@gmail.com"
name="Ernesto Buenrostro"
filter=$(cat <<eos
if [ "\$GIT_COMMITTER_EMAIL" = "${old_email}" ]; then
    export GIT_COMMITTER_NAME="${name}"
    export GIT_COMMITTER_EMAIL="${correct_email}"
fi
if [ "\$GIT_AUTHOR_EMAIL" = "${old_email}" ]; then
    export GIT_AUTHOR_NAME="${name}"
    export GIT_AUTHOR_EMAIL="${correct_email}"
fi
eos
)

# echo "${filter}"
# change-commits = "!f() { VAR=$1; OLD=$2; NEW=$3; shift 3; git filter-branch --env-filter \"if [[ \\\"$`echo $VAR`\\\" = '$OLD' ]]; then export $VAR='$NEW'; fi\" $@; }; f "
echo "git filter-branch --env-filter '${filter}' --tag-name-filter cat -- --branches --tags $@"
git filter-branch --env-filter '${filter}' $@

# this works
git filter-branch -f --env-filter "
    GIT_AUTHOR_NAME='Ernesto Buenrostro'
    GIT_AUTHOR_EMAIL='neto.buenrostro@gmail.com'
    GIT_COMMITTER_NAME='Ernesto Buenrostro'
    GIT_COMMITTER_EMAIL='neto.buenrostro@gmail.com'
  " HEAD~5..HEAD