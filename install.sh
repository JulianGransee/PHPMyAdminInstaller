#!/bin/bash
green='\033[0;32m'
red='\033[0;31m'
white='\033[0;37m'
reset='\033[0;0m'
status(){
  clear
  echo -e $green$1'...'$reset
  sleep 1
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

while [ -z $dynuser ]; do
read -ep $'\e[37mPlease enter a name for the MySQL user you want to use later to log in to PHPMyAdmin:\e[0m ' dynuser;
done
while [ -z $dynamicUserPassword ]; do
read -ep $'\e[37mPassword for \e[0m\e[36m'$dynuser$'\e[0m\e[37m (\"\e[33mauto\e[0m\"\e[37m for an automatically generated password):\e[0m ' dynamicUserPassword;
done

generatePassword="false";

if [[ "${dynamicUserPassword}" == "auto" ]]; then

	generatePassword="true";

fi

status "updating"
apt -qq -o=Dpkg::Use-Pty=0 update -y

status "installing necessary packages"
apt -qq -o=Dpkg::Use-Pty=0 install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-mbstring php-zip php-gd apache2 libapache2-mod-php mariadb-server pwgen expect iproute2 -y

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

status "downloading of PHPMyAdmin"
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip

status "unpacking PHPMyAdmin"
unzip phpMyAdmin-5.1.0-all-languages.zip

rm phpMyAdmin-5.1.0-all-languages.zip

status "moving files"
sudo mv phpMyAdmin-5.1.0-all-languages/ /usr/share/phpmyadmin

sudo mkdir -p /var/lib/phpmyadmin/tmp

status "editing config"
sudo cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php


sed -i 's/\$cfg\[\x27blowfish_secret\x27\] = \x27\x27\; \/\* YOU MUST FILL IN THIS FOR COOKIE AUTH! \*\//\$cfg\[\x27blowfish_secret\x27\] = \x27'$blowfish_secret'\x27\; \/\* YOU MUST FILL IN THIS FOR COOKIE AUTH! \*\//' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controluser\x27\] \= \x27pma\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controluser\x27\] \= \x27pma\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controlpass\x27\] = \x27pmapass\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controlpass\x27\] = \x27'$pmaPassword'\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pmadb\x27\] \= \x27phpmyadmin\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pmadb\x27\] \= \x27phpmyadmin\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27bookmarktable\x27\] \= \x27pma__bookmark\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27bookmarktable\x27\] \= \x27pma__bookmark\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27relation\x27\] \= \x27pma__relation\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27relation\x27\] \= \x27pma__relation\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_info\x27\] \= \x27pma__table_info\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_info\x27\] \= \x27pma__table_info\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_coords\x27\] \= \x27pma__table_coords\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_coords\x27\] \= \x27pma__table_coords\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pdf_pages\x27\] \= \x27pma__pdf_pages\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pdf_pages\x27\] \= \x27pma__pdf_pages\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27column_info\x27\] \= \x27pma__column_info\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27column_info\x27\] \= \x27pma__column_info\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27history\x27\] \= \x27pma__history\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27history\x27\] \= \x27pma__history\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_uiprefs\x27\] \= \x27pma__table_uiprefs\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_uiprefs\x27\] \= \x27pma__table_uiprefs\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27tracking\x27\] \= \x27pma__tracking\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27tracking\x27\] \= \x27pma__tracking\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27userconfig\x27\] \= \x27pma__userconfig\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27userconfig\x27\] \= \x27pma__userconfig\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27recent\x27\] \= \x27pma__recent\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27recent\x27\] \= \x27pma__recent\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27favorite\x27\] \= \x27pma__favorite\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27favorite\x27\] \= \x27pma__favorite\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27users\x27\] \= \x27pma__users\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27users\x27\] \= \x27pma__users\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27usergroups\x27\] \= \x27pma__usergroups\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27usergroups\x27\] \= \x27pma__usergroups\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27navigationhiding\x27\] \= \x27pma__navigationhiding\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27navigationhiding\x27\] \= \x27pma__navigationhiding\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27savedsearches\x27\] \= \x27pma__savedsearches\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27savedsearches\x27\] \= \x27pma__savedsearches\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27central_columns\x27\] \= \x27pma__central_columns\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27central_columns\x27\] \= \x27pma__central_columns\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27designer_settings\x27\] \= \x27pma__designer_settings\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27designer_settings\x27\] \= \x27pma__designer_settings\x27\;/' /usr/share/phpmyadmin/config.inc.php

sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27export_templates\x27\] \= \x27pma__export_templates\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27export_templates\x27\] \= \x27pma__export_templates\x27\;/' /usr/share/phpmyadmin/config.inc.php

echo "\$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';" >> /usr/share/phpmyadmin/config.inc.php

status "rights are granted"
sudo chown -R www-data:www-data /var/lib/phpmyadmin

status "importing PHPMyAdmin's \"creating_tables.sql\""
sudo mariadb < /usr/share/phpmyadmin/sql/create_tables.sql

status "creating MySQL users and granting privileges"
sudo mariadb -e "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '${pmaPassword}'"

sudo mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '${dynuser}'@'localhost' IDENTIFIED BY '${dynamicUserPassword}' WITH GRANT OPTION;"

status "deploying apache2 config"
echo '# phpMyAdmin default Apache configuration

Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php

    <IfModule mod_php5.c>
        <IfModule mod_mime.c>
            AddType application/x-httpd-php .php
        </IfModule>
        <FilesMatch ".+\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>

        php_value include_path .
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
        php_admin_value mbstring.func_overload 0
    </IfModule>
    <IfModule mod_php.c>
        <IfModule mod_mime.c>
            AddType application/x-httpd-php .php
        </IfModule>
        <FilesMatch ".+\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>

        php_value include_path .
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
        php_admin_value mbstring.func_overload 0
    </IfModule>

</Directory>

# Authorize for setup
<Directory /usr/share/phpmyadmin/setup>
    <IfModule mod_authz_core.c>
        <IfModule mod_authn_file.c>
            AuthType Basic
            AuthName "phpMyAdmin Setup"
            AuthUserFile /etc/phpmyadmin/htpasswd.setup
        </IfModule>
        Require valid-user
    </IfModule>
</Directory>

# Disallow web access to directories that dont need it
<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
    Require all denied
</Directory>' > /etc/apache2/conf-available/phpmyadmin.conf

sudo a2enconf phpmyadmin.conf

sudo systemctl reload apache2

ipaddress=$( ip route get 1.1.1.1 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' )

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
