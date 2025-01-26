#    Copyright (C) 2021  Julian G.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License 2 as published by
#    the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License 2 for more details.
#
#    You should have received a copy of the GNU General Public License 2 along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

#!/bin/bash
green='\033[0;32m'
red='\033[0;31m'
white='\033[0;37m'
reset='\033[0;0m'

status(){
  clear
  if [[ "$2" == "/" ]]; then
    echo -e $green$1$reset
  else
    echo -e $green$@'...'$reset
  fi
  sleep 1
}

runCommand(){
    COMMAND=$1

    if [[ ! -z "$2" ]]; then
      status $2
    fi

    eval $COMMAND;
    BASH_CODE=$?
    if [ $BASH_CODE -ne 0 ]; then
      echo -e "${red}An error occurred:${reset} ${white}${COMMAND}${reset}${red} returned${reset} ${white}${BASH_CODE}${reset}"
      exit ${BASH_CODE}
    fi
}

function input() {

  clear

  status "Create a special account for PHPMyAdmin access (this is going to disable the PHPMyAdmin access with root)?" "/"

  export OPTIONS=("No, keep it simple" "Yes, I want security")
    bashSelect
    case $? in
      0 )
        status "okay"
        rootLogin="y"
      ;;
      1 )
        rootLogin="n";

        #readUname
        while [ -z $dynuser ]; do
           dynuser=$( echo $dynuser | sed 's/ //g' | sed 's/[^a-z]//g' )
           read -ep $'\e[37mPlease enter a name for the MySQL user you want to use later to log in to PHPMyAdmin:\e[0m ' dynuser;
           if [[ "${dynuser,,%%*( )}" == "root" ]]; then
             unset dynuser
           fi

        done

         status "Set a password" "/"
         export OPTIONS=("Let the script generate a secure passwort" "No, I will do it myself")
         bashSelect
           case $? in
             0 )
               generatePassword="true";
             ;;
             1 )
               while [ -z $dynamicUserPassword ]; do
                 read -ep $'\e[37mPassword for \e[0m\e[36m'$dynuser$'\e[0m\e[37m:\e[0m ' dynamicUserPassword;
               done
               generatePassword="false";
               dynamicUserPassword=`echo $dynamicUserPassword | sed 's/ *$//g'`
                if [[ "${dynamicUserPassword,,%%*( )}" == "auto" ]]; then

                  generatePassword="true";

                fi

             ;;
             esac


      ;;
    esac

}

function serverCheck() {
  status "running some checks"
  mariadb --version
  if [[ $? != 127 ]]; then
    status "It looks like mariadb is already installed\nShould it be removed or can we just reset the password?" "/"
    export OPTIONS=("Reset MySQL/MariaDB password and proceed to install PHPMyAdmin" "Remove the MariaDB/MySQL server and every database" "Exit the script ")
    bashSelect
    case $? in
      0 )
        status "resetting mysql password"
        alreadyInstalled=true;
      ;;
      1 )
        status "removing MariaDB/MySQL"
        runCommand "service mariadb stop || service mysql stop || systemctl stop mariadb; DEBIAN_FRONTEND=noninteractiv apt -y remove --purge mariadb-*"
        runCommand "rm -r /var/lib/mysql/"
        ;;
      2 )
        exit 0
        ;;
    esac
  fi

  if [[ -d /usr/share/phpmyadmin ]]; then
    status "It looks like the phpmyadmin directory already exists" "/"
    export OPTIONS=("Remove the /usr/share/phpmyadmin directory" "Exit the script ")
    bashSelect
    case $? in
      0 )
        runCommand "rm -r /usr/share/phpmyadmin/" "removing /usr/share/phpmyadmin"
        ;;
      1 )
        exit 0
        ;;
    esac
  fi

#I added this to collect some usage statistics.
#Don't worry, no code will be downloaded or executed here (this is not possible with such a command).
#Don't worry, we don't store any user-related data, IP addresses are anonymised, etc..
#This command has no influence on the rest of the script, or on you, I only added it out of personal interest to know what kind of people use this script :)
curl https://script.gransee.me/PHPMyAdminInstaller &
}

function webserverInstall(){
  runCommand "printf '
  \n
  Alias /phpmyadmin /usr/share/phpmyadmin
  \n
  \n<Directory /usr/share/phpmyadmin>
  \n    Options SymLinksIfOwnerMatch
  \n    DirectoryIndex index.php
  \n
  \n    <IfModule mod_php5.c>
  \n        <IfModule mod_mime.c>
  \n            AddType application/x-httpd-php .php
  \n        </IfModule>
  \n        <FilesMatch \".+\.php$\">
  \n            SetHandler application/x-httpd-php
  \n        </FilesMatch>
  \n
  \n        php_value include_path .
  \n        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
  \n        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
  \n        php_admin_value mbstring.func_overload 0
  \n    </IfModule>
  \n    <IfModule mod_php.c>
  \n        <IfModule mod_mime.c>
  \n            AddType application/x-httpd-php .php
  \n        </IfModule>
  \n        <FilesMatch \".+\.php$\">
  \n            SetHandler application/x-httpd-php
  \n        </FilesMatch>
  \n
  \n        php_value include_path .
  \n        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
  \n        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
  \n        php_admin_value mbstring.func_overload 0
  \n    </IfModule>
  \n
  \n</Directory>
  \n
  \n# Authorize for setup
  \n<Directory /usr/share/phpmyadmin/setup>
  \n    <IfModule mod_authz_core.c>
  \n        <IfModule mod_authn_file.c>
  \n            AuthType Basic
  \n            AuthName \"phpMyAdmin Setup\"
  \n            AuthUserFile /etc/phpmyadmin/htpasswd.setup
  \n        </IfModule>
  \n        Require valid-user
  \n    </IfModule>
  \n</Directory>
  \n
  \n# Disallow web access to directories that dont need it
  \n<Directory /usr/share/phpmyadmin/templates>
  \n    Require all denied
  \n</Directory>
  \n<Directory /usr/share/phpmyadmin/libraries>
  \n    Require all denied
  \n</Directory>
  \n<Directory /usr/share/phpmyadmin/setup/lib>
  \n    Require all denied
  \n</Directory>' > /etc/apache2/conf-available/phpmyadmin.conf" "deploying apache2 config"

  runCommand "/etc/init.d/apache2 start"

  runCommand "a2enconf phpmyadmin.conf"

  runCommand "service apache2 reload"

  phpinstall

  runCommand "service apache2 restart"

}

function phpinstall() {

  eval $( cat /etc/*release* )
  if [[ "$ID" == "debian" && $VERSION_ID > 10 ]]; then

    runCommand "wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg" "adding main PHP repository for Debian - https://deb.sury.org"

    runCommand "sh -c 'echo \"deb https://packages.sury.org/php/ \$(lsb_release -sc) main\" > /etc/apt/sources.list.d/php.list'"

    runCommand "apt -y update"

    runCommand "apt -y install php8.3 php8.3-{cli,fpm,common,mysql,zip,gd,mbstring,curl,xml,bcmath}  libapache2-mod-php8.3" "installing php8"

  else

    runCommand "apt -y install php php-{cli,fpm,common,mysql,zip,gd,mbstring,curl,xml,bcmath}  libapache2-mod-php" "installing default php version"

  fi


}

function dbInstall(){

  status "generating passwords"
  rootPasswordMariaDB=$( pwgen 16 1 );
  pmaPassword=$( pwgen 32 1 );
  blowfish_secret=$( pwgen 32 1 );
  if [[ "${generatePassword}" == "true" ]]; then
  	dynamicUserPassword=$( pwgen 32 1 );
  fi

  status "securing the mariadb installation"

  if [[ "${alreadyInstalled}" == "true" ]]; then

    runCommand "systemctl stop mysql"
    runCommand "mysqld_safe --skip-grant-tables --skip-networking &"
    runCommand "sleep 5"

    mariadb -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '$rootPasswordMariaDB';"
    runCommand "killall mysqld || killall mariadbd"
    runCommand "systemctl start mysql"

  fi

  mariadb -u root -p$rootPasswordMariaDB -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${rootPasswordMariaDB}';"
  mariadb -u root -p$rootPasswordMariaDB -e "DELETE FROM mysql.user WHERE User='';"
  mariadb -u root -p$rootPasswordMariaDB -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');';"
  mariadb -u root -p$rootPasswordMariaDB -e "FLUSH PRIVILEGES;"


}

function pmaInstall() {

  runCommand "wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip" "downloading PHPMyAdmin"

  runCommand "unzip phpMyAdmin-latest-all-languages.zip" "unpacking PHPMyAdmin"

  runCommand "rm phpMyAdmin-latest-all-languages.zip"

  runCommand "mv phpMyAdmin-* /usr/share/phpmyadmin" "moving files"

  runCommand "mkdir -p /var/lib/phpmyadmin/tmp"

  runCommand "cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php" "editing config"

  runCommand "sed -i 's/\$cfg\[\x27blowfish_secret\x27\] = \x27\x27\; \/\* YOU MUST FILL IN THIS FOR COOKIE AUTH! \*\//\$cfg\[\x27blowfish_secret\x27\] = \x27'${blowfish_secret}'\x27\; \/\* YOU MUST FILL IN THIS FOR COOKIE AUTH! \*\//' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controluser\x27\] \= \x27pma\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controluser\x27\] \= \x27pma\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controlpass\x27\] = \x27pmapass\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controlpass\x27\] = \x27'${pmaPassword}'\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pmadb\x27\] \= \x27phpmyadmin\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pmadb\x27\] \= \x27phpmyadmin\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27bookmarktable\x27\] \= \x27pma__bookmark\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27bookmarktable\x27\] \= \x27pma__bookmark\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27relation\x27\] \= \x27pma__relation\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27relation\x27\] \= \x27pma__relation\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_info\x27\] \= \x27pma__table_info\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_info\x27\] \= \x27pma__table_info\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_coords\x27\] \= \x27pma__table_coords\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_coords\x27\] \= \x27pma__table_coords\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pdf_pages\x27\] \= \x27pma__pdf_pages\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pdf_pages\x27\] \= \x27pma__pdf_pages\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27column_info\x27\] \= \x27pma__column_info\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27column_info\x27\] \= \x27pma__column_info\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27history\x27\] \= \x27pma__history\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27history\x27\] \= \x27pma__history\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_uiprefs\x27\] \= \x27pma__table_uiprefs\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_uiprefs\x27\] \= \x27pma__table_uiprefs\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27tracking\x27\] \= \x27pma__tracking\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27tracking\x27\] \= \x27pma__tracking\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27userconfig\x27\] \= \x27pma__userconfig\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27userconfig\x27\] \= \x27pma__userconfig\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27recent\x27\] \= \x27pma__recent\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27recent\x27\] \= \x27pma__recent\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27favorite\x27\] \= \x27pma__favorite\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27favorite\x27\] \= \x27pma__favorite\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27users\x27\] \= \x27pma__users\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27users\x27\] \= \x27pma__users\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27usergroups\x27\] \= \x27pma__usergroups\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27usergroups\x27\] \= \x27pma__usergroups\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27navigationhiding\x27\] \= \x27pma__navigationhiding\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27navigationhiding\x27\] \= \x27pma__navigationhiding\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27savedsearches\x27\] \= \x27pma__savedsearches\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27savedsearches\x27\] \= \x27pma__savedsearches\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27central_columns\x27\] \= \x27pma__central_columns\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27central_columns\x27\] \= \x27pma__central_columns\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27designer_settings\x27\] \= \x27pma__designer_settings\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27designer_settings\x27\] \= \x27pma__designer_settings\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  runCommand "sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27export_templates\x27\] \= \x27pma__export_templates\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27export_templates\x27\] \= \x27pma__export_templates\x27\;/' /usr/share/phpmyadmin/config.inc.php"

  if [[ "${rootLogin}" == "n" ]]; then

  runCommand "echo \"\\\$cfg['Servers'][\\\$i]['export_templates'] = false;\" >> /usr/share/phpmyadmin/config.inc.php"

  fi

  runCommand "printf \"\\\$cfg[\'TempDir\'] = \'/var/lib/phpmyadmin/tmp\';\" >> /usr/share/phpmyadmin/config.inc.php"

  runCommand "chown -R www-data:www-data /var/lib/phpmyadmin" "rights are granted"

  runCommand "service mariadb start || service mysql start || systemctl start mariadb" "importing PHPMyAdmin's \"creating_tables.sql\""

  runCommand "mariadb -u root -p${rootPasswordMariaDB} < /usr/share/phpmyadmin/sql/create_tables.sql"
}

function mainPart() {

  runCommand "ls /etc/apt/sources.list.d/php* >/dev/null 2>&1 && rm /etc/apt/sources.list.d/php* || echo 0"

  runCommand "apt -y update" "updating"

  runCommand "apt -y upgrade"

  runCommand "apt install -y apache2 mariadb-server pwgen expect iproute2 wget zip apt-transport-https lsb-release ca-certificates curl dialog" "installing necessary packages"

  runCommand "service mariadb start || service mysql start || systemctl start mariadb"

  dbInstall

  pmaInstall

  runCommand "service mariadb restart || service mysql restart || systemctl restart mariadb"

  runCommand "mariadb -u root -p${rootPasswordMariaDB} -e \"GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '${pmaPassword}'\"" "creating MySQL users and granting privileges"

  if [[ "${rootLogin}" == "n" ]]; then

  runCommand "mariadb -u root -p${rootPasswordMariaDB} -e \"GRANT ALL PRIVILEGES ON \$( printf '\52' ).\$( printf '\52' ) TO '${dynuser}'@'localhost' IDENTIFIED BY '${dynamicUserPassword}' WITH GRANT OPTION;\""

  fi


  webserverInstall

}

function selfTest() {

  ipaddress=$( ip route get 1.1.1.1 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' )

  status "Running some very basic self tests"
  status "Running apache2 self tests (using curl)"

  APACHE_TEST_PASSED=true

  HTTP_STATUS_CODE=$( curl -I -X GET http://${ipaddress}/phpmyadmin/ | head -n 1 )
  FIRST_COOKIE=$( curl -I -X GET http://${ipaddress}/phpmyadmin/ | grep Set-Cookie | head -n 1 )

  if [[ "${HTTP_STATUS_CODE,,}" != *"200"* ]]; then APACHE_TEST_PASSED=false; fi

  if [[ "${FIRST_COOKIE,,}" != *"phpmyadmin"* ]]; then APACHE_TEST_PASSED=false; fi

  if [[ "${APACHE_TEST_PASSED}" != "true" ]]; then
    echo -e "${red}Apache2 did not respond as expected. Please check your Apache2 (and PHP) installation!"
    exit 1
  fi

  status "Running MariaDB self tests"

  MARIADB_TEST_PASSED=true

  SHOW_DATABASES=$(mariadb -u root -p$rootPasswordMariaDB -e "SHOW DATABASES;")

  if [[ "${SHOW_DATABASES}" != *"phpmyadmin"* ]]; then MARIADB_TEST_PASSED=false; fi

  if [[ "${MARIADB_TEST_PASSED}" != "true" ]]; then
    echo -e "${red}MariaDB did not respond as expected. Please check your MariaDB installation!"
    exit 1
  fi

}


function output() {
  clear

  if [[ $saveOutput == "true" ]]; then
    echo "
    MariaDB-Data:
       IP/Host: localhost
       Port: 3306
       User: root
       Password: ${rootPasswordMariaDB} " > /root/.mariadbPhpma
       echo "${rootPasswordMariaDB}" > /root/.mariadbRoot
       if [[ "${rootLogin}" == "n" ]]; then
         echo "
    PHPMyAdmin-Data:
      Link: http://${ipaddress}/phpmyadmin/
      User: ${dynuser}
      Password: ${dynamicUserPassword}" > /root/.PHPma
      else
      echo "Link: http://${ipaddress}/phpmyadmin/ " > /root/.PHPma
      fi
      printf "\nOutput saved in /root/.mariadbPhpma, /root/.PHPma and /root/.mariadbRoot"
  fi

  printf "\nSave the following:\n\n"
  echo "
  MariaDB-Data:
     IP/Host: localhost
     Port: 3306
     User: root
     Password: ${rootPasswordMariaDB}"

   if [[ "${rootLogin}" == "n" ]]; then
   echo "
  PHPMyAdmin-Data:
     Link: http://${ipaddress}/phpmyadmin/
     User: ${dynuser}
     Password: ${dynamicUserPassword}
     "
  else
  echo "
      Link: http://${ipaddress}/phpmyadmin/"
  fi
}



if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -h|--help)
      echo "This is just a simple script to install PHPMyAdmin, Apache2 and MariaDB on Debian based systems."
      echo
      echo "Syntax: bash <(curl -s https://raw.githubusercontent.com/JulianGransee/PHPMyAdminInstaller/main/install.sh) [options]"
      echo
      echo "Options:"
      echo "  -h, --help                      Display this help message."
      echo "  -s, --save                      Save the output to /root/.mariadbPhpma.output."
      echo "      --non-interactive           Skip all interactive prompts by providing all required inputs as options."
      echo "                                  Requires either --simple or --security to be specified."
      echo "                                  When using --security, you must also provide --db_name and --db_password."
      echo "      --simple                    Enable root access for phpMyAdmin (no security)."
      echo "      --security                  Disable root access for phpMyAdmin (enhanced security)."
      echo "      --db_name <name>            Specify a database name"
      echo "      --db_password <password>    Set a custom password for the database."
      echo "      --generate_password         Automatically generate a secure password for the database."
      echo "      --reset_password            Reset the database password if one already exists."
      echo "      --remove_db                 Remove MySQL/MariaDB and reinstall it."
      echo "      --remove_pma                Remove phpMyAdmin and reinstall it if it already exists."
      shift
      exit
      ;;
    -s|--save)
      status "The output is written to a file"
      saveOutput=true
      shift
      ;;
    --non-interactive)
      non_interactive=true
      shift
      ;;
    --security)
      rootLogin="n"
      shift
      ;;
    --simple)
      rootLogin="y"
      shift
      ;;
    --db_user)
      db_user="$2"
      dynuser="${db_user}"
      shift 2
      ;;
    --db_password)
      db_password="$2"
      generatePassword="false"
      dynamicUserPassword="${db_password}"
      shift 2
      ;;
    --generate_password)
      generatePassword="true"
      shift
      ;;
    --reset_password)
      reset_password="true"
      shift
      ;;
    --remove_db)
      remove_db="true"
      shift
      ;;
    --remove_pma)
      remove_pma="true"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done


if [[ "${non_interactive}" == "true" ]]; then
  errors=()

  if [[ "${rootLogin}" == "0" ]]; then
    errors+=("${red}Error:${reset} With --non-interactive, either --security or --simple must be set.")
  fi

  if [[ "${rootLogin}" == "n" ]]; then
    if [[ "${db_user}" == "0" ]]; then
      errors+=("${red}Error:${reset} With --non-interactive and --security, --db_user must be set.")
    fi

    if [[ "${db_password}" == "0" ]]; then
      errors+=("${red}Error:${reset} With --non-interactive and --security, --db_password must be set.")
    fi
  fi

  if [[ ${#errors[@]} -gt 0 ]]; then
    for error in "${errors[@]}"; do
      echo -e "$error"
    done
    exit 1
  fi
fi

curl --version
if [[ $? == 127  ]]; then  apt -y install curl; fi

source <(curl -s https://raw.githubusercontent.com/JulianGransee/BashSelect.sh/main/BashSelect.sh)

input

serverCheck

mainPart

selfTest

output
