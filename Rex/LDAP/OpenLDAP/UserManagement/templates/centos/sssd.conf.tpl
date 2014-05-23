[domain/default]
debug_level = 5
cache_credentials = False
ldap_search_base = <%= $ldap_base_dn %>
krb5_realm = EXAMPLE.COM
krb5_server = kerberos.example.com
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
ldap_uri = <%= $ldap_uri %>
ldap_tls_cacertdir = /etc/openldap/cacerts
ldap_tls_reqcert = allow

ldap_default_bind_dn = <%= $ldap_bind_dn %>
ldap_default_authtok_type = password
ldap_default_authtok = <%= $ldap_bind_password %>

<% if(! $ldap_configure_tls) { %>
ldap_auth_disable_tls_never_use_in_production = True
<% } %>

ldap_user_search_base = <%= $ldap_base_user_dn %>
ldap_group_search_base = <%= $ldap_base_group_dn %>
ldap_group_member = memberUid
ldap_group_nesting_level = 4

[sssd]
services = nss, pam
config_file_version = 2
debug_level = 5
domains = default

[nss]

[pam]

[sudo]

[autofs]

[ssh]

[pac]
