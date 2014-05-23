host: '<%= $ldap_uri %>'
bind_dn: '<%= $ldap_bind_dn %>'
bind_pw: '<%= $ldap_bind_password %>'
base_dn: '<%= $ldap_base_dn %>'
filter: (&(uid={{LOGIN_NAME}})(objectClass=posixAccount))
#tls:
#        verify: optional
#        cafile: /etc/openldap/certs/cacert.pem
