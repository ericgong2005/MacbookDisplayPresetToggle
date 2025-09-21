# Toggle Apple Macbook Display Presets

## Motivation:
The developer of this code, an owner of a Macbook Pro (14-inch, 2023), has been plagued by a display backlight issue: when the angle of the screen was pushed past a certain angle, the backlight would immediately turn off, and not turn on until the lid was fully closed. Occasionally, the backlight would also turn off spontaneously. Closing the lid naturally puts the macbook to sleep, which is highly inconvenient when code is executing or the user is in an online meeting.

It was observed however, that changing the display preset while the backlight was off, then subtly adjusting the screen angle sufficed to turn the screen back on without the need to close the lid completely. Hence, it was deemed of high priority to create a keyboard shortcut to allow the user to toggle between diplsay presets, allowing a quick recovery from backlight glitches.

## Display Preset Toggling
An Objective-C script utilizing Apple's `MonitorPanel` framework was written to Toggle the Display preset between `Apple XDR Display (P3-1600 nits)` and `Apple Display (P3-500 nits)`. 

The name of the Display presets were determined using a custom script `list_presets.m`. 

The script for toggling the Display preset (`toggle_preset_hotkey.m`) was then added to the LaunchAgent directory, enabling the script to be automatically run in the background whenever the Macbook was turned on. This was accomplished through the shell script `Add_to_LaunchAgent.sh`.

All Objective-C code can be compiled and run using the makefile. (ie:  `make all` to compile all scripts, `make run-list` to list available presets, etc.)

