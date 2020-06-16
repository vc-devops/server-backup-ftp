#!/bin/sh

# true / false
DRY_RUN=
# Current server ip
SERVER_IP=''
# FTP server ip
FTP_HOST=''
# FTP user
FTP_USER=''
# FTP password
FTP_PASS=''
FTP_PATH='/'
# Folder that we want to backup
BACKUP_DIR=''
# Back up all file in folder (maxdepth=1)
BACKUP_FILE=true
# Back up all folder in folder (maxdepth=1)
BACKUP_FOLDER=true
BACKUP_PARTTEN='.*Full-Code[0-7]-.*'
MOVE_TO_TMP_FOLDER=true
TMP_FOLDER_PATH=''
REMOVE_AFTER_BACKUP=true
TOUCH=true
TOUCH_URL='https://api.pigeon.vicoders.com/api/v1/backups/guest'
HOME_PATH='/home'

if [ ! -d "$BACKUP_DIR" ]; then
    echo "$BACKUP_DIR directory does not exist"
    exit 1
fi

items=()

echo "find $BACKUP_DIR -regex \"$BACKUP_PARTTEN\" -maxdepth 1" | sh | tee tmp_file >/dev/null

IFS=$'\n' read -d '' -r -a items <tmp_file
rm -rf tmp_file

log() {
    printf "[$(date -u)] $1\n"
}

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
                echo $HOME_PATH/$username/domains
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
            # mv $1 $TMP_FOLDER_PATH/tmp
            cp -R $1 $TMP_FOLDER_PATH/tmp
        fi
        foldername=$(basename $1)

        if ! $DRY_RUN; then
            ncftpput -R -v -u "$FTP_USER" -p "$FTP_PASS" "$FTP_HOST" $FTP_PATH $TMP_FOLDER_PATH/tmp/$foldername
        fi
        if $TOUCH; then
            touch $TMP_FOLDER_PATH/tmp/$foldername
        fi
        rm -rf $TMP_FOLDER_PATH/tmp/$foldername
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

for i in "${items[@]}"; do
    if [ -d "$i" ]; then
        BackupDir $i
    # else
    #     if [ -f "$i" ]; then
    #         BackupFile $i
    #     fi
    fi
done
