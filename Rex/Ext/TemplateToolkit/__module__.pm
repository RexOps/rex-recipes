#
# Nicolas Leclercq <nicolas.private@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Ext::TemplateToolkit;

use Rex -base;
use Rex::Helper::Path;
use Template;

require Exporter;
use base qw(Exporter);
use vars qw (@EXPORT);

@EXPORT = qw(template_toolkit);


sub validate_vars {
  my ( $vars ) = @_;

  foreach my $key (keys %$vars) {
      if ($key ~= /^[\._]/) {
	  Rex::Logger::info( "variable name '$key' considered private by Template Toolkit",
			     "warn" );
      } elsif ($key ~= /([^a-zA-Z0-9_])/) {
	  Rex::Logger::info( "variable name '$key' contains '$1' unsupported by Template Toolkit",
			     "warn" );
      } elsif ($key ~= /^(GET|CALL|SET|DEFAULT|INSERT|INCLUDE|PROCESS|WRAPPER|IF|UNLESS|ELSE|ELSIF|FOR|FOREACH|WHILE|SWITCH|CASE|USE|PLUGIN|FILTER|MACRO|PERL|RAWPERL|BLOCK|META|TRY|THROW|CATCH|FINAL|NEXT|LAST|BREAK|RETURN|STOP|CLEAR|TO|STEP|AND|OR|NOT|MOD|DIV|END)$/) {
	  Rex::Logger::info( "variable name '$key' clashes with reserved Template Toolkit word",
			     "warn" );
      }
  }
}

sub template_toolkit {
  my ( $template_path, $vars ) = @_;

  validate_vars( $vars );

  # resolv template path
  $template_path = Rex::Helper::Path::resolv_path($template_path);
  $template_path = Rex::Helper::Path::get_file_path( $template_path, caller() );
  Rex::Logger::debug("Processing template file : $template_path");

  # process template
  my $output = '';
  my $template = Template->new( { ABSOLUTE => 1 } );
  $template->process( $template_path, $vars, \$output )
    || Rex::Logger::info( $template->error(), 'error' );

  return $output;
}

sub import {

  my ( $class, $tag ) = @_;

  if ( $tag && $tag eq ":register" ) {

    # register Template::Toolkit for default template processing
    set template_function => sub {
      my ( $content, $vars ) = @_;
      
      validate_vars( $vars );

      my $template = Template->new;

      my $output;
      $template->process( \$content, $vars, \$output )
        || Rex::Logger::info( $template->error(), 'error' );

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

 # to use as a default template engine
 # this will make the template() function use TemplateTookit to render
 # all the templates. This will also register all the known template variables
 # like hostname, eth0_ip and so on.
 use Rex::Ext::TemplateTookkit ':register';

=cut
