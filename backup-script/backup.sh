#! /bin/bash

# REQUIRE
BACKUP_DIRECTORY="/home/crayon/Downloads/backup-$(date +%d-%m-%Y)"
MYSQL_USER="root"
MYSQL_PASSWORD="carlos101"

APACHE_LOCAL_PROJECTS_DIRECTORY=/var/www/html
APACHE_BACKUP_DIRECTORY=$BACKUP_DIRECTORY/apache
APACHE_BACKUP_PROJECTS_DIRECTORY=$APACHE_BACKUP_DIRECTORY/www

VSCODE_BACKUP_DIRECTORY=$BACKUP_DIRECTORY/vscode
MOCKOON_BACKUP_DIRECTORY=$BACKUP_DIRECTORY/mockoon

MYSQL_BACKUP_DIRECTORY=$BACKUP_DIRECTORY/mysql
MYSQL_FULL_BACKUP_DIRECTORY=$MYSQL_BACKUP_DIRECTORY/full
MYSQL_DATABASES_BACKUP_DIRECTORY=$MYSQL_BACKUP_DIRECTORY/databases

TOTAL_PROCESS=15
bar_size=40
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

function show_progress {
    current="$1"
    total="$2"

    # calculate the progress in percentage
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"

    if [ $total -eq $current ]; then
        echo -e "\nDONE"
    fi
}

changePermissions(){
    sudo chmod 775 -R $1
    sudo chown $USER:$USER -R $1
}

# Create backup directory
if [ ! -d $BACKUP_DIRECTORY ]
then
    mkdir $BACKUP_DIRECTORY;
else
    echo 'There is already a directory with this name. You want to overwritten and continue the process?'
    select result in Yes No
    do
        if [ "$result" = "Yes" ]
        then
            rm -r $BACKUP_DIRECTORY;
            mkdir $BACKUP_DIRECTORY;
            break;
        else
         exit;
        fi
    done
fi

show_progress 1 $TOTAL_PROCESS

# APACHE
show_progress 2 $TOTAL_PROCESS
mkdir $APACHE_BACKUP_DIRECTORY

# Copiar fichero /etc/hosts en <backup>/Apache/hosts
show_progress 3 $TOTAL_PROCESS
cp /etc/hosts $APACHE_BACKUP_DIRECTORY

# Copy directory site-available
show_progress 4 $TOTAL_PROCESS
sudo cp -r /etc/apache2/sites-available/ $APACHE_BACKUP_DIRECTORY

# Copy certs local directory
show_progress 5 $TOTAL_PROCESS
sudo cp -r /etc/ssl/certs-local $APACHE_BACKUP_DIRECTORY


# Copy web directories and configuration files
show_progress 6 $TOTAL_PROCESS
mkdir $APACHE_BACKUP_PROJECTS_DIRECTORY

for projectDirectory in $(ls $APACHE_LOCAL_PROJECTS_DIRECTORY)
do
    # Create directory
    backupProjectDirectory=$APACHE_BACKUP_PROJECTS_DIRECTORY/$projectDirectory
    mkdir $backupProjectDirectory

    projectEnviroment=$APACHE_LOCAL_PROJECTS_DIRECTORY/$projectDirectory/.env
    projectLocalEnviroment=$APACHE_LOCAL_PROJECTS_DIRECTORY/$projectDirectory/.env.local
    projectLocalTestEnviroment=$APACHE_LOCAL_PROJECTS_DIRECTORY/$projectDirectory/.env.test.local
    projectVscodeConfig=$APACHE_LOCAL_PROJECTS_DIRECTORY/$projectDirectory/.vscode

 if [ -f $projectEnviroment ]
    then
        cp $projectEnviroment $backupProjectDirectory
    fi

    if [ -f $projectLocalEnviroment ]
    then
        cp $projectLocalEnviroment $backupProjectDirectory
    fi

    if [ -f $projectLocalTestEnviroment ]
    then
        cp $projectLocalTestEnviroment $backupProjectDirectory
    fi

    if [ -d $projectVscodeConfig ]
    then
        cp -r $projectVscodeConfig $backupProjectDirectory
    fi

done

show_progress 7 $TOTAL_PROCESS
changePermissions $APACHE_BACKUP_DIRECTORY

# VSCODE

# User config
show_progress 8 $TOTAL_PROCESS
sudo cp -r ~/.config/Code/User $VSCODE_BACKUP_DIRECTORY

show_progress 9 $TOTAL_PROCESS
changePermissions  $VSCODE_BACKUP_DIRECTORY

# MOCKOON

# Copy projects config
show_progress 10 $TOTAL_PROCESS
sudo cp -r ~/.config/mockoon/storage $MOCKOON_BACKUP_DIRECTORY

show_progress 11 $TOTAL_PROCESS
changePermissions $MOCKOON_BACKUP_DIRECTORY

# MYSQL
show_progress 12 $TOTAL_PROCESS
mkdir $MYSQL_BACKUP_DIRECTORY
mkdir $MYSQL_FULL_BACKUP_DIRECTORY
mkdir $MYSQL_DATABASES_BACKUP_DIRECTORY

# Full backup
show_progress 13 $TOTAL_PROCESS
mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD --opt --all-databases -r $MYSQL_FULL_BACKUP_DIRECTORY/full.sql

# Database backup (not _test)
show_progress 14 $TOTAL_PROCESS
ExcludeDatabases="Database|information_schema|performance_schema|mysql"
databases=`mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | tr -d "| " | egrep -v $ExcludeDatabases`

for db in $databases; do
    if [[ "$db" != *"_test"* ]]
    then
        mysql_backup=$MYSQL_DATABASES_BACKUP_DIRECTORY/$db.sql
        mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD --databases $db > $mysql_backup
    fi
done
show_progress 15 $TOTAL_PROCESS
changePermissions $MYSQL_BACKUP_DIRECTORY
