# OBS Scene Switch Automixer

A very simple script for auto-mixing 2 audio sources when specific scenes are
activated. Currently supports 2 auto-mixing sequences, in and out:

- 'in' sequence: sourceA is set as full volume, unmuted; the destination scene
  is activated immediately. sourceB is faded out until -60dB, then hard muted.
- 'out' sequence: sourceB is set as full volume, unmuted. sourceA is faded out
  until -60dB, then hard muted. A transition to the destination scene is
  triggered *at the end*.

## Usage

- Edit obs-scene-switch-automixer.lua, update variables with parameters,
  setting proper values for the current scene collection; save and then add to
  OBS scripts.

## Notes

- Tested on OBS 26.0.2@Linux
