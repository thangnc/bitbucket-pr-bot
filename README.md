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
      --env BITBUCKET_COMMIT \
      --env BITBUCKET_REPO_OWNER \
      --env BITBUCKET_REPO_SLUG \
      cc-bot:latest
```

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
