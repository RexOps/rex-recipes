#
# LDAP Defaults
#

# See ldap.conf(5) for details
# This file should be world readable but not world writable.

BASE	<%= $ldap_base_dn %>
URI	<%= $ldap_uri %>

BINDDN <%= $ldap_bind_dn %>
BINDPW <%= $ldap_bind_password %>


#SIZELIMIT	12
#TIMELIMIT	15
#DEREF		never

TLS_CACERTDIR	/etc/openldap/cacerts
