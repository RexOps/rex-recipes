package REX::Cloud::Ganeti::RAPI::VM;


sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub name {
   my ($self, $data) = @_;

   $data->{name};
}

sub uri {
   my ($self, $data) = @_;

   $data->{uri};
}
1;

