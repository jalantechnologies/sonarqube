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

## If using GitHub actions:
- After selecting "GitHub actions", generate token to get the value for `SONAR_TOKEN`. Take a note of it, this won't be shown again.
- Take a note of value for `SONAR_HOST_URL` as well. This will be usually - `https://sonarqube.platform.jalantechnologies.com`
- Add following github actions secrets via `Settings > Secrets > Actions`:
    - `SONAR_TOKEN`
    - `SONAR_HOST_URL`
- Add following actions to your GitHub projects `.github/workflows/` directory:
    - [analysis-sonarqube-pull-request.yml](https://github.com/jalantechnologies/platform-sonarqube/blob/main/github/actions/analysis-sonarqube-pull-request.yml) - Workflow which will run when Pull Requests are opened and updated to run branch anaysis.
    - [analysis-sonarqube-push.yml](https://github.com/jalantechnologies/platform-sonarqube/blob/main/github/actions/analysis-sonarqube-push.yml) - Workflow which will run when commits are pushed to default branch. Default is being assumed `develop` and can be changed according to the project.

## If using CircleCI:
- Select "Other CI" when prompted for "How do you want to analyze your repository?".
- Generate token for the project and take a note of it. This will be the value for `SONAR_TOKEN`.
- Add the following CircleCI configurationfile `config.yml` inside `.circleci` folder, in your root directory - [config.yml](https://github.com/jalantechnologies/platform-sonarqube/blob/main/circleci/workflows/config.yml)
- Add following enviornment variables to your CircleCI project:
    - `SONAR_TOKEN`
    - `SONAR_HOST_URL`

_Note:_ You might see the message `<YOUR_DEFAULT_BRANCH>` branch has not been analyzed yet and you have multiple branches already. It looks like it is not your Main Branch, check your configuration.". This will get resolved once the checked in files are successfully merged to `<YOUR_DEFAULT_BRANCH>` branch.
