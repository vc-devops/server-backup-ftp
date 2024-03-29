# FTP Backup

# Usage
## Install JQ

```
yum install -y epel-release
yum install -y jq

// Failed to set locale, defaulting to C
// Loaded plugins: fastestmirror
// Setting up Install Process
// Loading mirror speeds from cached hostfile
// Error: Cannot retrieve metalink for repository: epel. Please verify its path and try again

// sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
```

## Allow output traffic

```
iptables -I OUTPUT -p tcp -m tcp --dport 2121 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2122 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2123 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2124 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2125 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2126 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2127 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2128 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2129 -j ACCEPT
iptables -I OUTPUT -p tcp -m tcp --dport 2130 -j ACCEPT
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
