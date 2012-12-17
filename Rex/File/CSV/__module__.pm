#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# This is a small Module to parse simple comma seperated
# text files (csv).

package Rex::File::CSV;
   
use strict;
use warnings;

require Exporter;

use vars qw(@EXPORT);
@EXPORT = qw(read_csv_file);
use base qw(Exporter);

sub read_csv_file {
   my ($file, $code) = @_;
   open(my $fh, "<", $file) or die($!);
   while(my $line = <$fh>) {
      chomp $line;
      my @cols = split(m/,(?!(?:[^",]|[^"],[^"])+")/, $line);
      &$code(@cols);
   }
   close($fh);
}

1;

=pod

=head1 NAME

Rex::File::CSV - Simple CSV Module

=head1 USAGE

You can use this module as a library. It will export the function I<read_csv_file>.

 use Rex::File::CSV;
    
 task "yourtask", sub {
    read_csv_file "yourfile.csv", sub {
       my ($col1, $col2, $col3, ...) = @_;
       print "col1: $col1\n";
       print "col2: $col2\n";
       print "col3: $col3\n";
    };
 };

