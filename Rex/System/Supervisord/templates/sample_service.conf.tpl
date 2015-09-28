[program:<%= $settings->{program_name} %>]
process_name=%(program_name)s_%(process_num)02d
<% foreach my $s (keys %{$settings}) {
    next if ($s eq 'program_name'); %>
<%= $s %>=<%= $settings->{$s} %>
<% } %>
