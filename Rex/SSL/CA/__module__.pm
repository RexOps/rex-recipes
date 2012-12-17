#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# This is a basic task collection to create own SSL CAs.

   
package Rex::SSL::CA;

use Rex -base;
use Expect;
use Sys::Hostname;

task create => sub {
   my $param = shift;

   if(! $param || ! exists $param->{password}) {
      say "Usage: rex Rex:SSL:CA:create --password=pass [--country=cn --state=state --city=city --org=organization --unit=organizational-unit --cn=name-of-the-ca --email=email]";
      say "If you set the Common Name (cn) don't use the name of a server here.";

      exit 1;
   }

   # defaults
   $param->{country} ||= "US";
   $param->{state}   ||= "State";
   $param->{city}    ||= "City";
   $param->{org}     ||= "Org";
   $param->{unit}    ||= "";
   $param->{cn}      ||= hostname() . " CN";
   $param->{email}   ||= "hostmaster\@" . hostname();

   # get the default ssl conf out of the <DATA> store
   my @openssl_cnf = <DATA>;
   chomp @openssl_cnf;

   # create the files and directories
   mkdir "ca";
   chdir "ca";

   open(my $fh, ">", "openssl.cnf") or die($!);
   print $fh join("\n", @openssl_cnf);
   close($fh);

   mkdir "certs";
   mkdir "crl";
   mkdir "newcerts";
   mkdir "private";

   chmod 600, "openssl.cnf";
   chmod 700, "private";

   open($fh, ">", "index.txt");
   close($fh);

   system('echo "01" > serial');

   my $cmd = "LC_ALL=C openssl req -config openssl.cnf -new -x509 -keyout private/ca.key -out certs/ca.crt -days 3600"; 
   my $exp = Expect->spawn($cmd);
   $exp->expect(5, 
                    [ qr/Enter PEM pass phrase/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{password} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/Country Name/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{country} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/State or Province Name/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{state} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/Locality Name/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{city} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/Organization Name/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{org} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/Organizational Unit Name/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{unit} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/Common Name/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{cn} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/Email Address/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{email} . "\n");
                                 exp_continue;
                              } ],
   );

   $exp->soft_close;



};


1;

=pod

=head1 NAME

Rex::SSL::CA - Small CA module

=head1 DESCRIPTION

This is a basic task collection to create own SSL CAs.

=head1 USAGE

 # create a new ca
 rex SSL:CA:create --password=foobar
    
 # create a server vert
 rex SSL:CA:Server:create --cn=your-server --password=foobar

=cut


__DATA__
[ ca ]
default_ca= myca # The default ca section
#################################################################

[ myca ]
dir=.

certs=$dir/certs # Where the issued certs are kept
crl_dir= $dir/crl # Where the issued crl are kept
database= $dir/index.txt # database index file
new_certs_dir= $dir/newcerts # default place for new certs
certificate=$dir/certs/ca.crt # The CA certificate
serial= $dir/serial # The current serial number
crl= $dir/crl.pem # The current CRL
private_key= $dir/private/ca.key # The private key
RANDFILE= $dir/.rand # private random number file
default_days= 365 # how long to certify for
default_crl_days= 30 # how long before next CRL
default_md= md5 # which message digest to use
preserve= no # keep passed DN ordering

# A few different ways of specifying how closely the request should
# conform to the details of the CA

policy= policy_anything 

[ policy_anything ]
countryName = optional
stateOrProvinceName= optional
localityName= optional
organizationName = optional
organizationalUnitName = optional
commonName= supplied
emailAddress= optional

[ req ]
default_bits = 1024
default_keyfile= privkey.pem
distinguished_name = req_distinguished_name
attributes = req_attributes

[ req_distinguished_name ]
countryName= Country Name (2 letter code)
countryName_min= 2
countryName_max = 2
stateOrProvinceName= State or Province Name (full name)
localityName = Locality Name (eg, city)
organizationName = Organization Name (eg, company)
organizationalUnitName = Organizational Unit Name (eg, section)
commonName = Common Name (eg. YOUR name)
commonName_max = 64
emailAddress = Email Address
emailAddress_max = 40

[ req_attributes ]
challengePassword = A challenge password
challengePassword_min = 0 
challengePassword_max = 20
unstructuredName= An optional company name


