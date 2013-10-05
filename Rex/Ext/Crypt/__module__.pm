package Rex::Ext::Crypt;

use Rex -base;
require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);


BEGIN {
   use MIME::Base64;
   use Crypt::CBC;

   if($^O =~ m/^MSWin/) {
      require Term::ReadPassword::Win32;
      Term::ReadPassword::Win32->import;
   }
   else {
      require Term::ReadPassword;
      Term::ReadPassword->import;
   }
};

@EXPORT = qw(crypt_key decrypt);

my $crypt_key;

sub crypt_key {
   my ($path) = @_;
   if($path eq "-") {
      $crypt_key = read_password('key: ');
      chomp $crypt_key;
      return;
   }

   if(! -f $path) {
      die("Error: no keyfile found at $path.");
   }

   $crypt_key = eval { local(@ARGV, $/) = ($path); <>; };
   chomp $crypt_key;
}

sub decrypt {
   my ($string) = @_;
   my $c = Crypt::CBC->new(-key => $crypt_key, -cipher => 'Blowfish');
   return $c->decrypt(decode_base64($string));
}

1;

=pod

=head1 NAME

Rex::Ext::Crypt - Encrypt strings inside a Rexfile.

=head1 DESCRIPTION

With this module it is possible to encrypt strings inside your Rexfile. For example passwords.

Keep in mind that you have to protect your keyfile at a secure place. This module is mostly for camouflage.

For Windows you have to manually install I<Term::ReadPassword::Win32>.

=head1 USAGE


 use Rex::Ext::Crypt;
    
 crypt_key "/path/to/the/key/file";
 crypt_key "-";   # read the key from stdin
    
 user "root";
 password decrypt("U2FsdGVkX1/0VY5yH4kwUilSVzKAxClw");
    
 task yourtask => sub {
    install "foo";
 };

=head1 EXPORTED FUNCTIONS

=over 4

=item crypt_key($file)

This defines the key you have used to encrypt your strings.

=item decrypt($string)

This function decrypts the given $string with the help of the key inside the keyfile.

=back

=cut
