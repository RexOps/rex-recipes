#
# Nicolas Leclercq <nicolas.private@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Ext::TemplateToolkit;

use Rex -base;
use Rex::Helper::Path;
use Template;
use Devel::Caller;

require Exporter;
use base qw(Exporter);
use vars qw (@EXPORT);

@EXPORT = qw(template_toolkit);

sub template_toolkit {
  my ( $template_path, $vars ) = @_;

  # resolv template path
  $template_path = Rex::Helper::Path::resolv_path($template_path);
  $template_path = Rex::Helper::Path::get_file_path( $template_path, caller() );
  Rex::Logger::debug("Processing template file : $template_path");

  # process template
  my $output = '';
  my $template = Template->new( { ABSOLUTE => 1 } );
  $template->process( $template_path, $vars, \$output )
    || Rex::Logger::debug( $template->error() );

  return $output;
}

sub import {

  my ( $class, $tag ) = @_;

  if ( $tag && $tag eq ":register" ) {

    # register Template::Toolkit for default template processing
    set template_function => sub {
      my ( $content, $vars ) = @_;
      my $template = Template->new;

      my $output;
      $template->process( \$content, $vars, \$output );

      return $output;
    };
  }

  __PACKAGE__->export_to_level(1);
}

1;

=pod

=head1 NAME

Rex::Ext::TemplateToolkit - A module to process templates with template toolkit.

see http://www.template-toolkit.org/

=head1 SYNOPSIS

 use Rex::Ext::TemplateToolkit;

 task "blah", sub {
   file "/tmp/blah",
        content    => template_toolkit("path/to/blah.template", { persons => ['bob', 'alice'] }),
        owner     => "root",
        group     => "root",
        mode      => 644
 };

=cut
