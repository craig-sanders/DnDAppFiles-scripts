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
  $filename = $ENV{'DnDAppFiles'} . '/Compendiums/Items Compendium.xml';
} else {
  die "DnDAppFiles Env variable is not set"
};

my $dom = XML::LibXML->load_xml(location => $filename);

sub print_item;
sub debug;

# stop complaints about wide characters
binmode(STDOUT, "encoding(UTF-8)");

### my $nomatch = 'this will never ever ever be matched in a billion years or more!!';
### my $search  = $nomatch;
### my $name    = $nomatch;
### my $type    = $nomatch;
### my $rarity  = $nomatch;
### my $classes = $nomatch;
### 
### # Insert Getopt processing here.
### # for now, do a full-text search of the node.
### $search  = shift || '.';

my (@name,@type,@rarity,@classes,@search) = ();
my ($name,$type,$rarity,$classes,$search) = qw(.? .? .? .? .?);
my $logical_or=0;
my $help=0;
my $man=0;
my $debug=0;
my $unformatted=0;
#my $block=0;

GetOptions ("name=s"       => \@name,
            "type=s"       => \@type,
            "rarity=s"     => \@rarity,
#            "classes=s"    => \@classes,
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
  $name    = join('|',@name   ) if (@name   );
  $type    = join('|',@type   ) if (@type   );
  $rarity  = join('|',@rarity ) if (@rarity );
  $classes = join('|',@classes) if (@classes);
  $search  = join('|',@search ) if (@search );
} else {
  # build regexp strings containing postive look-aheads.
  @name = map { "(?=.*$_)" } @name if (@name);
  $name = join('',@name) if (@name);

  @type = map { "(?=.*$_)" } @type if (@type);
  $type = join('',@type) if (@type);

  @rarity = map { "(?=.*$_)" } @rarity if (@rarity);
  $rarity = join('',@rarity) if (@rarity);

  @classes = map { "(?=.*$_)" } @classes if (@classes);
  $classes = join('',@classes) if (@classes);

  @search = map { "(?=.*$_)" } @search if (@search);
  $search = join('',@search) if (@search);
};

debug if ($debug);

die "need something to search for" if ((join "", $name,$type,$rarity,$classes,$search) eq '.?' x 5) ;


foreach my $item ($dom->findnodes('/compendium/item')) {

  #print_item($item) if ($item->findvalue('./name')    =~ m/$name/io);
  if ( ($item->textContent =~ m/$search/mio) &&
       ($item->findvalue('./name')    =~ m/$name/io) &&
       ($item->findvalue('./type')    =~ m/$type/io) &&
       ($item->findvalue('./rarity')  =~ m/$rarity/io) &&
       ($item->findvalue('./classes') =~ m/$classes/io)
     ) {
    print_item($item);
    # output 2 blank lines between items
    print "\n\n";
  };
};

sub debug {
  print "search      = '$search'\n";
  print "name        = '$name'\n";
  print "type        = '$type'\n";
  print "rarity      = '$rarity'\n";
#  print "classes     = '$classes'\n";
};


sub fields_hash;

sub print_item {
  my $i   = shift;

  local $Text::Wrap::columns = 78;
  my $out='';

  my %fields = %{ &fields_hash };

  foreach (qw(name type rarity weight value range strength stealth property classes)) {
     my $v = $i->findvalue($_);
     if ($v) {
       $out .= sprintf "%s: %s\n", $fields{$_}, $v;
     }
  };

  my $text = join "\n", map {
    $_->to_literal();
  } $i->findnodes('./text');

  $text =~ s/\*/\\*/g;
  $text =~ s/\s*Rarity:[^[:cntrl:]]*\n//gm;
  $text =~ s/\n\s+/\n\n/gm;
  $text =~ s/\n/\n\n/gm;
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
       'type'        => 'Type',
       'ac'          => 'Armor Class',
       'range'       => 'Range',
       'rarity'      => 'Rarity',
       'detail'      => 'Detail',
       'property'    => 'Property',
       'stealth'     => 'Stealth',
       'duration'    => 'Duration',
       'classes'     => 'Classes',
       'roll'        => 'Roll',
       'strength'    => 'Strength',
       'value'       => 'Value',
       'weight'      => 'Weight',
  );

  return \%fields;
};



=head1 NAME

grep-dnd-item.pl -- Search the DnDAppFiles XML files for item details.

=head1 SYNOPSIS

grep-dnd-item.pl [options] [regexp...]

Search Options:

  -n, --name        <regexp>   search Names
  -t, --type        <regexp>   search types
  -r, --rarity      <regexp>   search rarities
  -f, --full        <regexp>   full-text search of item descriptions.

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

Search the item names.

=item B<-t>, B<--type> <regexp>

Search the item type.

=item B<-r>, B<--rarity> <regexp>

Search the item rarities.

=item B<-c>, B<--classes> <regexp>

Search the item classes.

=item B<-f>, B<--full> <regexp>

Full text search of item descriptions.

=item B<-h>, B<--help>

Print a brief help message and exit.

=item B<-o>, B<--or>

Search options with multiple elements are OR-ed together rather than AND-ed.
If used, this option applies to all search options.

=back

=head1 EXAMPLES

=over 8

=item B<grep-dnd-item.pl -n '^Wand of Viscid Globs$'>

Search for an item whose name exactly matches "Wand of Viscid Globs".

=item B<grep-dnd-item.pl -n viscid>

Search for items whose name contains the word "viscid".

=item B<grep-dnd-item.pl -n ring>

Search for all rings.

=back

=head1 DESCRIPTION

=over 8

B<This program> will search the DnDAppFiles XML files for item details.

=back

=cut

