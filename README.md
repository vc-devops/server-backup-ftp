# FTP Backup

# Usage
## Install JQ

```
yum install -y epel-release
yum install -y jq
```
## Run command

```
curl https://raw.githubusercontent.com/vc-devops/server-backup-ftp/production/script.sh | bash /dev/stdin --token JDJhJDA4JGRrQ0NCOWxNSHVPaGN4Z2RLai9KNGUvZEs5TnZHYXAzak41ejZXWExiOUZKeXJ2MlQwckQy
```

Options

| Option  | Description                  | Default |
| ------- | ---------------------------- | ------- |
| --token | Token to get correct account |         |


## Cron job

```
0 21 * * 1 curl https://raw.githubusercontent.com/vc-devops/server-backup-ftp/production/script.sh | bash /dev/stdin --token JDJhJDA4JEE0cHhac1MxZWU4UHUvLjloaWNwVWVNVnE3RFFGQ3l2VGtNaFhtNDZaN3RGVno0b2xNQ1NX -d /Work/Backup-Auto
```
