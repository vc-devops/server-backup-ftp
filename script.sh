#!/bin/sh
set -euo pipefail

TOKEN=''
TOKEN_BASE64=''
ERP_API_URL='https://api.pigeon.vicoders.com'
DRY_RUN=false
FTP_HOST=''
FTP_USER=''
FTP_PASS=''
FTP_PATH='/'
BACKUP_DIR=$(pwd)
BACKUP_PARTTEN='.*Full-Code[0-7]-.*'
MOVE_TO_TMP_FOLDER=false
TMP_FOLDER_PATH=$(pwd)
REMOVE_AFTER_BACKUP=true
TOUCH=true
TOUCH_URL='https://api.pigeon.vicoders.com/api/v1/backups/guest'
HOME_PATH='/home'
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    --token)
        TOKEN_BASE64="$2"
        shift # past argument
        shift # past value
        ;;
    --api-url)
        ERP_API_URL="$2"
        shift # past argument
        shift # past value
        ;;
    -dry | --dry-run)
        DRY_RUN=true
        shift # past argument
        shift # past value
        ;;
    -ip | --server-ip)
        SERVER_IP="$2"
        shift # past argument
        shift # past value
        ;;
    -h | --host)
        FTP_HOST="$2"
        shift # past argument
        shift # past value
        ;;
    --tmp)
        MOVE_TO_TMP_FOLDER=true
        shift # past argument
        shift # past value
        ;;
    -u | --user)
        FTP_USER="$2"
        shift # past argument
        shift # past value
        ;;
    -p | --password)
        FTP_PASS="$2"
        shift # past argument
        shift # past value
        ;;
    -d | --directory)
        BACKUP_DIR="$2"
        shift # past argument
        shift # past value
        ;;
    --home)
        HOME_PATH="$2"
        shift # past argument
        ;;
    --regex)
        BACKUP_PARTTEN=$2
        shift # past argument
        ;;
    *) ;; # unknown option
    esac
done

function log() {
    printf "[$(date -u)] $1\n"
}

function error() {
    printf "[ERROR][$(date -u)] $1\n"
    exit 1
}

function join() {
    local IFS="$1"
    shift
    echo "$*"
}

function parseToken() {
    echo $1 | base64 --decode
}

function getAccount() {
    curl --header "Content-Type: application/json" --request GET "$ERP_API_URL/api/v1/servers/accounts/get-by-token?token=$1"
}

function getServer() {
    curl --header "Content-Type: application/json" --request GET "$ERP_API_URL/api/v1/servers/accounts/get-by-token?token=$1"
}

if [ -z "$TOKEN_BASE64" ]; then
    error "TOKEN is required"
fi

TOKEN="$(parseToken $TOKEN_BASE64)"

ACCOUNT="$(getAccount $TOKEN)"

FTP_HOST=$(echo $ACCOUNT | jq -r .'data.server.data.ip')
FTP_USER=$(echo $ACCOUNT | jq -r .'data.user')
FTP_PASS=$(echo $ACCOUNT | jq -r .'data.password')

curl -k "ftp://$FTP_HOST/" --user "$FTP_USER:$FTP_PASS" >/dev/null || {
    error "Can not connect to $FTP_HOST"
    exit 1
}

if $TOUCH; then
    regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    if ! [[ $TOUCH_URL =~ $regex ]]; then
        log "$TOUCH_URL not valid URL"
        exit 1
    fi
fi

touch() {
    folder=$1
    echo "Touching $folder/$file"
    echo "find $folder -maxdepth 1 -not -type d" | sh | while read file; do
        if [ -f "$folder/$file" ]; then
            reseller=''
            username=''
            reseller=$(echo "$file" | cut -d . -f 2)
            username=$(echo "$file" | cut -d . -f 3)

            echo "Reseller & Username $reseller - $username"

            if [ ! -z "$reseller" ] && [ ! -z "$username" ]; then
                if [ -d "$HOME_PATH/$username" ] && [ -d "$HOME_PATH/$username/domains" ]; then
                    domains=()
                    domains=($(ls $HOME_PATH/$username/domains))
                    concat=$(join , ${domains[@]})
                    size=$(du -k $folder/$file | cut -f1)
                    if $DRY_RUN; then
                        echo "Touching data {\"ip\":\"$SERVER_IP\",\"username\":\"$username\",\"domains\":\"$concat\",\"size\": $size, \"note\":\"\"}"
                    else
                        curl --header "Content-Type: application/json" \
                            --request POST \
                            --data "{\"ip\":\"$SERVER_IP\",\"username\":\"$username\",\"domains\":\"$concat\",\"size\": $size, \"note\":\"\"}" \
                            $TOUCH_URL
                    fi

                fi

            fi
        fi
    done
}

function BackupDir() {
    if $MOVE_TO_TMP_FOLDER; then
        if [ -z "$TMP_FOLDER_PATH" ]; then
            TMP_FOLDER_PATH="$BACKUP_DIR"
        fi
        if [ ! -d "$TMP_FOLDER_PATH/tmp" ]; then
            mkdir -p $TMP_FOLDER_PATH/tmp
        fi

        cp -R $1 $TMP_FOLDER_PATH/tmp

        foldername=$(basename $1)

        if ! $DRY_RUN; then
            ncftpput -R -v -u "$FTP_USER" -p "$FTP_PASS" "$FTP_HOST" $FTP_PATH $TMP_FOLDER_PATH/tmp/$foldername || {
                rm -rf $TMP_FOLDER_PATH/tmp/$foldername
                exit 1
            }
        fi
        if $TOUCH; then
            touch $TMP_FOLDER_PATH/tmp/$foldername
            echo "$TMP_FOLDER_PATH/tmp/$foldername"
        fi
        rm -rf $TMP_FOLDER_PATH/tmp/$foldername
        if $REMOVE_AFTER_BACKUP; then
            rm -rf $1
        fi
        log "Backup $1 completed"
    else
        foldername=$(basename $1)
        if ! $DRY_RUN; then
            ncftpput -R -v -u "$FTP_USER" -p "$FTP_PASS" "$FTP_HOST" $FTP_PATH $1 || {
                exit 1
            }
            if $REMOVE_AFTER_BACKUP; then
                rm -rf $1
            fi
        fi
        if $TOUCH; then
            touch $1
        fi
        log "Backup $1 completed"
    fi
}

function BackupFile() {
    echo "Backup file: $1"
}

echo "find $BACKUP_DIR -maxdepth 1 -regex \"$BACKUP_PARTTEN\"" | sh | while read i; do
    if [ -d "$i" ] && [ "$i" != "$BACKUP_DIR" ]; then
        BackupDir $i
    fi
done
