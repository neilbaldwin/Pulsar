PULSAR by Neil Balwin
---------------------

Requirements
------------
There are currently only two ways to run Pulsar:

- using an NTSC NES and a PowerPak cart
- using Nestopia NES emulator

If you're using a PowerPak cart, you need to copy the 'MAP01.MAP' file from the PowerPak folder to the
POWERPAK folder on your compact flash card (in the PowerPak cart) otherwise it won't work.

Read the manual - I spent a long time writing it! :)


SAVING
------
If you're using Nestopia, a new blank .sav file will be created when you run Pulsar for the first time.

If you're using PowerPak you must initially put an empty 32kb .sav file named 'pulsar.sav' in the SAV folder on
your PowerPak cart. If you're an experienced user you'll know that you can point Pulsar to any .sav file
you like but remember it MUST be 32KB. A blank 32KB .sav file is supplied with the PowerPak software.

Warning: on boot-up, Pulsar will check your .sav file for a signature. If it's not found, the .sav file
will be 'formatted' to give you a blank Pulsar setup. Remember: when using PowerPak you have to hold
reset for a few seconds and then release it when you want to save your progress.

Release History
---------------

V1.04
- Fixed a crash bug that would happen if you started playback from the Pattern Editor while
  having no Pattern/Chain set for the current step.

V1.03
- Tightened up the reset code to overcome some reset issues on real hardware

V1.02
- Added boot-up check for emulator support of 32KB .sav files. You will get an error message if
  your emulator does not suppor Pulsar and Pulsar will not run
- Updated 'System Requirement' section of manual to include Nintendulator information

V1.01
- Bug Fix: Using the Hxx command in any other track than Track 1 caused incorrect operation.
- Manual : Page_NavMenu.html - key combo to access/use Navigation Menu was incorrect.
- Manual : QuirksBugs.html - added information about the Pulsar bug database


V1.00 23rd December 2010
- Initial release


BUGS
----

There is an online active bug database here:

http://ntrq.lighthouseapp.com/projects/63135/home
	
Please submit tickets there if you think you've found a bug. I monitor it regularly.


FILES
-----

pulsar.nes  - the NES ROM
readme.txt  - this file
license.txt - license file
PowerPak    - folder containing mapper update for PowerPak
Manual      - folder containing HTML manual (Pulsar.html)

