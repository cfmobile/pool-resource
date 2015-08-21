#!/bin/sh

set -e

source $(dirname $0)/helpers.sh

it_can_check_from_head() {
  local repo=$(init_repo)
  local ref=$(make_commit_to_file $repo my_pool/unclaimed/file-a)

  check_uri $repo | jq -e "
    . == [{ref: $(echo $ref | jq -R .)}]
  "
}

it_can_check_from_a_ref() {
  local repo=$(init_repo)
  local ref1=$(make_commit_to_file $repo my_pool/unclaimed/file-a)
  local ref2=$(make_commit_to_file $repo my_pool/unclaimed/file-b)
  local ref3=$(make_commit_to_file $repo my_pool/unclaimed/file-c)

  check_uri_from $repo $ref1 | jq -e "
    . == [
      {ref: $(echo $ref2 | jq -R .)},
      {ref: $(echo $ref3 | jq -R .)}
    ]
  "
}

it_can_check_from_a_bogus_sha() {
  local repo=$(init_repo)
  local ref1=$(make_commit_to_file $repo my_pool/unclaimed/file-a)
  local ref2=$(make_commit_to_file $repo my_pool/unclaimed/file-b)

  check_uri_from $repo "bogus-ref" | jq -e "
    . == [{ref: $(echo $ref2 | jq -R .)}]
  "
}

it_checks_given_pool() {
  local repo=$(init_repo)
  local ref1=$(make_commit_to_file $repo my_pool/unclaimed/file-a)
  local ref2=$(make_commit_to_file $repo my_other_pool/unclaimed/file-b)
  local ref3=$(make_commit_to_file $repo my_pool/unclaimed/file-c)

  check_uri_paths $repo "my_other_pool" | jq -e "
    . == [{ref: $(echo $ref2 | jq -R .)}]
  "

  check_uri_paths $repo "my_pool" | jq -e "
    . == [{ref: $(echo $ref3 | jq -R .)}]
  "

  local ref4=$(make_commit_to_file $repo my_other_pool/unclaimed/file-d)

  check_uri_from_paths $repo $ref1 "my_pool" | jq -e "
    . == [{ref: $(echo $ref3 | jq -R .)}]
  "

  local ref5=$(make_commit_to_file $repo my_pool/claimed/file-e)

  check_uri_from_paths $repo $ref1 "my_pool" | jq -e "
    . == [
      {ref: $(echo $ref3 | jq -R .)}
    ]
  "
}

it_checks_given_pool_only_claimed() {
  local repo=$(init_repo)
  local ref1=$(make_commit_to_file $repo my_pool/claimed/file-a)
  local ref2=$(make_commit_to_file $repo my_other_pool/claimed/file-b)
  local ref3=$(make_commit_to_file $repo my_pool/claimed/file-c)

	echo $ref1
	echo $ref2
	echo $ref3
  check_uri_paths $repo "my_other_pool" | jq -e "
    . == []
  "

  check_uri_paths $repo "my_pool" | jq -e "
    . == []
  "

  local ref4=$(make_commit_to_file $repo my_other_pool/claimed/file-d)

  check_uri_from_paths $repo $ref1 "my_pool" | jq -e "
    . == []
  "

  local ref5=$(make_commit_to_file $repo my_pool/claimed/file-e)

  check_uri_from_paths $repo $ref1 "my_pool" | jq -e "
    . == []
  "
}

it_can_check_when_not_ff() {
  local repo=$(init_repo)
  local other_repo=$(init_repo)

  local ref1=$(make_commit_to_file $repo my_pool/unclaimed/file-a)
  local ref2=$(make_commit_to_file $repo my_pool/unclaimed/file-a)

  local ref3=$(make_commit_to_file $other_repo my_pool/unclaimed/file-a)

  check_uri $other_repo

  cd "$TMPDIR/git-resource-repo-cache"

  # do this so we get into a situation that git can't resolve by rebasing
  git config branch.autosetuprebase never

  # set my remote to be the other git repo
  git remote remove origin
  git remote add origin $repo/.git

  # fetch so we have master available to track
  git fetch

  # setup tracking for my branch
  git branch -u origin/master HEAD

  check_uri $other_repo | jq -e "
    . == [{ref: $(echo $ref2 | jq -R .)}]
  "
}


run it_can_check_from_head
run it_can_check_from_a_ref
run it_can_check_from_a_bogus_sha
run it_checks_given_pool
run it_can_check_when_not_ff
run it_checks_given_pool_only_claimed
