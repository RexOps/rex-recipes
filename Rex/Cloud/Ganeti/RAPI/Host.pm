package REX::Cloud::Ganeti::RAPI::Host;


sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

