#!/bin/bash

PR_COMMIT_RESPONSE=""
PR_ID=""
PR_DETAIL_RESPONSE=""

PR_TITLE=""
PR_LINK=""

SHORT_COMMIT_HASH=""

function prepare_pr_metadata {
  PR_COMMIT_RESPONSE=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$BITBUCKET_REPO_SLUG/commit/$BITBUCKET_COMMIT/pullrequests" \
    --request GET \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_SOURCE_ACCESS_TOKEN")

  PR_ID=$(echo "$PR_COMMIT_RESPONSE" | jq -r ".values[0].id")

  PR_DETAIL_RESPONSE=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$BITBUCKET_REPO_SLUG/pullrequests/$PR_ID" \
    --request GET \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_SOURCE_ACCESS_TOKEN")

  PR_TITLE=$(echo "$PR_DETAIL_RESPONSE" | jq -r ".title")
  PR_LINK=$(echo "$PR_DETAIL_RESPONSE" | jq -r ".links.html.href")
}

function pulling_gitops_code {
  cd /tmp || exit
  git clone https://x-token-auth:"$GITOPS_ACCESS_TOKEN"@bitbucket.org/est-rouge/"$GITOPS_REPO".git
  cd /tmp/"$GITOPS_REPO" || exit
  git checkout develop
  SHORT_COMMIT_HASH=$(git rev-parse --short HEAD | awk 'NF > 0')
  BRANCH_NAME="release/$SHORT_COMMIT_HASH"
  git checkout -b "$BRANCH_NAME"
  sed -i -e "s|tag        = \".*\"|tag        = \"$SHORT_COMMIT_HASH\"|g" waypoint.hcl
  git config user.email "$GITOPS_BOT_EMAIL"
  git add .
  git commit -m "chore: $PR_TITLE ($PR_LINK)"
  git push origin "$BRANCH_NAME" -f
}

function create_new_pr {
  cat <<EOF | tee /tmp/json_payload.json
{
  "title": "chore: $PR_TITLE ($PR_LINK)",
  "source": {
    "branch": {
      "name": "$BRANCH_NAME"
    }
  },
  "destination": {
    "branch": {
      "name": "develop"
    }
  },
  "summary": {
    "raw": "chore: $PR_TITLE ($PR_LINK)"
  },
  "reviewers": [
    {
      "uuid": "{7ff3a816-c6c7-4cd7-8133-fdf7f285ab62}"
    }
  ]
}
EOF

  NEW_PR_RESPONSE=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$GITOPS_REPO/pullrequests" \
    --request POST \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_ACCESS_TOKEN" \
    --data @/tmp/json_payload.json)
  NEW_PR_ID=$(echo "$NEW_PR_RESPONSE" | jq -r ".id")
}

function create_new_comment {
  cat <<EOF | tee /tmp/comment_json_payload.json
{
  "content": {
    "raw": "@{5bb1bc27535ae9205e1b5899} PTAL"
  }
}
EOF

  NEW_PR_RESPONSE=$(curl "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$GITOPS_REPO/pullrequests/${NEW_PR_ID}/comments" \
    --request POST \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $GITOPS_ACCESS_TOKEN" \
    --data @/tmp/comment_json_payload.json)
}

prepare_pr_metadata
pulling_gitops_code
create_new_pr
create_new_comment
