
These scripts are intended to be used with the Compendium XML files from
https://github.com/Cphrampus/DnDAppFiles

1. You need to `git clone` that repo to somewhere on your disk, `cd` to it, and
run the `create_compendiums.py` script.
 
 e.g.
 
    mkdir -p ~/git/rpg
    cd ~/git/rpg
    git clone https://github.com/Cphrampus/DnDAppFiles
    cd DnDAppFiles
    ./create_compendiums.py


2. Then you need to modify each of my scripts to point to the correct file in
your system.
 
 e.g. on my system:
 
    $ grep filename.*xml *
    grep-dnd-items.pl:my $filename = '/home/cas/git/rpg/DnDAppFiles/Compendiums/Items Compendium.xml';
    grep-dnd-monster.pl:my $filename = '/home/cas/git/rpg/DnDAppFiles/Compendiums/Bestiary Compendium.xml';
    grep-dnd-spell.pl:my $filename = '/home/cas/git/rpg/DnDAppFiles/Compendiums/Spells Compendium.xml';


3. From time to time, you'll need to update the XML files to get the latest data:
 
    cd ~/git/rpg/DnDAppFiles
    git pull
    ./create_compendiums.py


