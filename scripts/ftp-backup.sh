#!/bin/bash
POSITIONAL=()
DRY_RUN=false
SERVER_IP=''
FTP_HOST=''
FTP_USER=''
FTP_PASS=''
FTP_PATH='/'
BACKUP_DIR=''
BACKUP_FILE=false
BACKUP_FOLDER=false
BACKUP_PARTTEN=''
MOVE_TO_TMP_FOLDER=false
TMP_FOLDER_PATH=''
REMOVE_AFTER_BACKUP=true
TOUCH=false
TOUCH_URL=''
HOME_PATH='/home'
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
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
    --file)
        BACKUP_FILE=true
        shift # past argument
        ;;
    --folder)
        BACKUP_FILE=true
        shift # past argument
        ;;
    --regex)
        BACKUP_PARTTEN=$2
        shift # past argument
        ;;
    --tmp)
        MOVE_TO_TMP_FOLDER=true
        TMP_FOLDER_PATH="$2"
        shift # past argument
        ;;
    --touch)
        TOUCH=true
        TOUCH_URL="$2"
        shift # past argument
        ;;
    *)                     # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift              # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}"

log() {
    printf "[$(date -u)] $1\n"
}

if [ ! -d "$BACKUP_DIR" ]; then
    echo "$BACKUP_DIR directory does not exist"
    exit 1
fi

if [ -z "$BACKUP_PARTTEN" ]; then
    BACKUP_PARTTEN='.*'
fi

if [ ! -d "$HOME_PATH" ]; then
    echo "$HOME_PATH directory does not exist"
    exit 1
fi

if [ -z "$FTP_HOST" ]; then
    log "FTP_HOST is required"
    exit 1
fi

if [ -z "$FTP_USER" ]; then
    log "FTP_USER is required"
    exit 1
fi

if [ -z "$FTP_PASS" ]; then
    log "FTP_PASS is required"
    exit 1
fi

if $TOUCH; then
    regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    if ! [[ $TOUCH_URL =~ $regex ]]; then
        log "$TOUCH_URL not valid URL"
        exit 1
    fi
fi

function join() {
    local IFS="$1"
    shift
    echo "$*"
}

touch() {
    folder=$1
    files=()
    files=($(ls $folder))
    for file in "${files[@]}"; do
        if [ -f "$folder/$file" ]; then
            reseller=''
            username=''
            reseller=$(echo "$file" | cut -d . -f 2)
            username=$(echo "$file" | cut -d . -f 3)
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
            TMP_FOLDER_PATH=$(pwd)
        fi
        if [ ! -d "$TMP_FOLDER_PATH/tmp" ]; then
            mkdir -p $TMP_FOLDER_PATH/tmp
        fi
        if $DRY_RUN; then
            cp -R $1 $TMP_FOLDER_PATH/tmp
        else
            mv $1 $TMP_FOLDER_PATH/tmp
        fi
        foldername=$(basename $1)

        if ! $DRY_RUN; then
            ncftpput -R -v -u "$FTP_USER" -p "$FTP_PASS" "$FTP_HOST" $FTP_PATH $TMP_FOLDER_PATH/tmp/$foldername
        fi
        if $TOUCH; then
            touch $TMP_FOLDER_PATH/tmp/$foldername
        fi

        if $REMOVE_AFTER_BACKUP; then
            rm -rf $TMP_FOLDER_PATH/tmp/$foldername
        fi
        log "Backup $1 completed"
    else
        foldername=$(basename $1)
        if ! $DRY_RUN; then
            ncftpput -R -v -u "$FTP_USER" -p "$FTP_PASS" "$FTP_HOST" $FTP_PATH $1
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

items=()

echo "find $BACKUP_DIR -regex \"$BACKUP_PARTTEN\" -maxdepth 1" | sh | tee tmp_file >/dev/null

IFS=$'\n' read -d '' -r -a items <tmp_file
rm -rf tmp_file

for i in "${items[@]}"; do
    if [ -d "$i" ] && [ "$i" != "$BACKUP_DIR" ]; then
        BackupDir $i
    fi
done
