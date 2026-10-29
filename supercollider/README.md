# Granular Looper (SuperCollider)

A port of the Sonic Pi Granular Looper v1.0 (`../Granular_Looper.rb`). It
plays one sample from several start points, each for its own length of time,
one after another in a loop.

## Running it

1. Install [SuperCollider](https://supercollider.github.io/downloads) 3.12 or
   newer.
2. Put your sample in `samples/` (the original used `BeNice.wav`). If the
   folder is empty, the looper falls back to `a11wlk01.wav`, which ships with
   SuperCollider, so it makes sound out of the box.
3. Open `main.scd` in the SuperCollider IDE, click inside the parenthesised
   block and press Cmd-Return (Ctrl-Enter on Windows/Linux). The server
   boots, the samples load and the looper starts.
4. Open `live.scd` and evaluate lines from it to change the looper while it
   plays. Cmd-. (Ctrl-.) stops all sound.

From a terminal, `sclang main.scd` does the same as step 3.

## Layout

| File | What it holds |
| --- | --- |
| `main.scd` | Boots the server, loads everything below, starts the looper. |
| `config.scd` | The settings: sample name, start points and their units, play lengths, rate, swing, envelope, output. |
| `live.scd` | Scratchpad of lines to evaluate while it plays. Never loaded. |
| `lib/synthdefs.scd` | `\gl_slice_1` / `\gl_slice_2`: mono and stereo slice players. |
| `lib/samples.scd` | Loads every sound file in `samples/` into `~gl[\samples]`, keyed by file name. |
| `lib/looper.scd` | `Pdef(\granularLooper)`, the pattern that replaces the Sonic Pi `loop do`. |
| `tests/render_nrt.scd` | Offline render, for checking output without a sound card. |

Everything lives in one Event, `~gl`, so the project only claims one
environment variable. Functions in it are called with `.value` or `.()`,
e.g. `~gl[\loadSample].(\kick, "/path/kick.wav")`.

## How the port maps

| Sonic Pi | SuperCollider |
| --- | --- |
| `juicy_sound = '/path/BeNice.wav'` | `~gl[\sampleName] = \BeNice` plus the file in `samples/` |
| `start_location`, `play_length` | `~gl[\startPoints]`, `~gl[\playLengths]` |
| `scale_UI_to_zero_one` | `~gl[\secondsToFraction]` |
| `sample ..., start:, finish:, attack: 0.1, release: 0.1, rate: 0.9` | one `\gl_slice_N` synth; `~gl[\sliceTiming]` turns start/finish into a start frame and an attack/hold/release envelope that ends exactly at `finish` |
| `sleep play_length[count]` | `\dur` of each event (seconds, since `TempoClock.default` runs at 1 beat per second) |
| `loop do ... count ...` | `Pn(Plazy { Pseq(...) })`, which re-reads the lists on every pass |

Behaviour kept from the original:

- A slice's play length is measured in seconds of the source file, so at
  rate 0.9 it actually sounds for length / 0.9 and overlaps the next slice
  a little, just as in Sonic Pi.
- `finish` is clipped to the end of the file. With the default settings the
  5 second slice from 0.45 runs off the end of a short sample, so it plays to
  the end and then there is silence until the next slice.

Small differences to know about:

- If attack + release is longer than a slice, both are shortened in
  proportion so the slice still ends at its `finish` point.
- A negative `playRate` plays each slice backwards from its `finish` point.
- Mono samples are panned with `Pan2` and stereo with `Balance2`, so a
  centred sample is about 3 dB quieter per channel than at full scale.

## Swing and start-position units

These grew out of the `add_swing` and `improved_scaling` Sonic Pi branches.
Both default to the original behaviour.

- `~gl[\swing]` delays every second slice by that fraction of the slice
  before it, so two equal slices sound long-short. 0 is straight, 1/3 is a
  triplet shuffle (2:1), and it is capped at 0.9. The count carries across
  passes, so a list with an odd number of slices still alternates evenly.
  The slice after a swung one stays on the grid, so the loop's overall
  length doesn't change.
- `~gl[\positionUnits]` sets how `~gl[\startPoints]` are read: `\fraction`
  (0-1 across the file, as in Sonic Pi), `\percent` (0-100) or `\seconds`
  (seconds into the file, the same units as `playLengths`). Positions past
  either end of the file are clipped to it.

```
~gl[\swing] = 1/3;
~gl[\positionUnits] = \seconds; ~gl[\startPoints] = [1.5, 1.9, 2.3, 2.7];
```

## Testing without a sound card

`tests/render_nrt.scd` renders the looper offline with the settings in
`config.scd` and prints the first two passes' timing:

```
sclang tests/render_nrt.scd                # 20 s of samples/ (or a11wlk01) to tests/render.wav
sclang tests/render_nrt.scd 30 ~/x.wav out.wav
```

With the default settings and `a11wlk01.wav` (4.28 s, mono) it prints:

```
start  length  startFrac  attack   hold     release  next in  swing lag
0.35     0.5      0.35     0.1      0.3556   0.1      0.5      0.0
0.45     5.0      0.45     0.1      2.4176   0.1      5.0      0.0
0.55     1.5      0.55     0.1      1.4667   0.1      1.5      0.0
...
```

which matches Sonic Pi's math: 0.5 s / 0.9 = 0.556 s, minus 0.2 s of
ramps, is a 0.356 s hold.

On Linux without a desktop, run sclang with
`QT_QPA_PLATFORM=offscreen`.

## Ideas for growing it into a sampler

- More than one looper: build `~gl[\onePass]`-style patterns per voice and
  run them as separate `Pdef`s, or put them in a `Ppar`.
- Per-slice settings: add lists such as `~gl[\rates]` or `~gl[\pans]` and
  `Pseq` them in `lib/looper.scd` the same way as the start points.
- Effects: send `\outBus` to a private bus and add a reverb or filter
  SynthDef reading from it.
- MIDI or OSC control: `MIDIdef.cc` handlers that write into `~gl`.
