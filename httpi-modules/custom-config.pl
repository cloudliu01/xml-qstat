# This file contains custom questions for configuring the HTTPi-xmlqstat
# It hooks into the configure system provided by HTTPi-1.6.2 and above

# get GridEngine arch/lib information
print <<"PROMPT";

GridEngine configuration
------------------------
Trying to determine the architecture and library requirements
PROMPT

( $DEF_SGE_ARCH, $DEF_LIBENV ) = ( '', '' );

if ( $ENV{SGE_ROOT} and -d $ENV{SGE_ROOT} ) {
    my $archScript = &detaint( $ENV{SGE_ROOT} ) . "/util/arch";

    # use 'arch' script if possible
    print "... checking what '$archScript' reports\n";

    chomp( $DEF_SGE_ARCH = qx{$archScript} );
    if ($DEF_SGE_ARCH) {
        chomp( $DEF_LIBENV = qx{$archScript -lib 2>/dev/null} );
    }
    else {
        print "Hmm. Couldn't seem to execute $archScript\n";
    }
}

if ($DEF_SGE_ARCH) {
    print "Using $DEF_SGE_ARCH for the GridEngine architecture\n";
}
else {
    print
"Couldn't get GridEngine architecture automatically, need to do it ourselves\n";
    $DEF_SGE_ARCH = "undef";
}

while (1) {
    $DEF_SGE_ARCH = &prompt( <<"PROMPT", $DEF_SGE_ARCH, 1 );

Define the architecture used for the GridEngine commands.
This should correspond to the value emitted by the \$SGE_ROOT/util/arch

Hint: the 'arch' value here should allow us to find
\$SGE_ROOT/bin/<arch>/qstat

Which value should be used for the GridEngine architecture?
PROMPT

    if ( $DEF_SGE_ARCH eq "undef" or not $DEF_SGE_ARCH ) {
        print <<"PROMPT";
The GridEngine architecture value '$DEF_SGE_ARCH' looks implausible
Please try again ...

PROMPT
    }
    else {
        last;
    }
}

# library path setting for architectures where RUNPATH is not supported
if ( $DEF_SGE_ARCH =~ /^(lx|sol)/ or $DEF_SGE_ARCH eq "hp11-64" ) {
    print "Good. We can apparently use RUNPATH for this architecture!\n";
    $DEF_LIBENV = '';
}
else {
    $DEF_LIBENV = &prompt( <<"PROMPT", 'LD_LIBRARY_PATH', 1 );

Define the name of the dynamic link library environment variable
for your machine. This is needed to load the GridEngine libraries.

Which environment variable is used for the libraries?
PROMPT
}

# get the name of the web application
$DEF_XMLQSTAT_WEBAPPNAME = &prompt( <<"PROMPT", 'grid', 1 );

xml-qstat customization:
------------------------
Serve this web application under which resource name:?
PROMPT

$DEF_XMLQSTAT_WEBAPPNAME =~ s{^/+|/+$}{}g;    # no leading/trailing slashes
$DEF_XMLQSTAT_WEBAPPNAME =~ s{^//+}{/}g;      # double slashes

# get xmlqstat root
$DEF_XMLQSTAT_ROOT =
  &interprompt( <<"PROMPT", '~/xml-qstat', 1, \&inter_homedir );

xml-qstat customization:
------------------------
Specify where the xml-qstat root is located.
The 'web-app' directory under this root will be served by HTTPi
as the resource '/$DEF_XMLQSTAT_WEBAPPNAME'.

You can use Perl variables for this option (example: \$ENV{'HOME'}/xml-qstat).
As a shortcut, ~/ in first position will be turned into \$ENV{'HOME'}/,
which is "$ENV{'HOME'}/".

xml-qstat resource root:?
PROMPT

# verify directory plausibility
for ($DEF_XMLQSTAT_ROOT) {
    if (    -d $_
        and -d "$_/web-app"
        and -d "$_/web-app/css"
        and -d "$_/web-app/xsl" )
    {
        print <<"PROMPT";
Okay. The directory '$_'
Seems to have the correct directory structure.

PROMPT
    }
    else {
        print <<"PROMPT";
WARNING: The directory '$_'
Does not appear to contain the correct directory structure!!

PROMPT
    }
}

$DEF_XMLQSTAT_TIMEOUT = &prompt( <<"PROMPT", '20', 1 );

------------------------
xml-qstat customization:
Define the maximum timeout (seconds) when executing GridEngine commands
PROMPT

1;    # loaded ok

# ----------------------------------------------------------------- end-of-file
