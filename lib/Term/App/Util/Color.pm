package Term::App::Util::Color;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

our %SPEC;

# return undef if fail to parse
sub __parse_color_depth {
    my $val = shift;
    if ($val =~ /\A\d+\z/) {
        return $val;
    } elsif ($val =~ /\A(\d+)[ _-]?(?:bit|b)\z/) {
        return 2**$val;
    } else {
        # IDEA: parse 'high color', 'true color'?
        return undef;
    }
}

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Determine color depth and whether to use color or not',
};

$SPEC{term_app_should_use_color} = {
    v => 1.1,
    args => {},
    description => <<'_',

Try to determine whether colors should be used. First will check NO_COLOR
environment variable and return false if it exists. Otherwise will check the
COLOR environment variable and use it if it's defined. Otherwise will check the
COLOR_DEPTH environment variable and if defined will use color when color depth
is > 0. Otherwise will check if script is running interactively and when it is
then will use color. Otherwise will not use color.

_
};
sub term_app_should_use_color {
    my $res = [200, "OK", undef, {}];

    if (exists $ENV{NO_COLOR}) {
        $res->[2] = 0;
        $res->[3]{'func.debug_info'}{use_color_from} = 'NO_COLOR env';
        goto RETURN_RES;
    } elsif (defined $ENV{COLOR}) {
        $res->[2] = $ENV{COLOR};
        $res->[3]{'func.debug_info'}{use_color_from} = 'COLOR env';
    } elsif (defined $ENV{COLOR_DEPTH}) {
        my $val = __parse_color_depth($ENV{COLOR_DEPTH}) // $ENV{COLOR_DEPTH};
        $res->[2] = $val ? 1:0;
        $res->[3]{'func.debug_info'}{use_color_from} = 'COLOR_DEPTH env';
        goto RETURN_RES;
    } else {
        require Term::App::Util::Interactive;
        my $interactive_res = Term::App::Util::Interactive::term_app_is_interactive();
        my $color_depth_res = term_app_color_depth();
        $res->[2] = $interactive_res->[2] && $color_depth_res->[2] > 0 ? 1:0;
        $res->[3]{'func.debug_info'}{use_color_from} = 'interactive + color_deth > 0';
        goto RETURN_RES;
    }

  RETURN_RES:
    $res;
}

$SPEC{term_app_color_depth} = {
    v => 1.1,
    args => {},
    description => <<'_',

Try to determine the suitable color depth to use. Will first check COLOR_DEPTH
environment variable and use that if defined. Otherwise will check COLOR
environment variable and use that as color depth if defined and the value looks
like color depth (e.g. `256` or `24bit`). Otherwise will try to detect terminal
emulation software and use the highest supported color depth of that terminal
software. Otherwise will default to 16.

_

};
sub term_app_color_depth {
    my $res = [200, "OK", undef, {}];

    if (defined($ENV{COLOR_DEPTH}) &&
            defined(my $val = __parse_color_depth($ENV{COLOR_DEPTH}))) {
        $res->[2] = $val;
        $res->[3]{'func.debug_info'}{color_depth_from} = 'COLOR_DEPTH env';
        goto RETURN_RES;
    } elsif (defined($ENV{COLOR}) && $ENV{COLOR} !~ /^(|0|1)$/ &&
                 defined(my $val = __parse_color_depth($ENV{COLOR}))) {
        $res->[2] = $val;
        $res->[3]{'func.debug_info'}{color_depth_from} = 'COLOR env';
        goto RETURN_RES;
    } elsif (defined(my $software_info = do {
        require Term::Detect::Software;
        Term::Detect::Software::detect_terminal_cached(); }) {
        $res->[2] = $software_info->{color_depth};
        $res->[3]{'func.debug_info'}{color_depth_from} = 'detect_terminal';
        goto RETURN_RES;
    } else {
        $res->[2] = 16;
        $res->[3]{'func.debug_info'}{color_depth_from} = 'default';
        goto RETURN_RES;
    }

  RETURN_RES:
    $res;
}

1;
# ABSTRACT:

=head1 DESCRIPTION


=head1 ENVIRONMENT

=head2 COLOR

=head2 COLOR_DEPTH

=head2 NO_COLOR


=head1 SEE ALSO

Other C<Term::App::Util::*> modules.

L<Term::Detect::Software>
    
