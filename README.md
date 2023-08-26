# bitbucket-pr-bot

A job to promote a Pull Requests on GitOps repository

## How it works

On each run, the bot will:

1. Get the PR of the merged commit
2. Clone the GitOps repository
3. Promote the new PR in GitOps repository

## Usage

### Setup
1. [Create an application repository access token](https://support.atlassian.com/bitbucket-cloud/docs/repository-access-tokens/) with `pullrequest:read` scope
2. [Create a gitops repository access token](https://support.atlassian.com/bitbucket-cloud/docs/repository-access-tokens/) with `pullrequest:write` scope
3. Set the environment variables:
   - `GITOPS_SOURCE_ACCESS_TOKEN`: Bitbucket application repository in step 1
   - `GITOPS_ACCESS_TOKEN`: Bitbucket gitops repository in step 2
   - `GITOPS_BOT_EMAIL`: Bitbucket gitops repository email that is associated with the Access token created in step 2

### Run the bot with Docker
```bash
    docker run --rm \
      --env GITOPS_SOURCE_ACCESS_TOKEN \
      --env GITOPS_ACCESS_TOKEN \      
      --env GITOPS_BOT_EMAIL \      
      --env GITOPS_REPO \
      --env GITOPS_DESTINATION_BRANCH \
      --env GITOPS_SOURCE_BRANCH_PREFIX \
      --env BITBUCKET_COMMIT \
      --env BITBUCKET_REPO_OWNER \
      --env BITBUCKET_REPO_SLUG \
      --env BITBUCKET_REVIEWER_UUIDS \
      bitbucket-pr-bot:latest
```

- `GITOPS_DESTINATION_BRANCH`: The branch that PR will be merged and deployed to environments such as `main`, `master`, `develop`, `stg`, `qa`
- `GITOPS_SOURCE_BRANCH_PREFIX`: The prefix of the branch name that PR will be created from such as `qa` for testing, `stg` for staging, `release` for production
- `BITBUCKET_REVIEWER_UUIDS` The list of string UUID of reviewers separated by `;`. E.g `{7ff3a816-c6c7-4cd7-8133};{7ff3a816-c6c7-4cd7-8133}`

### Bitbucket Pipelines example

1. Add `GITOPS_SOURCE_ACCESS_TOKEN` and `GITOPS_ACCESS_TOKEN` and `GITOPS_BOT_EMAIL` to your [repository variables](https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/#Repository-variables)
2. Create a custom pipeline in your `bitbucket-pipelines.yml` file

   ```yaml
   pipelines:
     custom:
       cc-bot:
         - step:
             name: Bitbucket PR Bot
             image: ghcr.io/thangnc/bitbucket-pr-bot:latest
   ```
