#
# (c) Joris De Pooter <jorisd@gmail.com>
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

# Some of the code is based on Rex::Cloud::OpenNebula

# this package is bogus atm and does nothing
package Rex::Cloud::Ganeti::RAPI::Host;

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

1;
