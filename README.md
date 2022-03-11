# Platform - SonarQube

This setup allows you to run your own instance of SonarQube with [branch plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin) enabled, which allows multiple branch analysis with PR decorations enabled.


## Production Setup

SonarQube production setup:

- Create a public network - `docker network create sonar_public_network`
- Issue SSL certificate - `docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d sonarqube.platform.jalantechnologies.com -m developer@jalantechnologies.com --agree-tos`
- Run services - `docker-compose up`

## Project Import Process - GitHub

On SonarQube:
- Make sure [GtiHub App](https://github.com/apps/jtc-platform-sonarqube) for SonarQube integration is installed within the GitHub organization. GitHub app can be installed via selecting the "Configure" option from the GitHub app link.
- Sign in using "GitHub" and start the import process from here - https://sonarqube.platform.jalantechnologies.com/projects/create?mode=github
- Select organization and search for the project to import
    - If the organization is not listed - Make sure step #1 was completed and app was successfully installed within the GitHub org.
    - If the repository is not listed - Make sure you have read access to the repository.
- Select appropriate option when asked for "How do you want to analyze your repository?"
    - If using GitHub actions - Select GitHub actions and follow the process as described below.
    - If using any other CI tool - Follow the steps as described within the flow.
- From "Project Information" section (accessible from top right), take note of the project key.

On project:
- Add `sonar-project.properties` file to the project:
```
sonar.projectKey=<YOUR_PROJECT_KEY_HERE>
```

If using GitHub actions:
- After selecting "GitHub actions", generate token to get the value for `SONAR_TOKEN`. Take a note of it, this won't be shown again.
- Take a note of value for `SONAR_HOST_URL` as well. This will be usually - `https://sonarqube.platform.jalantechnologies.com`
- Add following github actions secrets via `Settings > Secrets > Actions`:
    - `SONAR_TOKEN`
    - `SONAR_HOST_URL`
- Add following actions to your GitHub projects `.github/workflows/` directory:
    - [analysis-sonarqube-pull-request.yml](https://github.com/jalantechnologies/jtc-website-v2/blob/develop/.github/workflows/analysis-sonarqube-push.yml) - Workflow which will run when Pull Requests are opened and updated to run branch anaysis.
    - [analysis-sonarqube-push.yml](https://github.com/jalantechnologies/platform-sonarqube/blob/main/github/actions/analysis-sonarqube-push.yml) - Workflow which will run when commits are pushed to default branch. Default is being assumed `develop` and can be changed according to the project.

_Note:_ You might see the message ""<YOUR_DEFAULT_BRANCH>" branch has not been analyzed yet and you have multiple branches already. It looks like it is not your Main Branch, check your configuration.". This will get resolved once the checked in files are successfully merged to `<YOUR_DEFAULT_BRANCH>` branch.

## If using CircleCI
- Create a file `config.yml` inside `.circleci` folder, in your root directory.
### PR analysis
- This workflow is used to run analysis on our PR when code is pushed to the branch.
- Create a job and name it as `analyze` which will run pull request analysis. Use docker image of sonarqube `sonarsource/sonar-scanner-cli:latest`.
- Under the steps of analyze first checkout the code using `- checkout` and then run a command to fetch Github PR number.

```
- run:
          name: Get GitHub PullRequest Number
          command: >-
            if [[ -z "$CIRCLE_PR_NUMBER" ]]; then
                if [[ -z "$CI_PULL_REQUEST" ]]; then
                    URL="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls?head=$CIRCLE_PROJECT_USERNAME:$CIRCLE_BRANCH"
                    RESULT="`curl -X GET -u $GITHUB_ACCESS_TOKEN:x-oauth-basic $URL | jq ".[0].url"`"
                    [[ "$RESULT" == 'null' ]] && CI_PULL_REQUEST='' || CI_PULL_REQUEST="${RESULT//\"}"
                fi
                CIRCLE_PR_NUMBER="$(basename "$CI_PULL_REQUEST")"
            fi

            echo 'export CIRCLE_PR_NUMBER=$CIRCLE_PR_NUMBER' >> $BASH_ENV
```

- Now run second command for PR analysis, name this as `SonarQube - PullRequest Scan`, now write command to run the PR analysis, given below:

```
command: >-
            sonar-scanner
            -X
            -Dsonar.login=$SONAR_TOKEN
            -Dsonar.host.url=$SONAR_HOST_URL
            -Dsonar.pullrequest.key=${CIRCLE_PULL_REQUEST##*/}
            -Dsonar.pullrequest.branch=$CIRCLE_BRANCH
            -Dsonar.pullrequest.base=main
            -Dsonar.qualitygate.wait=true
            -Dsonar.qualitygate.timeout=300
            -Dsonar.projectVersion=$CIRCLE_SHA1
```

Where, 
-`-Dsonar.login` is the token we get from SonarQube and `-Dsonar.host.url` is the URL where SonarQube instance is hosted. Both of these parameters are passed using CircleCI enviornment variables.
- `-Dsonar.pullrequest.key` is the pull request key which fetched using the previous command.
- `-Dsonar.pullrequest.branch` is the name of the Git branch currently being built.
- `-Dsonar.pullrequest.base` is the name of branch against which PR is raise.
- `-Dsonar.qualitygate.wait` setting this true forces the analysis step to poll your SonarQube instance until the Quality Gate status is available.
- `-Dsonar.qualitygate.timeout` set this to the number of seconds that the scanner should wait for a report to be processed.
- `-Dsonar.projectVersion` is the SHA1 hash of the last commit of the current build.

In the workflow set filters for analyze job to ignore `main`, `master` and `develop` branches.

### Main branch analysis
- This workflow is used to run analysis on main branch when are pull request get merged.
- Create a new job and name is as `analyze_branch` and use the docker image `sonarsource/sonar-scanner-cli:latest`.
- Under the steps first checkout the code using `- checkout`, now run a command and name it as `SonarQube - Push Scan` now write a command to run analysis on main branch on merging, Given below:

```
command: >-
            sonar-scanner
            -X
            -Dsonar.login=$SONAR_TOKEN
            -Dsonar.host.url=$SONAR_HOST_URL
            -Dsonar.branch.name=main
```
Where, 
`-Dsonar.login` and `-Dsonar.host.url` is passed using CircleCI enviornment variables and `-Dsonar.branch.name` is the name of branch on which sonarqube analysis needs to be run.

