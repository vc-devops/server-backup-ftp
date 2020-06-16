# FTP Backup

# Usage

```
./scripts/ftp-backup.sh -d $(pwd)/__tests__ --touch https://api.pigeon.vicoders.com/api/v1/backups/guest -h xxx.xxx.xxx.xxx -u xxx -p xxx --regex "xxx"
```

Options

| Option            | Description        | Default |
| ----------------- | ------------------ | ------- |
| -dry , --dry-run  | Run in dry mode    |         |
| -ip , --server-ip | Current Server IP  |         |
| -h , --host       | FTP Server         |         |
| -u , --user       | FTP User           |         |
| -p , --password   | FTP Password       |         |
| -d , --directory  | Backup directory   |         |
| --home            | Home folder        | /home   |
| --regex           | Backup pattern     | .*      |
| --tmp             | MOVE_TO_TMP_FOLDER | false   |
| --touch           | Touch URL          |         |
