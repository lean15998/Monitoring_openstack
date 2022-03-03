# Mô hình triển khai

                                                         | eth0
                            +----------------------------+----------------------------+-----------------------------+
                            |                            |                            |                             |
                            |10.0.0.11                   |10.0.0.12                   |10.0.0.30                    |10.0.0.51
                +-----------+-----------+    +-----------+-----------+    +-----------+-----------+     +-----------+-----------+
                |        [master]       |    |      [satellite]      |    |      [Controller]     |     |        [Compute]      |
                |        icinga2        +    +         icinga2       +    +   nagios-nrpe-server  |     |   nagios-nrpe-server  |
                |        maria-db       |    |                       |    |  Keystone   Nova-api  |     |      Nova-compute     |
                |        mailutils      |    |                       |    |  Neutron    Placement |     |      Cinder-volume    |
                |         ssmtp         |    |                       |    |  Glance               |     |                       |
                |                       |    |                       |    |                       |     |                       |
                +-----------+-----------+    +-----------------------+    +-----------------------+     +-----------------------+
                       
## 1. Thiết lập trên node master 

- Chạy `wizard node`
```sh
root@master:~# icinga2 node wizard
Welcome to the Icinga 2 Setup Wizard!

We will guide you through all required configuration details.

Please specify if this is an agent/satellite setup ('n' installs a master setup)                                                                                                              [Y/n]: n

Starting the Master setup routine...

Please specify the common name (CN) [master]:
Reconfiguring Icinga...
Checking for existing certificates for common name 'master'...
Certificate '/var/lib/icinga2/certs//master.crt' for CN 'master' already existing.                                                                                                              Skipping certificate generation.
Generating master configuration for Icinga 2.
'api' feature already enabled.

Master zone name [master]:

Default global zones: global-templates director-global
Do you want to specify additional global zones? [y/N]: n
Please specify the API bind host/port (optional):
Bind Host []:
Bind Port []:

Do you want to disable the inclusion of the conf.d directory [Y/n]: y
Disabling the inclusion of the conf.d directory...
Checking if the api-users.conf file exists...

Done.

Now restart your Icinga 2 daemon to finish the installation!
```

- Khởi động lại icinga2 và tạo ticket client cho node satellite
```sh
root@master:~# systemctl restart icinga2.service
root@master:~# icinga2 pki ticket --cn "satellite"
7a6dabea07cd37514ab142ed55030c11a242af9d
```


## 2. Thiết lập trên node satellite

- Chạy `wizard node`

```sh
root@satellite:~# icinga2 node wizard
Welcome to the Icinga 2 Setup Wizard!

We will guide you through all required configuration details.

Please specify if this is an agent/satellite setup ('n' installs a master setup) [Y/n]: y

Starting the Agent/Satellite setup routine...

Please specify the common name (CN) [satellite]:

Please specify the parent endpoint(s) (master or satellite) where this node should connect to:
Master/Satellite Common Name (CN from your master/satellite node): master

Do you want to establish a connection to the parent node from this node? [Y/n]: y
Please specify the master/satellite connection information:
Master/Satellite endpoint host (IP address or FQDN): 10.0.0.11
Master/Satellite endpoint port [5665]:

Add more master/satellite endpoints? [y/N]: n
Parent certificate information:

 Version:             3
 Subject:             CN = master
 Issuer:              CN = Icinga CA
 Valid From:          Feb 17 07:57:36 2022 GMT
 Valid Until:         Feb 13 07:57:36 2037 GMT
 Serial:              cb:ad:a4:bf:0e:df:d0:6f:86:f2:16:0e:19:f9:30:d6:9b:03:34:71

 Signature Algorithm: sha256WithRSAEncryption
 Subject Alt Names:   quynv
 Fingerprint:         CF 6C E6 50 CA C2 FD 81 90 B5 C5 02 2D 42 31 FD 58 80 BC E1 E3 E1 A0 AE 18 E7 8E 84 06 FE 25 12

Is this information correct? [y/N]: y

Please specify the request ticket generated on your Icinga 2 master (optional).
 (Hint: # icinga2 pki ticket --cn 'satellite'): 7a6dabea07cd37514ab142ed55030c11a242af9d
Please specify the API bind host/port (optional):
Bind Host []:
Bind Port []:

Accept config from parent node? [y/N]: y
Accept commands from parent node? [y/N]: y

Reconfiguring Icinga...
Disabling feature notification. Make sure to restart Icinga 2 for these changes to take effect.

Local zone name [satellite]:
Parent zone name [master]:

Default global zones: global-templates director-global
Do you want to specify additional global zones? [y/N]: n

Do you want to disable the inclusion of the conf.d directory [Y/n]: y
Disabling the inclusion of the conf.d directory...

Done.

Now restart your Icinga 2 daemon to finish the installation!
```
- Khởi động lại icinga2

```sh
root@satellite:~# systemctl restart icinga2.service
```


## 3. Thiết lập trên 2 node compute và controller

- Tải pulgin monitor

- Cài đặt nrpe-server

```sh
root@controller:~# apt-get install nagios-nrpe-server
```

- Cấu hình nagios nrpe

```sh
root@controller:~# vim /etc/nagios/nrpe.cfg

/....
allowed_hosts=127.0.0.1, 10.0.0.11, 10.0.0.12

/...
command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -r -w .15,.10,.05 -c .30,.25,.20
command[check_hda1]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /dev/hda1
command[check_zombie_procs]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
command[check_mem]=/usr/lib/nagios/plugins/check_mem.pl -f -w 20 -c 10
command[check_cpu]=/usr/lib/nagios/plugins/check_cpu
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% /
```

- Khởi động lại dịch vụ

```sh
root@controller:~# systemctl restart nagios-nrpe-server.service
```

## 4. Cấu hình giám sát node controller và compute trên node master

- Cài đặt nrpe plugin

```sh
root@master:~# apt install nagios-nrpe-plugin
```

- Cấu hình CheckCommand cho `nrpe`
```sh
root@m:/etc/icinga2/zones.d/satellite# vim /usr/share/icinga2/include/command-plugins.conf

object CheckCommand "nrpe" {
        import "ipv4-or-ipv6"

        command = [ PluginDir + "/check_nrpe" ]

        arguments = {
                "-H" = {
                        value = "$nrpe_address$"
                        description = "The address of the host running the NRPE daemon"
                }
                "-p" = {
                        value = "$nrpe_port$"
                }
                "-c" = {
                        value = "$nrpe_command$"
                }
                "-n" = {
                        set_if = "$nrpe_no_ssl$"
                        description = "Do not use SSL"
                }
                "-u" = {
                        set_if = "$nrpe_timeout_unknown$"
                        description = "Make socket timeouts return an UNKNOWN state instead of CRITICAL"
                }
                "-t" = {
                        value = "$nrpe_timeout$"
                        description = "<interval>:<state> = <Number of seconds before connection times out>:<Check state to exit with in the event of a timeout (default=CRITICAL)>"
                }
                "-a" = {
                        value = "$nrpe_arguments$"
                        repeat_key = false
                        order = 1
                }
                "-4" = {
                        set_if = "$nrpe_ipv4$"
                        description = "Use IPv4 connection"
               }
               "-6" = {
                        set_if = "$nrpe_ipv6$"
                        description = "Use IPv6 connection"
                }
                "-2" = {
                        set_if = "$nrpe_version_2$"
                        description = "Use this if you want to connect to NRPE v2"
                }
                "-A" = {
                        value = "$nrpe_ca$"
                        description = "The CA file to use for PKI"
                }
                "-C" = {
                        value = "$nrpe_cert$"
                        description = "The cert file to use for PKI"
                }
                "-K" = {
                        value = "$nrpe_key$"
                        description = "The key file to use for PKI"
                }
                "-S" = {
                        value = "$nrpe_ssl_version$"
                        description = "The SSL/TLS version to use"
                }
                "-L" = {
                        value = "$nrpe_cipher_list$"
                        description = "The list of SSL ciphers to use"
                }
                "-d" = {
                        value = "$nrpe_dh_opt$"
                        description = "Anonymous Diffie Hellman use: 0 = deny, 1 = allow, 2 = force"
                }
        }

        vars.nrpe_address = "$check_address$"
        vars.nrpe_no_ssl = false
        vars.nrpe_timeout_unknown = false
        vars.check_ipv4 = "$nrpe_ipv4$"
        vars.check_ipv6 = "$nrpe_ipv6$"
        vars.nrpe_version_2 = false
        timeout = 5m
}
```


- Thêm cấu hình zone satellite


```sh
root@master:/etc/icinga2# vim zones.conf

object Endpoint "master" {
}

object Zone "master" {
        endpoints = [ "master" ]
}

object Zone "global-templates" {
        global = true
}

object Zone "director-global" {
        global = true
}

object Zone "satellite" {
  endpoints = [ "satellite" ]
  parent = "master"
}


object Endpoint "satellite" {
  host = "10.0.0.12"
  log_duration = 0 // Disable the replay log for command endpoint agents
}

```

- Thêm cấu hình zone compute và controller

```sh
root@master:/etc/icinga2# vim zones.d/satellite/agent.conf 

object Zone "compute" {
  endpoints = [ "compute" ]
  parent = "satellite"
}

object Endpoint "compute" {
  host = "10.0.0.51"
  log_duration = 0 // Disable the replay log for command endpoint agents
}

object Zone "controller" {
  endpoints = [ "controller" ]
  parent = "satellite"
}

object Endpoint "controller" {
  host = "10.0.0.30"
  log_duration = 0 // Disable the replay log for command endpoint agents
}
```
- Thêm cấu hình host compute và controller

```sh
root@master:/etc/icinga2# vim zones.d/satellite/hosts.conf

object Host "compute" {
  check_command = "hostalive"
  address = "10.0.0.51"
  vars.agent_endpoint = name
}

object Host "controller" {
  check_command = "hostalive"
  address = "10.0.0.30"
  vars.agent_endpoint = name
}

```

- Thêm cấu hình service

```sh
root@master:/etc/icinga2# vim zones.d/satellite/service.conf 

apply Service "ping4" {
  check_command = "ping4"
  assign where host.zone == "satellite" && host.address
}

apply Service "load" {
  check_command = "nrpe"
  vars.nrpe_command = "check_load"
  assign where host.zone == "satellite" && host.address
}

apply Service "Memory" {
  check_command = "nrpe"
  vars.nrpe_command = "check_mem"
  assign where host.zone == "satellite" && host.address
}

apply Service "cpu" {
  check_command = "nrpe"
  vars.nrpe_command = "check_cpu"
  assign where host.zone == "satellite" && host.address
}

apply Service "Disk" {
  check_command = "nrpe"
  vars.nrpe_command = "check_disk"
  assign where host.zone == "satellite" && host.address
}
```

- Kiểm tra cấu hình và khởi động lại icinga2
```sh
root@master:/etc/icinga2/zones.d/satellite# icinga2 daemon -C
[2022-03-02 16:47:30 +0700] information/cli: Icinga application loader (version: r2.13.2-1)
[2022-03-02 16:47:30 +0700] information/cli: Loading configuration file(s).
[2022-03-02 16:47:30 +0700] information/ConfigItem: Committing config item(s).
[2022-03-02 16:47:30 +0700] information/ApiListener: My API identity: master
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 1 IcingaApplication.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 2 Hosts.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 1 FileLogger.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 1 CheckerComponent.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 1 ApiListener.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 1 IdoMysqlConnection.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 6 Zones.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 4 Endpoints.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 2 ApiUsers.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 244 CheckCommands.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 1 NotificationComponent.
[2022-03-02 16:47:30 +0700] information/ConfigItem: Instantiated 10 Services.
[2022-03-02 16:47:30 +0700] information/ScriptGlobal: Dumping variables to file '/var/cache/icinga2/icinga2.vars'
[2022-03-02 16:47:30 +0700] information/cli: Finished validating the configuration file(s).
root@master:/etc/icinga2/zones.d/satellite# systemctl restart icinga2

```

- Trên dashboard


<img src="https://github.com/lean15998/Monitoring_openstack/blob/main/image/002.png">
<img src="https://github.com/lean15998/Monitoring_openstack/blob/main/image/003.png">



# 5. Cảnh báo

- Mở tính năng `notification`

```sh
root@master:~# icinga2 feature list
Disabled features: command compatlog debuglog elasticsearch gelf graphite icingadb influxdb influxdb2 livestatus opentsdb perfdata statusdata syslog
Enabled features: api checker ido-mysql mainlog notification
```

- Cài đặt mailutils và sSMTP (Trình gửi mail)

```sh
root@quynv:~# apt install -y mailutils ssmtp
```

- Cấu hình ssmtp

```sh
root@master:~# vim /etc/ssmtp/ssmtp.conf
root=quy15091998@gmail.com

mailhub=smtp.gmail.com:587
UseSTARTTLS=YES
AuthUser=quy15091998@gmail.com
AuthPass=Abc123456789
rewriteDomain=gmail.com
hostname=quynv
FromLineOverride=YES
```

- Cấu hình gửi cảnh báo cho người dùng `Admin`

```sh
root@master:~# cd /etc/icinga2/zones.d/satellite/
root@master:/etc/icinga2/zones.d/satellite# vim user.conf

object User "Admin" {

display_name = "Admin"
email = "quy15091998@gmail.com"
enable_notifications = true
}
```

- Cấu hình cảnh báo cho host `controller` và ``compute`

```sh
root@master:/etc/icinga2/zones.d/satellite# vim hosts.conf
object Host "compute" {
  check_command = "hostalive"
  address = "10.0.0.51"
  vars.agent_endpoint = name
  vars.notification["mail"] = { users = [ "Admin" ] }
  enable_notifications = true
}

object Host "controller" {
  check_command = "hostalive"
  address = "10.0.0.30"
  vars.agent_endpoint = name
  vars.notification["mail"] = { users = [ "Admin" ] }
 enable_notifications = true
}
```
- Cấu hình cảnh báo

```sh
root@master:/etc/icinga2/zones.d/satellite# vim notifications.conf
apply Notification "mail-Admin" to Host {
  command = "mail-host-notification"
  users = host.vars.notification.mail.users
  states = [ Up, Down ]
  types = [ Problem, Acknowledgement, Recovery, Custom ]
  interval = 0
  period = "24x7"
  assign where host.vars.notification.mail
}

apply Notification "mail-Admin" to Service {
  command = "mail-service-notification"
  users = host.vars.notification.mail.users
  interval = 0
  period = "24x7"
  states = [ OK, Warning, Critical, Unknown ]
  types = [ Problem, Acknowledgement, Recovery ]
  assign where host.vars.notification.mail
  period = "24x7"
}
```

- Kiểm tra cấu hình và khởi động lại dịch vụ

```sh
root@master:/etc/icinga2/zones.d/satellite# icinga2 daemon -C
[2022-03-03 10:44:29 +0700] information/cli: Icinga application loader (version: r2.13.2-1)
[2022-03-03 10:44:29 +0700] information/cli: Loading configuration file(s).
[2022-03-03 10:44:29 +0700] information/ConfigItem: Committing config item(s).
[2022-03-03 10:44:29 +0700] information/ApiListener: My API identity: master
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 12 Notifications.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 1 IcingaApplication.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 2 Hosts.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 1 FileLogger.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 2 NotificationCommands.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 1 CheckerComponent.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 1 ApiListener.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 1 IdoMysqlConnection.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 6 Zones.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 4 Endpoints.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 2 ApiUsers.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 244 CheckCommands.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 1 NotificationComponent.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 1 User.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 3 TimePeriods.
[2022-03-03 10:44:30 +0700] information/ConfigItem: Instantiated 10 Services.
[2022-03-03 10:44:30 +0700] information/ScriptGlobal: Dumping variables to file '/var/cache/icinga2/icinga2.vars'
[2022-03-03 10:44:30 +0700] information/cli: Finished validating the configuration file(s).


root@master:/etc/icinga2/zones.d/satellite# systemctl restart icinga2.service
```


- Trên dashboard

<img src = "https://github.com/lean15998/Icinga/blob/main/image/005.png" >

- Check mail cảnh báo

<img src = "https://github.com/lean15998/Icinga/blob/main/image/006.png">

<img src = "https://github.com/lean15998/Icinga/blob/main/image/007.png">
