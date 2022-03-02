# Mô hình triển khai

                                                         | eth0
                            +----------------------------+----------------------------+
                            |                            |                            |
                            |10.0.0.51                   |10.0.0.52                   |10.0.0.30 
                +-----------+-----------+    +-----------+-----------+    +-----------+-----------+
                |        [master]       |    |      [satellite]      |    |      [Openstack]      |
                |        icinga2        +----+         icinga2       +----+   nagios-nrpe-server  |
                |        maria-db       |    |                       |    |      Openstack AIO    |
                |        mailutils      |    |                       |    |                       |    
                |         ssmtp         |    |                       |    |                       |    
                |                       |    |                       |    |                       |
                +-----------+-----------+    +-----------------------+    +-----------------------+
                       
## 1. Thiết lập trên node master 

- Chạy `wizard node`
```sh
root@quynv:~# icinga2 node wizard
Welcome to the Icinga 2 Setup Wizard!

We will guide you through all required configuration details.

Please specify if this is an agent/satellite setup ('n' installs a master setup)                                                                                                              [Y/n]: n

Starting the Master setup routine...

Please specify the common name (CN) [quynv]:
Reconfiguring Icinga...
Checking for existing certificates for common name 'quynv'...
Certificate '/var/lib/icinga2/certs//quynv.crt' for CN 'quynv' already existing.                                                                                                              Skipping certificate generation.
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
root@quynv:~# systemctl restart icinga2.service
root@quynv:~# icinga2 pki ticket --cn "satellite"
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
Master/Satellite Common Name (CN from your master/satellite node): quynv

Do you want to establish a connection to the parent node from this node? [Y/n]: y
Please specify the master/satellite connection information:
Master/Satellite endpoint host (IP address or FQDN): 10.0.0.51
Master/Satellite endpoint port [5665]:

Add more master/satellite endpoints? [y/N]: n
Parent certificate information:

 Version:             3
 Subject:             CN = quynv
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


## 3. Thiết lập trên node agent

- Tải pulgin monitor openstack



- Cấu hình nagios nrpe

```sh
root@client:~# vim /etc/nagios/nrpe.cfg

/....
allowed_hosts=127.0.0.1, 10.0.0.51, 10.0.0.52

/...
command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -r -w .15,.10,.05 -c .30,.25,.20
command[check_hda1]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /dev/hda1
command[check_zombie_procs]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
command[check_keystone]=/usr/lib/nagios/plugins/check_keystone
command[check_nova]=/usr/lib/nagios/plugins/check_nova
command[check_glance]=/usr/lib/nagios/plugins/check_glance
command[check_cinder]=/usr/lib/nagios/plugins/check_cinder
command[check_neutron]=/usr/lib/nagios/plugins/check_neutron
command[check_image]=/usr/lib/nagios/plugins/check_image
command[check_instance]=/usr/lib/nagios/plugins/check_instance
command[check_network]=/usr/lib/nagios/plugins/check_network
command[check_volume]=/usr/lib/nagios/plugins/check_volume
command[check_mem]=/usr/lib/nagios/plugins/check_mem
command[check_cpu]=/usr/lib/nagios/plugins/check_cpu
```

- Khởi động lại dịch vụ

```sh
root@client:~# systemctl restart nagios-nrpe-server.service
```

## 4. Cấu hình giám sát node agent trên node master
- Cài đặt nrpe plugin

```sh
root@quynv:~# apt install nagios-nrpe-plugin
```

- Cấu hình CheckCommand cho `nrpe`
```sh
root@quynv:/etc/icinga2/zones.d/satellite# vim /usr/share/icinga2/include/command-plugins.conf

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
root@quynv:/etc/icinga2# vim zones.conf

object Endpoint "quynv" {
}

object Zone "master" {
        endpoints = [ "quynv" ]
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
  host = "10.0.0.52"
  log_duration = 0 // Disable the replay log for command endpoint agents
}
```

- Thêm cấu hình zone openstack

```sh
root@quynv:/etc/icinga2/zones.d/satellite# vim agent.conf

object Zone "openstack" {
  endpoints = [ "openstack" ]
  parent = "satellite"
}

object Endpoint "openstack" {
  host = "10.0.0.30"
  log_duration = 0 // Disable the replay log for command endpoint agents
}
```
- Thêm cấu hình host openstack

```sh
root@quynv:/etc/icinga2/zones.d/satellite# vim hosts.conf

object Host "openstack" {
  check_command = "hostalive"
  address = "10.0.0.30"
  vars.agent_endpoint = name
}
```

- Thêm cấu hình service

```sh

root@quynv:/etc/icinga2/zones.d/satellite# vim service.conf

apply Service "ping4" {
  check_command = "ping4"
  assign where host.zone == "satellite" && host.address
}

apply Service "check-load" {
  check_command = "nrpe"
  vars.nrpe_command = "check_load"
  assign where host.zone == "satellite" && host.address
}

apply Service "check-keystone" {
  check_command = "nrpe"
  vars.nrpe_command = "check_keystone"
  assign where host.zone == "satellite" && host.address
}

apply Service "check-nova" {
  check_command = "nrpe"
  vars.nrpe_command = "check_nova"
  assign where host.zone == "satellite" && host.address
}

apply Service "check-image" {
  check_command = "nrpe"
  vars.nrpe_command = "check_image"
  assign where host.zone == "satellite" && host.address
}

apply Service "Check-network" {
  check_command = "nrpe"
  vars.nrpe_command = "check_network"
  assign where host.zone == "satellite" && host.address
}

apply Service "check-instance" {
  check_command = "nrpe"
  vars.nrpe_command = "check_instance"
  assign where host.zone == "satellite" && host.address
}

apply Service "check-cpu" {
  check_command = "nrpe"
  vars.nrpe_command = "check_cpu"
  assign where host.zone == "satellite" && host.address
}
apply Service "check-mem" {
  check_command = "nrpe"
  vars.nrpe_command = "check_mem"
  assign where host.zone == "satellite" && host.address
}
```

- Kiểm tra cấu hình và khởi động lại icinga2
```sh
root@quynv:/etc/icinga2/zones.d/satellite# icinga2 daemon -C
root@quynv:/etc/icinga2/zones.d/satellite# icinga2 daemon -C
[2022-03-02 01:56:16 +0000] information/cli: Icinga application loader (version: r2.13.2-1)
[2022-03-02 01:56:16 +0000] information/cli: Loading configuration file(s).
[2022-03-02 01:56:16 +0000] information/ConfigItem: Committing config item(s).
[2022-03-02 01:56:16 +0000] information/ApiListener: My API identity: quynv
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 1 IcingaApplication.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 1 Host.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 1 FileLogger.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 1 CheckerComponent.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 1 ApiListener.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 1 IdoMysqlConnection.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 5 Zones.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 3 Endpoints.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 2 ApiUsers.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 244 CheckCommands.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 1 NotificationComponent.
[2022-03-02 01:56:16 +0000] information/ConfigItem: Instantiated 9 Services.
[2022-03-02 01:56:16 +0000] information/ScriptGlobal: Dumping variables to file '/var/cache/icinga2/icinga2.vars'
[2022-03-02 01:56:16 +0000] information/cli: Finished validating the configuration file(s).
root@quynv:/etc/icinga2/zones.d/satellite# systemctl restart icinga2.service
```

- Trên dashboard

<img src="https://github.com/lean15998/Monitoring_openstack/blob/main/image/01.PNG">




