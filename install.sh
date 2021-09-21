#!/bin/bash
green='\033[0;32m'
red='\033[0;31m'
white='\033[0;37m'
reset='\033[0;0m'

status(){
  clear
  echo -e $green$@'...'$reset
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

  ipaddress=$( ip route get 1.1.1.1 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' )

  while [ -z $dynuser ]; do
  read -ep $'\e[37mPlease enter a name for the MySQL user you want to use later to log in to PHPMyAdmin:\e[0m ' dynuser;
  done
  while [ -z $dynamicUserPassword ]; do
  read -ep $'\e[37mPassword for \e[0m\e[36m'$dynuser$'\e[0m\e[37m (\"\e[33mauto\e[0m\"\e[37m for an automatically generated password):\e[0m ' dynamicUserPassword;
  done

  generatePassword="false";
  dynamicUserPassword=`echo $dynamicUserPassword | sed 's/ *$//g'`
  if [[ "${dynamicUserPassword,,%%*( )}" == "auto" ]]; then

  	generatePassword="true";

  fi

}


function mainPart() {
  runCommand "apt -y update" "updating"

  runCommand "apt -y upgrade" 

  runCommand "apt install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-mbstring php-zip php-gd apache2 libapache2-mod-php mariadb-server pwgen expect iproute2 wget zip -y" "installing necessary packages"

  status "generating passwords"
  rootPasswordMariaDB=$( pwgen 32 1 );
  pmaPassword=$( pwgen 32 1 );
  blowfish_secret=$( pwgen 32 1 );
  if [[ "${generatePassword}" == "true" ]]; then
  	dynamicUserPassword=$( pwgen 32 1 );
  fi

  status "securing the mariadb installation"
  SECURE_MYSQL=$(expect -c "
  set timeout 3
  spawn mysql_secure_installation
  expect \"Enter current password for root (enter for none):\"
  send \"\r\"
  expect \"root password?\"
  send \"y\r\"
  expect \"New password:\"
  send \"$rootPasswordMariaDB\r\"
  expect \"Re-enter new password:\"
  send \"$rootPasswordMariaDB\r\"
  expect \"Remove anonymous users?\"
  send \"y\r\"
  expect \"Disallow root login remotely?\"
  send \"y\r\"
  expect \"Remove test database and access to it?\"
  send \"y\r\"
  expect \"Reload privilege tables now?\"
  send \"y\r\"
  expect eof
  ")
  echo "${SECURE_MYSQL}"

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

  runCommand "printf \"\\\$cfg[\'TempDir\'] = \'/var/lib/phpmyadmin/tmp\';\" >> /usr/share/phpmyadmin/config.inc.php"

  runCommand "chown -R www-data:www-data /var/lib/phpmyadmin" "rights are granted"

  runCommand "service mysql start" "importing PHPMyAdmin's \"creating_tables.sql\""

  runCommand "mariadb < /usr/share/phpmyadmin/sql/create_tables.sql"

  runCommand "service mysql restart"

  runCommand "mariadb -e \"GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '${pmaPassword}'\"" "creating MySQL users and granting privileges"

  runCommand "mariadb -e \"GRANT ALL PRIVILEGES ON \$( printf '\52' ).\$( printf '\52' ) TO '${dynuser}'@'localhost' IDENTIFIED BY '${dynamicUserPassword}' WITH GRANT OPTION;\""

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
}


function selfTest() {

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

  SHOW_DATABASES=$(mariadb -e "SHOW DATABASES;")

  if [[ "${SHOW_DATABASES}" != *"phpmyadmin"* ]]; then MARIADB_TEST_PASSED=false; fi

  if [[ "${MARIADB_TEST_PASSED}" != "true" ]]; then
    echo -e "${red}MariaDB did not respond as expected. Please check your MariaDB installation!"
    exit 1
  fi

}


function output() {
  clear

  echo "
  MySQL-Data:
     IP/Host: localhost
     Port: 3306
     User: root
     Password: ${rootPasswordMariaDB}

  PHPMyAdmin-Data:
     Link: http://${ipaddress}/phpmyadmin/
     User: ${dynuser}
     Password: ${dynamicUserPassword}
  "
}



if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


input

mainPart

selfTest

output
