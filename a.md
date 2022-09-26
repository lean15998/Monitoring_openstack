root@quynv-cloud:~# openstack user create --domain default   --password 123456789Aa quynv
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | cbc2b86f09cf4a6d926378a79a291471 |
| name                | quynv                            |
| options             | {}                               |
| password_expires_at | 2022-09-26T03:11:15.309236       |
+---------------------+----------------------------------+
root@quynv-cloud:~# openstack role add --project admin --user quynv admin
