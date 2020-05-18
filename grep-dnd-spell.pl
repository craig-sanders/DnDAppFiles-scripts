#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Text::Wrap;
use XML::LibXML;
use Getopt::Long;
use Pod::Usage;

$Pod::Usage::Formatter = 'Pod::Text::Termcap';
Getopt::Long::Configure('no_ignore_case');

# env var DnDAppFiles needs to be set to the root dir of the DnDAppFiles repo
my $filename='';
if ($ENV{'DnDAppFiles'}) {
  $filename = $ENV{'DnDAppFiles'} . '/Compendiums/Spells Compendium.xml';
} else {
  die "DnDAppFiles Env variable is not set"
};

my $dom = XML::LibXML->load_xml(location => $filename);

# subrouting forward declarations
sub stat_to_bonus;
sub fields_hash;
sub print_spell;
sub debug;

# stop complaints about wide characters
binmode(STDOUT, "encoding(UTF-8)");

my (@name,@school,@level,@time,@range,@duration,@classes,@components,@ritual,@search) = ();
my ($name,$school,$level,$time,$range,$duration,$classes,$components,$ritual,$search) = qw(. . . . . . . . . .);
my $logical_or=0;
my $help=0;
my $man=0;
my $debug=0;
my $unformatted=0;
#my $block=0;

GetOptions ("name=s"       => \@name,
            "school=s"     => \@school,
            "level=s"      => \@level,
            "range=s"      => \@range,
            "duration=s"   => \@duration,
            "time=s"       => \@time,
            "classes=s"    => \@classes,
            "Components=s" => \@components,
            "ritual=s"     => \@ritual,
            "full=s"       => \@search,

            "or"           => \$logical_or,
            "unformatted"  => \$unformatted,

            "help|?"       => \$help,
            "Debug"        => \$debug,
            "man"          => \$man,
           ) || die("Error in command line arguments\n");

pod2usage(2) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

#print "argv  =" . join('|',@ARGV), "\n";
# append or replace any remaining @ARGV strings to @search.
if (@search) {
  push @search,@ARGV
} else {
  @search = @ARGV
};

if ($logical_or) {
  # build regexp strings containing | alternations.
  $name        = join('|',@name      ) if (@name      );
  $school      = join('|',@school    ) if (@school    );
  $level       = join('|',@level     ) if (@level     );
  $range       = join('|',@range     ) if (@range     );
  $duration    = join('|',@duration  ) if (@duration  );
  $time        = join('|',@time      ) if (@time      );
  $classes     = join('|',@classes   ) if (@classes   );
  $components  = join('|',@components) if (@components);
  $ritual      = join('|',@ritual    ) if (@ritual    );
  $search      = join('|',@search    ) if (@search    );
} else {
  # build regexp strings containing postive look-aheads.
  @name = map { "(?=.*$_)" } @name if (@name);
  $name = join('',@name) if (@name);

  @school = map { "(?=.*$_)" } @school if (@school);
  $school = join('',@school) if (@school);

  @level = map { "(?=.*$_)" } @level if (@level);
  $level = join('',@level) if (@level);

  @range = map { "(?=.*$_)" } @range if (@range);
  $range = join('',@range) if (@range);

  @duration = map { "(?=.*$_)" } @duration if (@duration);
  $duration = join('',@duration) if (@duration);

  @time = map { "(?=.*$_)" } @time if (@time);
  $time = join('',@time) if (@time);

  @classes = map { "(?=.*$_)" } @classes if (@classes);
  $classes = join('',@classes) if (@classes);

  @components = map { "(?=.*$_)" } @components if (@components);
  $components = join('',@components) if (@components);

  @ritual = map { "(?=.*$_)" } @ritual if (@ritual);
  $ritual = join('',@ritual) if (@ritual);

  @search = map { "(?=.*$_)" } @search if (@search);
  $search = join('',@search) if (@search);
};

debug if ($debug);

die "need something to search for" if ((join "", $name,$school,$level,$time,$range,$duration,$components,$classes,$ritual,$search) eq '.' x 10) ;

my $noritual = $dom->createElement('ritual');
$noritual->appendText('NO');

foreach my $spell ($dom->findnodes('/compendium/spell')) {
  $spell->appendChild($noritual) unless ($spell->findvalue('./ritual'));

  if ( ($spell->textContent =~ m/$search/mio) &&
       ($spell->findvalue('./name')       =~ m/$name/io) &&
       ($spell->findvalue('./school')     =~ m/$school/io) &&
       ($spell->findvalue('./level')      =~ m/$level/io) &&
       ($spell->findvalue('./range')      =~ m/$range/io) &&
       ($spell->findvalue('./duration')   =~ m/$duration/io) &&
       ($spell->findvalue('./time')       =~ m/$time/io) &&
       ($spell->findvalue('./classes')    =~ m/$classes/io) &&
       ($spell->findvalue('./components') =~ m/$components/io) &&
       ($spell->findvalue('./ritual')     =~ m/$ritual/io)
     ) {

    print_spell($spell);
    # output 2 blank lines between spells
    print "\n\n";
  };
};

sub debug {
  print "search      = '$search'\n";
  print "name        = '$name'\n";
  print "school      = '$school'\n";
  print "level       = '$level'\n";
  print "range       = '$range'\n";
  print "duration    = '$duration'\n";
  print "time        = '$time'\n";
  print "classes     = '$classes'\n";
  print "components  = '$components'\n";
  print "ritual      = '$ritual'\n";
};

sub stat_to_bonus {
  my $st = shift;
  return int(($st-10)/2);
};

sub fields_hash;

sub print_spell {
  my $s = shift;

  local $Text::Wrap::columns = 78;
  my $out='';

  my %fields = %{ &fields_hash };

  foreach (qw(name level school ritual time range components duration classes)) {
     my $v = $s->findvalue($_);
     #if ($v) {
       $out .= sprintf "%s: %s\n", $fields{$_}, $v;
     #}
  };

  my $text = join "\n", map {
    $_->to_literal();
  } $s->findnodes('./text');

  $text =~ s/\*/\\*/g;
  $text =~ s/\s*([+-])\s*(\d+)/$1$2/g;

  $out .= "\n$text\n";
  $out =~ s/\n\n\n+/\n\n/gm;

  if ($unformatted) {
    print $out;
  } else {
    print wrap("","",$out);
  };
};

sub fields_hash {
  my %fields = (
       'name'        => 'Name',
       'level'       => 'Level',
       'school'      => 'School',
       'ritual'      => 'Ritual',
       'time'        => 'Time',
       'range'       => 'Range',
       'components'  => 'Components',
       'duration'    => 'Duration',
       'classes'     => 'Classes',
       'roll'        => 'Roll',
  );

  return \%fields;
};

__END__

=head1 NAME

grep-dnd-spell.pl -- Search the DnDAppFiles XML files for spell details.

=head1 SYNOPSIS

grep-dnd-spell.pl [options] [regexp...]

Search Options:

  -n, --name        <regexp>   search Names
  -s, --school      <regexp>   search schools
  -l, --level       <regexp>   search levels
  -c, --classes     <regexp>   search levels
  -C, --Component   <regexp>   search Creature Rating
  -r, --ritual      [Y|N]      search for ritual spells
  -f, --full        <regexp>   full-text search of spell descriptions.

Each of these options can be used multiple times, with multiples of the same
option AND-ed together by default.  They can be OR-ed together with the --or
option.

The combined options will be AND-ed together.

Any remaining arguments on the command line will be added to the full-text
search regexp.

Misc  Options:

  -o, --or             Search options are OR-ed together rather
                       than AND-ed.  If used, this applies to all search
                       options.

  -h, --help           brief help message
  -m, --man            view POD man page

=head1 OPTIONS

=over 8

=item B<-n>, B<--name> <regexp>

Search the spell names.

=item B<-s>, B<--school> <regexp>

Search the spell schools.

=item B<-l>, B<--level> <regexp>

Search the spell levels.

=item B<-c>, B<--classes> <regexp>

Search the spell classes.

=item B<-C>, B<--Components> <regexp>

Search the spell components list.

=item B<-r>, B<--ritual>, [Y|N]

Search for spells which are (or are not) rituals.  Default is either.

=item B<-f>, B<--full> <regexp>

Full text search of spell descriptions.

=item B<-h>, B<--help>

Print a brief help message and exit.

=item B<-o>, B<--or>

Search options with multiple elements are OR-ed together rather than AND-ed.
If used, this option applies to all search options.

=back

=head1 EXAMPLES

=over 8

=item B<grep-dnd-spell.pl -n '^Find Familiar$'>

Search for a spell whose name exactly matches "Find Familiar".

=item B<grep-dnd-spell.pl -c Wizard -l 0>

Search for all Wizard Cantrips

=item B<grep-dnd-spell.pl -c Druid --ritual Y -l 1>

Search for all 1st level Druid ritual spells.

=item B<grep-dnd-spell.pl -c wizard -s 'en|i' -l [1-3]>

Search for all 1st-3rd level Wizard spells in the schools of Enchantment or
Illusion (useful for Arcane Tricksters)

=back

=head1 DESCRIPTION

=over 8

B<This program> will search the DnDAppFiles XML files for spell details.

=back

=cut

