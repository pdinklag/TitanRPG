TitanRPG
========
TitanRPG is a complete standalone roleplaying game mutator for Unreal Tournament 2004 based on ideas introduced in UT2004RPG and DruidsRPG.

Building
--------
TitanRPG can be built like any other UT2004 package. The following steps are necessary:

* Clone the repository into your UT2004 installation directory (so that the TitanRPG directory is on the same level as e.g. *System* or *Animations*).
* Add `OnslaughtBP` and `TitanRPG` to the `EditPackages` list in your `UT2004.ini` file.
* Switch to your installation's `System` directory.
* Remove any existing `TitanRPG.u` file.
* Execute the command line `ucc make`.

Version Customization
---------------------
If you use a public redirect, it may be a bad idea to use the file name `TitanRPG.u` for custom builds. TitanRPG is now written in a way where it can dynamically handle any package name. What this means is that you can rename `TitanRPG.u` to whatever you want, e.g. `MyAwesomeRPG.u`. Note that the names of the ini files need to remain the same, however.

When you rename the package file, you need to edit `TitanRPG.ini` so that all occurences of `TitanRPG.` (mind the dot!) are replaced by e.g. `MyAwesomeRPG.`, ie the file name without the "u".

In the `[MutTitanRPG]` section (the first in the ini), you can also define the `CustomVersion` field using any text you like. For instance, if you set it to "My awesome RPG v1337", that text will be displayed in the server browser instead of "TitanRPG v1.XX".

Documentation State
-------------------
The documentation is severely outdated, since the last public release was version 1.60 and there have been major changes since. The `TitanRPG.ini` file, however, is up to date and can be used as a documentation of sorts.

Credits
-------
TitanRPG contains code written by the following people:

* **Mysterial**
-- The creator of the original UT2004RPG. Although there is not too much left of UT2004RPG in TitanRPG internally, TitanRPG was based on UT2004RPG and still uses the original ideas.
* **TheDruidXpawX & Shantara**
-- These two are responsible for DruidsRPG, which can be considered the biggest and most influential addendum to UT2004RPG. It, too, represented a foundation of TitanRPG.
* **fluffy**
-- The first developer of TitanRPG, who created several extras for UT2004RPG and DruidsRPG for the historic TitanOnslaught VCTF RPG server.
* **Jrubzjeknf**
-- Creator of the Mantarun Assist and RPGFlags mutators. He also helped fluffy contribute several features and fixes to the early versions of TitanRPG.
* **BattleMode**
-- Owner of the BigBatteServers.com and creator of the resident UT2004RPG and DruidsRPG modifications, which would have their main features merged into TitanRPG at later point.
* **Mahalis**
-- Creator of the original Drones mutator, a modification by BattleMode of which was later merged into TitanRPG.
* **Wulff**
-- Contributor of some minor features, like the Lightning Rod being blockable using the Shield Gun.
* **Jonathan Zepp**
-- Author of GoodKarma, the core of which has been integrated to TitanRPG for future use.
* **pdinklag** aka **pd**
-- Myself, current developer of TitanRPG, who merged the single TitanRPG packages by fluffy into one and later made TitanRPG a standalone RPG system.

License
-------
The source code and artwork is public domain and is free to be used for spinoffs, as long as it is made clear that it is no longer the original TitanRPG. This is best done by editing the mutator's friendly name and changing the package name.
