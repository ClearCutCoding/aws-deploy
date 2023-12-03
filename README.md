# AWS Deploy

## Installation

Install script with Awesome bash package manager: `https://github.com/shinokada/awesome`

1. Install awesome
```
$ curl -s https://raw.githubusercontent.com/shinokada/awesome/main/install | bash -s install
```

2. Update ~/.bashrc

```
export PATH=$HOME/.local/share/bin:$PATH
```

3. Install scripts

```
$ awesome install ClearCutCoding/aws-deploy
$ awesome alias aws-deploy-dev-image aws-deploy aws-deploy-dev-image.sh
$ awesome alias aws-deploy-build-image aws-deploy aws-deploy-build-image.sh
$ awesome alias aws-deploy-ci-image aws-deploy aws-deploy-ci-image.sh
```

4. Update scripts

```
$ awesome update aws-deploy
```

## Configuration

- Make sure the aws repo using this script has a config file `aws-deploy.cfg` in `/opt/devops/aws/bin`
- You can run a custom script after git repos update by mentioning the script in 'hook_script_post_git_update'
- You can add custom volumes to the docker build image by mentioning the file in 'hook_config_docker_build_volumes'.  This file should be terminated by an empty line, with each line being a source:target volume mapping.
- You can add environment variables to the docker build image by mentioning the file in 'hook_config_docker_build_env_vars'.  This file should consist of each line being a NAME=VAR mapping.

## Run deployment

### Prod

```
$ (cd /opt/devops/aws/bin && aws-deploy --app xxx --devopsbranch master --branch master --target prd --build api)
```

### Dev images

```
$ (cd /opt/devops/aws/bin && aws-deploy-dev-image)
```

### Build images

```
$ (cd /opt/devops/aws/bin && aws-deploy-build-image)
```

### CI images

```
$ (cd /opt/devops/aws/bin && aws-deploy-ci-image)
```
