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
```

## Configuration

- Make sure the aws repo using this script has a config file `aws-deploy.cfg` in `/opt/devops/aws/bin`
- Run installer or create shell aliases, e.g:

```
$ (cd /opt/devops/aws/bin && aws-deploy --app xxx --devopsbranch master --branch master --target prd --build api)
```
