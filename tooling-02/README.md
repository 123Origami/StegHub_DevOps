# Tooling

[![nginx 1.17.2](https://img.shields.io/badge/nginx-1.17.2-brightgreen.svg?&logo=nginx&logoColor=white&style=for-the-badge)](https://nginx.org/en/CHANGES) [![php 7.3.8](https://img.shields.io/badge/php--fpm-7.3.8-blue.svg?&logo=php&logoColor=white&style=for-the-badge)](https://secure.php.net/releases/7_3_8.php)

## Introduction

This is a Dockerfile to build a debian based container image running nginx and php-fpm 8.3.x / 8.2.x / 8.1.x / 8.0.x & Composer.

### Versioning

| Docker Tag | GitHub Release | Nginx Version | PHP Version | Debian Version |
|-----|-------|-----|--------|--------|
| latest | master Branch |1.17.2 | 8 | slim |

## How to use this repository

The build is automatically triggered by a git push to your feature/[branch]

## First clone the repository to your workstation

```bash
git clone https://github.com/StegTechHub/tooling-02.git tooling
cd tooling
```

Create a feature branch. # Always start with feature/[name of your branch]

```bash
git branch -b feature/add-css-style-to-about-us-page
```

Update the application code in `./html/`

Then add/commit/push to gitlab

```bash
git status # to see your changes
```

```bash
git add --all # If you are satisfied with your changes and willing to push everything. Otherwise, select only the files to add
```

```bash
git commit -m "Put some message about this push here"
```

## Push your changes to gitlab, and merge to dev branch

```bash
git push --set-upstream origin feature/[Your branch name]
```

### Validate your changes have been triggered by gitlab-ci in

[tooling-scm](https://github.com/StegTechHub/tooling-02.git)

### Check the image have been pushed to

[Google Container Registry](https://console.cloud.google.com/gcr/images/non-prod-pdz/EU/tooling?project=non-prod-pdz&authuser=1&gcrImageListsize=30) (Depending on the environment. Either non-prod or prod)

## pulling the image

```bash
docker pull eu.gcr.io/$environment/tooling:${tag-version}
```

## Running (You can do this step without the pulling the above as it will put down if not found locally)

To run the container:

```bash
 docker run -d eu.gcr.io/$environment/tooling:${tag-version}
```

Default web root:

```bash
/usr/share/nginx/html
```
