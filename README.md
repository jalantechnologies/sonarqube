# Platform - SonarQube

This setup allows you to run your own instance of SonarQube with [branch plugin](https://github.com/mc1arke/sonarqube-community-branch-plugin) enabled, which allows multiple branch analysis with PR decorations enabled.

SonarQube production setup:

- Create a public network - `docker network create sonar_public_network`
- Issue SSL certificate - `docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d sonarqube.platform.jalantechnologies.com -m developer@jalantechnologies.com --agree-tos`
- Run services - `docker-compose up`
