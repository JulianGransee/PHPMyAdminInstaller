# PHPMyAdmin install Script

This is just a simple to install PHPMyAdmin, Apache2 and MariaDB on some Linux distributions based systems.

To run the installer simply run the following command and follow the instructions

```
bash <(curl -s https://raw.githubusercontent.com/GermanJag/PHPMyAdminInstaller/main/install.sh)
```

---

| Operating System | Version | Can run the script?
| ---------------- | ------- | ------------------
| Ubuntu           | 18.04   | probably, not tested yet 	        
|                  | 20.04   | :white_check_mark:
| Debian           | 9       | probably, not tested yet		        
|                  | 10      | :white_check_mark:
| CentOS           | 6       | probably, not tested yet 	       	 		  	
|                  | 7       | probably, not tested yet 	        		  	
|                  | 8       | probably, not tested yet 	         		  


## before installing it - think about it


Before you install PHPMyAdmin on your system, think twice about it:

  - PHPMyAdmin is exposing your Database on a publically available website - just behind a username and password
  - There are a lot of known [exploits](https://www.cvedetails.com/vulnerability-list/vendor_id-784/Phpmyadmin.html)
  - and there are [exploits](https://snyk.io/vuln/composer:phpmyadmin%2Fphpmyadmin), which are known, but not fixed

## This is what you should use:

 Here are some clients out there, which give you access to your database, without exposing it through a website:

 - [DBeaver](https://dbeaver.io/) _(it is written in Java, so you can run it nearly everywhere)_
 - [DataGrip](https://www.jetbrains.com/datagrip) _(available on Windows, Linux and Mac OS X)_
 - [mysql workbench](https://www.mysql.com/products/workbench/)  _(available on Windows, Linux and Mac OS X)_

 If you use one of these clients, I would recommend using an SSH tunnel, that you don't have to expose the MySQL Port to the outside world
