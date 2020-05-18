
These scripts are intended to be used with the Compendium XML files from
https://github.com/Cphrampus/DnDAppFiles

All scripts in this repo are licensed under the terms of the GNU General Public
License, version 3 or later.

1. You need to `git clone` that repo to somewhere on your disk, `cd` to it, and
run the `create_compendiums.py` script.

e.g.

```
mkdir -p ~/git/rpg
cd ~/git/rpg
git clone https://github.com/Cphrampus/DnDAppFiles
cd DnDAppFiles
./create_compendiums.py
```


2. Then you need to export an environment variable called 'DnDAppFiles' to point to
the top-level directory of the DnDAppFiles repository.  Add it to your `.bashrc` or
whatever.  For example:

```
export DnDAppFiles="$HOME/git/rpg/DnDAppFiles"

```

3. From time to time, you'll need to update the XML files to get the latest data:

e.g.

```
cd ~/git/rpg/DnDAppFiles
git pull
./create_compendiums.py
```

### Examples


 * grep-dnd-items.pl
 * grep-dnd-monster.pl
 * grep-dnd-spell.pl

These do what they say in the filename, with various options for limiting
the search to attributes like name, spell level, creature type (beast, fey,
whatever), item rarity, etc.  Default is a full-text search.  Because the
scripts are written in perl, the search strings are all treated as perl regular
expressions.

Output is plain text for viewing in a terminal.

e.g. to find all spells with **familiar** in the name:

```
$ grep-dnd-spell.pl -n familiar
Name: Find Familiar
Level: 1
School: C
Ritual: YES
Time: 1 hour
Range: 10 feet
Components: V, S, M (10 gp worth of charcoal, incense, and herbs that must be
consumed by fire in a brass brazier)
Duration: Instantaneous
Classes: Wizard

[...full text description deleted...]

```

Or to get the stat block of an **orc** (using an exact match regex to exclude
all other creatures with "orc" somewhere in the name):

```
$ ./grep-dnd-monster.pl -n ^orc$
Name: Orc
Size: M
Type: humanoid (orc)
Alignment: chaotic evil
Armor Class: 13 (hide armor)
Hit Points: 15 (2d8+6)
Speed: 30 ft.
Stats: STR 16 (+3)  DEX 12 (+1)  CON 16 (+3)  INT  7 (-1)  WIS 11 (+0)	CHA 10 (+0)  
Skills: Intimidation +2
Passive Perception: 10
Senses: darkvision 60 ft.
Languages: Common, Orc
Description: Source: Monster Manual
Cr: 1/2 (100 xp)

[...full text description deleted...]

```

Or to find items with **Magic Missile** in the name.

```
$ ./grep-dnd-items.pl -n magic.missile
Name: Wand of Magic Missiles
Type: WD
Rarity: Uncommon
Weight: 1

[...full text description deleted...]
```


 * list-spells.sh

This one generates a list of spells matching the search criteria.  It's a
simple wrapper around `grep-dnd-spell.pl` that I find useful to, e.g., list all
Cleric cantrips:

```
$ ./list-spells.sh -l 0 cleric
Level: 0   School: A  Name: Resistance                         Classes: Cleric, Druid
Level: 0   School: D  Name: Guidance                           Classes: Cleric, Druid
Level: 0   School: EV Name: Light                              Classes: Bard, Cleric, Sorcerer, Wizard
Level: 0   School: EV Name: Sacred Flame                       Classes: Cleric
Level: 0   School: EV Name: Word of Radiance                   Classes: Cleric
Level: 0   School: N  Name: Spare the Dying                    Classes: Cleric
Level: 0   School: N  Name: Toll the Dead                      Classes: Cleric, Warlock, Wizard
Level: 0   School: T  Name: Mending                            Classes: Bard, Cleric, Druid, Sorcerer, Wizard
Level: 0   School: T  Name: Thaumaturgy                        Classes: Cleric

```
