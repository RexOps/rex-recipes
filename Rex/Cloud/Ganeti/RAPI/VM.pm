package Rex::Cloud::Ganeti::RAPI::VM;

use Data::Dumper;

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub name {
   my $self = shift;

   #Rex::Logger::debug(Dumper($self));

   return $self->{data}->{id};
}

sub uri {
   my $self = shift;
  
   return $self->{data}->{uri};
}

sub status {
   my $self = shift;
   
   return $self->{extended_data}->{status};
}

1;
