// Granular Looper: live controls
//
// Start the looper with main.scd first. Then evaluate any of these lines
// (Shift-Return for one line, Cmd/Ctrl-Return for a block in parentheses)
// to change it while it plays. This file is a scratchpad; it is never loaded.
//
// Every setting lives in the Event ~gl. The defaults are in config.scd.
// When a change takes effect:
//   - startPoints and playLengths: at the start of the next pass through
//     the list, so the current pass finishes first.
//   - everything else: on the very next slice.


// ---- Slices -------------------------------------------------------------

// startPoints: where in the sample each slice begins, one entry per slice,
// played in order and then repeated. The numbers are read in the units set
// by positionUnits (below). Positions past either end of the file are
// clipped to it.
~gl[\startPoints] = [0.1, 0.35, 0.36, 0.7];

// playLengths: how long each slice plays, in seconds of the source file,
// paired with startPoints by position in the list (first with first, and
// so on). It is also the wait before the next slice starts. If the two
// lists differ in length, the extra entries in the longer one are ignored.
// A slice that runs past the end of the file stops at the end, followed by
// silence until the next slice.
~gl[\playLengths] = [0.25, 0.25, 2, 1];

// positionUnits: how the startPoints numbers are read.
//   \fraction  0-1 across the whole file (0.5 is the middle), as in Sonic Pi
//   \percent   0-100 across the whole file
//   \seconds   seconds from the start of the file
// Change the units and the points together, in one block:
(~gl[\positionUnits] = \seconds; ~gl[\startPoints] = [1.5, 1.9, 2.3, 2.7];)
(~gl[\positionUnits] = \percent; ~gl[\startPoints] = [35, 45, 55];)
(~gl[\positionUnits] = \fraction; ~gl[\startPoints] = [0.35, 0.45, 0.55];)


// ---- Playback ----------------------------------------------------------

// playRate (slice mode): speed and pitch. 1 is the original, 0.5 is half speed and an
// octave down, 2 is double speed and an octave up. Negative numbers play
// each slice backwards. Below 1, a slice sounds longer than its play
// length and overlaps the next one. Above 1, it ends early and leaves a
// gap. 0 is silent.
~gl[\playRate] = 0.5;

// swing: delays every second slice by this fraction of the length of the
// slice before it, so two equal slices sound long-short. 0 is straight,
// 1/3 is a triplet shuffle, and 0.9 is the most allowed. The slice after
// a swung one stays on time, so the loop's overall length doesn't change.
~gl[\swing] = 1/3;
~gl[\swing] = 0;

// attackTime / releaseTime: fade-in and fade-out of each slice, in
// seconds. Short values sound choppy and percussive, long values smooth.
// If the two together are longer than a slice, both shrink to fit it.
~gl[\attackTime] = 0.01; ~gl[\releaseTime] = 0.3;
(~gl[\attackTime] = 0.1; ~gl[\releaseTime] = 0.1;)


// ---- Grain mode ------------------------------------------------------

// mode: \slice plays each slice straight, so playRate changes speed and
// pitch together. \grain plays it as many short overlapping grains, so
// speed and pitch are set separately with the grain settings below and
// playRate is ignored. Switching applies from the next slice.
~gl[\mode] = \grain;
~gl[\mode] = \slice;

// grainSpeed: how fast each slice moves through the file, without changing
// pitch. 0.5 is half speed (the slice lasts twice as long), negative plays
// backwards, 0 freezes on the start point.
~gl[\grainSpeed] = 0.5;
~gl[\grainSpeed] = 0;
~gl[\grainSpeed] = 1;

// grainPitch: pitch as a ratio, without changing speed. 2 is an octave up,
// 0.5 an octave down; .midiratio converts semitones.
~gl[\grainPitch] = 0.5;
~gl[\grainPitch] = 7.midiratio;
~gl[\grainPitch] = 1;

// grainSize: seconds per grain. Small is buzzy, large is smooth but blurs
// drum hits. grainDensity: how many grains overlap at once (1-16).
(~gl[\grainSize] = 0.03; ~gl[\grainDensity] = 2;)
(~gl[\grainSize] = 0.25; ~gl[\grainDensity] = 8;)
(~gl[\grainSize] = 0.1; ~gl[\grainDensity] = 4;)

// grainJitter: scatters each grain up to this many seconds either side of
// where the slice is playing. 0 is clean, 0.05-0.2 shimmers.
~gl[\grainJitter] = 0.1;
~gl[\grainJitter] = 0;

// A frozen, shimmering pad an octave down from the current start points:
(~gl[\mode] = \grain; ~gl[\grainSpeed] = 0; ~gl[\grainPitch] = 0.5;
 ~gl[\grainSize] = 0.2; ~gl[\grainDensity] = 8; ~gl[\grainJitter] = 0.1;)


// ---- Output -------------------------------------------------------------

// level: volume, multiplied into the signal. 1 is the sample's own level,
// 0.5 is about 6 dB quieter. Above 1 can clip.
~gl[\level] = 0.5;
~gl[\level] = 1;

// panPos: stereo position, from -1 (left) through 0 (centre) to 1 (right).
~gl[\panPos] = -0.5;
~gl[\panPos] = 0;

// outBus: the first of the two audio buses the looper writes to. 0 is
// your first pair of speaker outputs. Use a private bus number (e.g. one
// from Bus.audio(s, 2).index) to route it into an effect instead.
~gl[\outBus] = 0;


// ---- Samples -----------------------------------------------------------

// samples: every loaded sample, keyed by file name without the extension.
// This line prints the names you can use for sampleName.
~gl[\samples].keys.postln;

// sampleName: which loaded sample the looper plays, as a symbol. If the
// name isn't loaded, the looper warns and picks the first one
// alphabetically. a11wlk01 is the sample that comes with SuperCollider.
~gl[\sampleName] = \a11wlk01;

// loadSample: loads a file from anywhere under a name you choose, replacing
// any sample already loaded with that name. Then select it by that name.
// Replace the example path with a real one; ~ works for your home folder.
// If the file isn't found, it posts a warning and nothing changes.
~gl[\loadSample].(\mySound, "/path/to/sound.wav");
~gl[\sampleName] = \mySound;

// sampleDir: the folder main.scd loads samples from (samples/ in this
// project). After adding files to it, load the new ones (already loaded
// samples are skipped):
~gl[\loadSamples].(~gl[\sampleDir]);


// ---- Transport -----------------------------------------------------------

// Stop the looper, or start it again from the first slice.
Pdef(\granularLooper).stop;
Pdef(\granularLooper).play;

// Stop and free every loaded sample from the server's memory. Run main.scd
// again to reload them.
(Pdef(\granularLooper).stop; ~gl[\freeSamples].value;)
