#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Development::Jenkins;

use Rex -base;

task add_repository => sub {

   my $param = shift;

   repository add => jenkins => {
      Ubuntu => {
         url => "http://pkg.jenkins-ci.org/debian",
         distro => "",
         repository => "binary/",
         after => sub {
            run "wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -";
         },
      },
      Debian => {
         url => "http://pkg.jenkins-ci.org/debian",
         distro => "",
         repository => "binary/",
         after => sub {
            run "wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -";
         },
      },
      CentOS => {
         url => "http://pkg.jenkins-ci.org/redhat",
         gpgcheck => 1,
         after => sub {
            run "rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key";
         },
      },
      RedHatEnterpriseServer => {
         url => "http://pkg.jenkins-ci.org/redhat",
         gpgcheck => 1,
         after => sub {
            run "rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key";
         },
      }
   };

   update_package_db;
};

task prepare => sub {

   my $param = shift;

   needs "add_repository";

   install "jenkins";

   service jenkins => ensure => "running";

};

1;
