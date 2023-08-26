#!/bin/bash

pr_title=""
pr_link=""
gitops_new_pr_id=""
source_branch_name=""
reviewer_uuids_json=""

function prepare_pr_metadata {
  _pr_commit_response=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$BITBUCKET_REPO_SLUG/commit/$BITBUCKET_COMMIT/pullrequests" \
    --request GET \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_SOURCE_ACCESS_TOKEN")

  _pr_id=$(echo "$_pr_commit_response" | jq -r ".values[0].id")

  _pr_detail_response=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$BITBUCKET_REPO_SLUG/pullrequests/$_pr_id" \
    --request GET \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_SOURCE_ACCESS_TOKEN")

  pr_title=$(echo "$_pr_detail_response" | jq -r ".title")
  pr_link=$(echo "$_pr_detail_response" | jq -r ".links.html.href")
}

function pulling_gitops_code {
  cd /tmp || exit
  git clone https://x-token-auth:"$GITOPS_ACCESS_TOKEN"@bitbucket.org/"$BITBUCKET_REPO_OWNER"/"$GITOPS_REPO".git

  # Switch to the specified destination branch (PR will be merged into this branch)
  cd /tmp/"$GITOPS_REPO" || exit
  git checkout "$GITOPS_DESTINATION_BRANCH"

  # Generate a short commit hash and construct a new branch name
  _short_commit_hash=$(git rev-parse --short HEAD | awk 'NF > 0')
  source_branch_name="$GITOPS_SOURCE_BRANCH_PREFIX/$_short_commit_hash"
  git checkout -b "$source_branch_name"

  # Update the 'tag' value in the 'waypoint.hcl' file with the commit hash
  sed -i -e "s|tag        = \".*\"|tag        = \"$_short_commit_hash\"|g" waypoint.hcl

  # Configure the GitOps bot user's email
  git config user.email "$GITOPS_BOT_EMAIL"

  # Push the changes forcefully to the remote repository
  git add .
  git commit -m "chore: $pr_title ($pr_link)"
  git push origin "$source_branch_name" -f
}

function convert_uuids_to_reviewers {
  # Split the input string by ";"
  IFS=';' read -ra uuids <<<"$BITBUCKET_REVIEWER_UUIDS"

  _json_array_uuids=()

  # Loop through each UUID and create the JSON object
  for uuid in "${uuids[@]}"; do
    _json_object="{ \"uuid\": \"$uuid\" }"
    _json_array_uuids+=("$_json_object")
  done

  # Convert the array to a JSON-formatted string
  reviewer_uuids_json="[ $(
    IFS=,
    echo "${_json_array_uuids[*]}"
  ) ]"
}

function create_new_pr {
  cat <<EOF | tee /tmp/json_payload.json
{
  "title": "chore: $pr_title ($pr_link)",
  "source": {
    "branch": {
      "name": "$source_branch_name"
    }
  },
  "destination": {
    "branch": {
      "name": "$GITOPS_DESTINATION_BRANCH"
    }
  },
  "summary": {
    "raw": "chore: $pr_title ($pr_link)"
  },
  "reviewers": $reviewer_uuids_json
}
EOF

  _new_pr_response=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$GITOPS_REPO/pullrequests" \
    --request POST \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_ACCESS_TOKEN" \
    --data @/tmp/json_payload.json)
  gitops_new_pr_id=$(echo "$_new_pr_response" | jq -r ".id")
}

function create_new_comment {
  cat <<EOF | tee /tmp/comment_json_payload.json
{
  "content": {
    "raw": "@{5bb1bc27535ae9205e1b5899} PTAL"
  }
}
EOF

  _new_pr_response=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$GITOPS_REPO/pullrequests/${gitops_new_pr_id}/comments" \
    --request POST \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_ACCESS_TOKEN" \
    --data @/tmp/comment_json_payload.json)
}

prepare_pr_metadata
pulling_gitops_code
convert_uuids_to_reviewers
create_new_pr
create_new_comment
