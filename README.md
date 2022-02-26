# Platform - SonarQube

This setup allows you to run your own instance of SonarQube with [branch plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin) enabled, which allows multiple branch analysis with PR decorations enabled.


## Production Setup

SonarQube production setup:

- Create a public network - `docker network create sonar_public_network`
- Issue SSL certificate - `docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d sonarqube.platform.jalantechnologies.com -m developer@jalantechnologies.com --agree-tos`
- Run services - `docker-compose up`

## Project Import Process - GitHub

On SonarQube:

- Sign in using "GitHub" and start the import process from here - https://sonarqube.platform.jalantechnologies.com/projects/create?mode=github
- Select organization and search for the project to import
- Select with "GitHub actions" when asked for "How do you want to analyze your repository?"
- Generate token to get the value for "SONAR_TOKEN". Take a note of it, this won't be shown again.
- Take a note of value for "SONAR_HOST_URL" as well. This will be usually - `https://sonarqube.platform.jalantechnologies.com`
- From "Project Information" section (accessible from top right), take note of the project key as well.

On GitHub:
- Add following github actions secrets via `Settings > Secrets > Actions`:
    - `SONAR_TOKEN`
    - `SONAR_HOST_URL`
- Add following actions to your GitHub projects `.github/workflows/` directory:
    - [analysis-sonarqube-pull-request.yml](https://github.com/jalantechnologies/jtc-website-v2/blob/develop/.github/workflows/analysis-sonarqube-push.yml) - Workflow which will run when Pull Requests are opened and updated to run branch anaysis.
    - [analysis-sonarqube-push.yml](https://github.com/jalantechnologies/platform-sonarqube/blob/main/github/actions/analysis-sonarqube-push.yml) - Workflow which will run when commits are pushed to default branch. Default is being assumed `develop` and can be changed according to the project.
- Add `sonar-project.properties` file to the project as well:
```
sonar.projectKey=<YOUR_PROJECT_KEY_HERE>
```
- After pushing these files, the analysis should be successful.
- You might see the message ""<YOUR_DEFAULT_BRANCH>" branch has not been analyzed yet and you have multiple branches already. It looks like it is not your Main Branch, check your configuration.". This will get resolved once the checked in files are successfully merged to `<YOUR_DEFAULT_BRANCH>` branch.
