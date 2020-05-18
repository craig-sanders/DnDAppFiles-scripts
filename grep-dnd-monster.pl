#!/usr/bin/perl

# Copyright Craig Sanders 2020
#
# Licensed under the terms of the GNU General Public License,
# version 3 or any later version.
#
# code available at https://github.com/craig-sanders/DnDAppFiles-scripts

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
  $filename = $ENV{'DnDAppFiles'} . '/Compendiums/Bestiary Compendium.xml';
} else {
  die "DnDAppFiles Env variable is not set"
};

# FIXME loop over all .xml files in DndAppFiles/Bestiary rather than require
# the compendium
my $dom = XML::LibXML->load_xml(location => $filename);

# subrouting forward declarations
sub stat_to_bonus;
sub fields_hash;
sub cr_hash;
sub print_monster;
sub debug;

# stop complaints about wide characters
binmode(STDOUT, "encoding(UTF-8)");

my (@name,@type,@size,@cr,@search) = ();
my ($name,$type,$size,$cr,$search) = qw(. . . . .);
my $logical_or=0;
my $help=0;
my $man=0;
my $debug=0;
my $block=0;

GetOptions ("name=s"      => \@name,
            "type=s"      => \@type,
            "size=s"      => \@size,
            "cr=s"        => \@cr,
            "full=s"      => \@search,

            "or"          => \$logical_or,

            "block"       => \$block,

            "help|?"      => \$help,
            "debug"       => \$debug,
            "man"         => \$man,
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
  $name   = join('|',@name  ) if (@name  );
  $type   = join('|',@type  ) if (@type  );
  $size   = join('|',@size  ) if (@size  );
  $cr     = join('|',@cr    ) if (@cr    );
  $search = join('|',@search) if (@search);
} else {
  # build regexp strings containing postive look-aheads.
  @name = map { "(?=.*$_)" } @name if (@name);
  $name = join('',@name) if (@name);

  @type = map { "(?=.*$_)" } @type if (@type);
  $type = join('',@type) if (@type);

  @size = map { "(?=.*$_)" } @size if (@size);
  $size = join('',@size) if (@size);

  @cr = map { "(?=.*$_)" } @cr if (@cr);
  $cr = join('',@cr) if (@cr);

  @search = map { "(?=.*$_)" } @search if (@search);
  $search = join('',@search) if (@search);
};

debug if ($debug);

die "need something to search for" if ("$name$type$size$cr$search" eq ".....") ;

foreach my $monster ($dom->findnodes('/compendium/monster')) {

  if ( ($monster->textContent =~ m/$search/mio) &&
       ($monster->findvalue('./name') =~ m/$name/io) &&
       ($monster->findvalue('./type') =~ m/$type/io) &&
       ($monster->findvalue('./size') =~ m/$size/io) &&
       ($monster->findvalue('./cr')   =~ m/$cr/io)
     ) {
    print_monster($monster);
    print "\n\n";
  };
};

sub debug {
  print "search = '$search'\n";
  print "name   = '$name'\n";
  print "type   = '$type'\n";
  print "size   = '$size'\n";
  print "cr     = '$cr'\n";
};

sub stat_to_bonus {
  my $s = shift;
  return int(($s-10)/2);
};

sub print_monster {
  my $m   = shift;

  local $Text::Wrap::columns = 86;
  my $out='';

  my %fields = %{ &fields_hash };
  my %crtable = %{ &cr_hash };

  foreach (qw(name size type alignment ac hp speed)) {
     my $v = $m->findvalue($_);
     $v = 'special' unless ($v);
     #if ($v) {
       $out .= sprintf "%s: %s\n", $fields{$_}, $v;
     #}
  };

  my $statblock='Stats: ';
  foreach my $stat (qw(str dex con int wis cha)) {
    my $s = $m->findvalue('./'.$stat);

    $statblock .= sprintf("%s %2i (%+2d)  ", uc($stat), $s, stat_to_bonus($s));
  }
  $out .= "$statblock\n";

  foreach (qw(save vulnerable resist immune conditionImmune skill passive senses languages slots description cr spells )) {
     my $v = $m->findvalue($_);
     $v =~ s/\*/\\*/g;
     if ($v) {
       $v = "$v (" . $crtable{$v} . " xp)" if ($_ eq 'cr');

       $out .= "\n" if (m/spells/);
       $out .= sprintf "%s: %s\n", $fields{$_}, $v;
     }
  };

  if(!$block) {
    foreach my $block ( qw(trait action reaction legendary) ) {
      $out .= "\n$fields{$block}:\n" if ($m->findnodes($block));

      foreach my $t ($m->findnodes($block)) {
        my $name = $t->findvalue('./name');

        my $text = join "\n", map {
          "" . $_->to_literal();
        } $t->findnodes('./text');

        $text =~ s/\*/\\*/g;
        $text =~ s/\s*([+-])\s*(\d+)/$1$2/g;

        if ($name) {
          $out .= "\n$name: ";
        };
        $out .= sprintf "%s\n", $text;
      };
    };
  };

  print wrap("","",$out);
};


sub cr_hash {
  my %crtable = (
   '0' => '0 or 10', '1/8' => '25',     '1/4' => '50',    '1/2' => '100',
   '1' => '200',       '2' => '450',      '3' => '700',     '4' => '1100',
   '5' => '1800',      '6' => '2300',     '7' => '2900',    '8' => '3900',
   '9' => '5000',     '10' => '5900',    '11' => '7200',   '12' => '8400',
  '13' => '10000',    '14' => '11500',   '15' => '13000',  '16' => '15000',
  '17' => '18000',    '18' => '20000',   '19' => '22000',  '20' => '25000',
  '21' => '33000',    '22' => '41000',   '23' => '50000',  '24' => '62000',
  '25' => '75000',    '26' => '90000',   '27' => '105000', '28' => '120000',
  '29' => '135000',   '30' => '155000',
  );

  return \%crtable;
};

sub fields_hash {
  my %fields = (
       'name'             => 'Name',
       'size'             => 'Size',
       'type'             => 'Type',
       'alignment'        => 'Alignment',
       'ac'               => 'Armor Class',
       'hp'               => 'Hit Points',
       'speed'            => 'Speed',

       'str'              => 'STR',
       'dex'              => 'DEX',
       'con'              => 'CON',
       'int'              => 'INT',
       'wis'              => 'WIS',
       'cha'              => 'CHA',

       'save'             => 'Saving Throws',
       'vulnerable'       => 'Damage Vulnerabilities',
       'resist'           => 'Damage Resistances',
       'immune'           => 'Damage Immunities',
       'conditionImmune'  => 'Condition Immunities',

       'skill'            => 'Skills',
       'passive'          => 'Passive Perception',
       'senses'           => 'Senses',
       'languages'        => 'Languages',
       'spells'           => 'Spells',
       'slots'            => 'Spell Slots',
       'description'      => 'Description',
       'cr'               => 'Cr',

       'trait'            => 'Traits',
       'action'           => 'Actions',
       'reaction'         => 'Reactions',
       'legendary'        => 'Legendary Actions',
  );

  return \%fields;
};



__END__

=head1 NAME

grep-dnd-monster.pl -- Search the DnDAppFiles XML files for monster details.

=head1 SYNOPSIS

grep-dnd-monster.pl [options] [regexp...]

Search Options:

  -n, --name <regexp>   search Names
  -t, --type <regexp>   search Types (beast, abberration, etc)
  -s, --size <regexp>   search Size
  -c, --cr   <regexp>   search Creature Rating
  -f, --full <regexp>   full-text search of monster descriptions.

Each of these options can be used multiple times, with multiples of the same
option AND-ed together by default.  They can be OR-ed together with the --or
option.

The combined options will be AND-ed together.

Any remaining arguments on the command line will be added to the full-text
search regexp.

=cut

#  --Stats               All of the above. Just the basic stat block. No traits, actions, etc.

=pod

Misc  Options:

  -b, --block          Output basic stat-block only

  -o, --or             Search options are OR-ed together rather
                       than AND-ed.  If used, this applies to all search
                       options.

  -h, --help           brief help message
  -m, --man            view POD man page

=head1 OPTIONS

=over 8

=item B<-n>, B<--name> <regexp>

Search the monster names.

=item B<-t>, B<--type> <regexp>

Search the monster types.

=item B<-s>, B<--size> <regexp>

Search the monster sizes.

=item B<-c>, B<--cr> <regexp>

Search the monster Creature Rating.

=item B<-f>, B<--full> <regexp>

Full text search of monster descriptions.

=item B<-b>, B<--block>

Print only the basic stat block, without traits, actions, reactions, or legendary actions.

=item B<-h>, B<--help>

Print a brief help message and exit.

=item B<-o>, B<--or>

Search options with multiple elements are OR-ed together rather than AND-ed.
If used, this option applies to all search options.

=back

=head1 EXAMPLES

=over 8

=item B<grep-dnd-monster.pl -n '^goblin$'>

Search for a monster whose name exactly matches "goblin".

=item B<grep-dnd-monster.pl -t beast -cr 2>

Search for all beasts with creature rating of 2.

=item B<grep-monster.pl -n green -n dragon -n adult>

Search for all monsters where the name contains B<all> of 'green' and 'dragon'
and 'adult'.

=item B<grep-dnd-monster.pl -n green -n dragon -n adult -o>

Search for all monsters where the name contains either 'green' or 'dragon' or 'adult'.

=back

=head1 DESCRIPTION

=over 8

B<This program> will search the DnDAppFiles XML files for monster details.

=back

=cut

