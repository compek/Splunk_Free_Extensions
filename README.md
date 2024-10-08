# Securing and extending Splunk Free Edition
A collection of scripts and configurations that enhance Splunk Free by adding access control (user/admin login), preventing license violations by stopping ingesting, and providing workarounds for missing alerting feature.

There are several versions of Splunk software: Splunk Enterprise (a paid version) and Splunk Free. Splunk Free is a limited version (https://docs.splunk.com/Documentation/Splunk/latest/Admin/MoreaboutSplunkFree). Here are the most important limitations of Splunk Free edition:

* Daily Volume Ingestion Restriction:
  * Splunk Free allows indexing up to 500 MB of data per day.
  * If you exceed this limit, you’ll receive a license violation warning.
  * After three warnings within a rolling 30-day period, searching functionality is disabled.
* Removed Features:
  * Alerting (Monitoring).
  * User Authentication and Roles:
    * There are no users or roles.
    * You are automatically logged in as an administrator-level user without any credentials.
      
Even with these limitations Splunk Free is still very useful.

Splunk Free Extensions is a collection of scripts and configurations that enhance Splunk Free and allows:
* configure a reverse proxy to add access control:
  * create login (username/password)
  * user "admin" can access everything and modify system settings
  * user "user" cannot modify system settings
* provides a workaround to configure alert actions by using cron and bash scripts
* stop splunk input if the license usage reaches 500MB to prevent license violations
* etc.

| Feature | Splunk Enterprise | Splunk Free Extensions or Workaround |
| --- | --- | --- |
|Ingest Action | + | Cribl, TRANSFORMS/SEDCMD/etc. |
|Alterting (monitoring)| + | scripting |
|Access control (users and roles)| + | reverse proxy (user + admin) |
|Distributed search incl. SH clustering | + | - |
|Deployment management| + | - |
|Index clustering | + | - |
|TCP/HTTP Forwarding | + | syslog-ng, rsyslog, Cribl |
|Report acceleration summaries| + | Data Model Accelerations or use of PREFIX |
|Debug/Referesh | + | Splunk Restart |
|Daily Volume | License | Stop input before the license usage reaches 500MB, data reduction, split data across multiple instances |

## Access Control

The access control (login with username/password) can be enabled by putting Splunk behind a reverse proxy with a basic authentication. Only authenticated user can access Splunk. A direct access to Splunk is restricted by binding UI to localhost in web.conf 
```
[settings]
server.socket_host = 127.0.0.1
```
On the reverse proxy you can configure several users that belong to two categories: users and admin. Users can do anything except modifing system settings. This is done by denying access to /manager/ URI path. Admins have access to all settings. 

![Splunk_Free_Extensions_Demo_Access_Control](https://github.com/compek/Splunk_Free_Extensions/assets/24303571/fc25ecde-6951-4a57-ba68-af50cab3c4b3)


## Alerts

To configuring an alert a cron job need to be configured that call a script that run a CLI SPL code and return results to the script. An example how to handle splunk stats results is provided. An Email action is provided in example (using mail or swacks command).
A throttle function (suppressing subsequent alerts until the throttle period is expired) is realised by creating a timestamp file.

## Prevent license violations

Splunk inputs can be disabled when the license reaches the daily limit and re-enabled at 00:00. During the "disabled" time incomping events are discarded (for example by using UDP).  

## Setup

### Configure reverse proxy to enable access control

Following steps were tested with Ubuntu 24.04 LTS
```
apt install apache2
cp splunk.conf /etc/apache2/sites-enabled/splunk.conf  # copy provided apache config
vi /etc/apache2/ports.conf                             # add a port for reverse proxy to listen on, ex. Listen 10.20.30.40:8008 and comment out Listen 80
a2enmod proxy proxy_http                               # enable proxy module
htpasswd -c /etc/apache2/.htpasswd user                # create a .htpasswd file and add a new user
htpasswd    /etc/apache2/.htpasswd admin               # add a new admin
systemctl restart apache2                              # restart apache

vi $SPLUNK_HOME/etc/system/local/web.conf              # add [settings]\nserver.socket_host = 127.0.0.1 to bind Splunk UI to localhost
systemctl restart Splunkd                              # restart Splunk
```

### Configure cron to enable Splunk alerts
```
vi splunk_free_alert.sh                                # modify SPL and mail parameters
chmod +x splunk_free_alert.sh
crontab -e # create a cronjob
```

### Disclamer ###
* The reverse proxy configuration is based on the idea that all management functions are located behind the /manager URI path. This “just enough” approach is suitable for a simple setup, though it is somewhat naive and not intended to be bulletproof.
* This release is a BETA.
* Test anything before using in production.
* All you do with this software is on your own responsibility.
