#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::SSL::CA::Server;

use Rex -base;
use Expect;

task create => sub {
   my $param = shift;

   if(! $param || ! exists $param->{password}) {
      say "Usage: rex Rex:SSL:CA:create --cn=name-of-the-server --password=password [--challenge-password=challenge-password --country=country --state=state --city=city --org=organization --unit=organizational-unit --email=email]";
      say "Use the server name for CN.";

      exit 1;
   }

   # defaults
   $param->{country} ||= "US";
   $param->{state}   ||= "State";
   $param->{city}    ||= "City";
   $param->{org}     ||= "Org";
   $param->{unit}    ||= "";
   $param->{password}||= "";
   $param->{email}   ||= "";


   chdir "ca";

   my $exp2 = Expect->spawn("openssl req -config openssl.cnf -new -nodes -keyout private/" . $param->{cn} 
                                    . ".key -out " 
                                    . $param->{cn} . ".csr -days 3600");
   $exp2->expect(5, 
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
                    [ qr/A challenge password/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{"challenge-password"} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/An optional company name/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{"challenge-password"} . "\n");
                                 exp_continue;
                              } ],
   );

   $exp2->soft_close;

   print "Signing server certificate\n";
   my $exp3 = Expect->spawn("openssl ca -config openssl.cnf -policy policy_anything -out certs/" . $param->{cn} . ".crt -infiles " . $param->{cn} . ".csr");
   $exp3->expect(5, 
                  [ qr/Enter pass phrase for/ => sub {
                                 my $_exp = shift;
                                 $_exp->send($param->{password} . "\n");
                                 exp_continue;
                              } ],
                    [ qr/Sign the certificate/ => sub {
                                 my $_exp = shift;
                                 $_exp->send("y\n");
                                 exp_continue;
                              } ],
                    [ qr/certified, commit/ => sub {
                                 my $_exp = shift;
                                 $_exp->send("y\n");
                                 exp_continue;
                              } ],
   );

   $exp3->soft_close;

   unlink $param->{cn} . ".csr";



};

1;
