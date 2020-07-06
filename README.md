# FTP Backup

# Usage
## Install JQ

```
yum install -y epel-release
yum install -y jq
```
## Run command

```
curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/vc-devops/server-backup-ftp/production/script.sh | bash /dev/stdin --token {token} -d {folder_backup}
```

Options

| Option  | Description                  | Default |
| ------- | ---------------------------- | ------- |
| --token | Token to get correct account |         |


## Cron job

```
0 21 * * 6 curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/vc-devops/server-backup-ftp/production/script.sh | bash /dev/stdin --token {token} -d {folder_backup}

// folder backup là folder chứa các thư mục Full-Code3 hoặc Full-Code7, ví dụ: /Work/Backup-Auto
// token sẽ được cung cấp trên phần mềm
// 0 21 * * 6 cronjob sẽ chạy vào 21h thứ 7
```
