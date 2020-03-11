this is a script i put together that automatically:

* patches and compiles winealsa/winepulse with environment variables to
  tweak sound latency
* creates a back-up of your system wine's winealsa and winepulse
* installs the patched winealsa/winepulse
* creates a wine prefix and installs osu! using your system wine
* creates a script to start and kill osu with tweakable latency values

at the moment, this script makes various assumptions:

* it looks in /usr/lib32 for wine libraries to replace
* assumes you don't touch the osu install location or at least don't move
  it outside of C:

USE AT YOUR OWN RISK. I made this mainly for myself so I can set up osu
without having to replace the system wine or making a full wine build
with all the runtime libraries. it will only ask for root when replacing
the winealsa/winepulse libraries and when installing the osu binary

credits to ThePooN for exploring past just adjusting buffer sizes, which
inspired me to make this winealsa patch for my particular setup

note that on a pure alsa setup you also want to manually tweak your buffer
size in the asoundrc.

if using pulse, check out thepoon's blog post for more low latency settings
for pulse https://blog.thepoon.fr/osuLinuxAudioLatency/

possible improvements:

* find a way to inject the patched .drv.so files without physically
  replacing them. I tried LD_PRELOAD tricks and changing WINEDLLPATH but
  nothing worked
* find a way to properly wait for the osu installer to start and terminate
* find a way to automatically cancel the gecko/mono install on prefix
  creation

# requirements

* git
* wine
* GNU find or something that supports -quit
* make, autoconfig, automake
* gcc
* winealsa-devel, winepulse-devel

if you have all of these and it still doesn't work just read the terminal
output and you'll most likely be able to figure out what is missing

# how to use

```
git clone https://github.com/Francesco149/linux-osu
cd ./linux-osu
./build.sh
```

cancel the wine gecko/mono installs when prompted

when the installer starts, don't change the install location

when the game starts, close it.

if this completes successfully, you should be able to run `osu`

after the first run, re-running build.sh regenerates and reinstalls the osu
launcher script.

things you can do before re-running build.sh

* delete pfx to recreate the wine prefix
* delete both pfx and folder to reinstall osu and recreate the prefix
  (folder is your osu folder, so back it up if you wish)
* delete wine to force it to re-download the wine source
* delete wrk to force a re-build of the patched wine libraries
