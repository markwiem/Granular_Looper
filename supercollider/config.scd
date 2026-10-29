// Granular Looper: settings
//
// These are the values from the Sonic Pi v1.0 script. Edit them here before
// running main.scd, or change them live while the looper plays, e.g.
//
//     ~gl[\startPoints] = [0.1, 0.6, 0.62, 0.8];
//     ~gl[\playRate] = 0.5;
//
// Changes to the slice lists take effect at the start of the next pass
// through the list; the other values apply to the very next slice.

(
~gl = ~gl ? ();

// Folder of samples to load. Every .wav/.aif/.aiff/.flac in it is loaded
// and can be selected by its file name (without extension) as a symbol.
~gl[\sampleDir] = ~gl[\root] +/+ "samples";

// The sample the looper plays. The original script used BeNice.wav; drop
// that (or anything else) into samples/ and name it here. If it is not
// found, the first loaded sample is used, and if the folder is empty the
// a11wlk01.wav file that ships with SuperCollider is used.
~gl[\sampleName] = \BeNice;

// Start positions, as many as you like, in the units below.
~gl[\startPoints] = [0.35, 0.45, 0.55];

// How startPoints are measured:
//   \fraction  0-1 across the file (as in the Sonic Pi script)
//   \percent   0-100 across the file
//   \seconds   seconds from the start of the file, e.g. [1.5, 1.93, 2.36]
~gl[\positionUnits] = \fraction;

// How long each slice plays, in seconds of the source file. This is also
// the time until the next slice starts. Paired with startPoints by index.
~gl[\playLengths] = [0.5, 5, 1.5];

// Playback rate (1 = original speed and pitch). At 0.9 a slice lasts
// slightly longer than its play length, so neighbouring slices overlap.
~gl[\playRate] = 0.9;

// Playback mode:
//   \slice  plays each slice straight (speed and pitch both follow playRate)
//   \grain  plays each slice as overlapping grains, so the speed through the
//          file (grainSpeed) and the pitch (grainPitch) are set separately.
//          playRate is not used in this mode.
~gl[\mode] = \slice;

// Grain mode settings.
// grainSpeed: how fast the slice moves through the file. 1 is original
// speed, 0.5 is half speed (the slice lasts twice as long), negative plays
// backwards, and 0 freezes on the start point for as long as the slice
// would last at speed 1.
~gl[\grainSpeed] = 1;
// grainPitch: pitch as a ratio, 1 is original, 2 an octave up, 0.5 an
// octave down. For semitones use e.g. 7.midiratio.
~gl[\grainPitch] = 1;
// grainSize: length of each grain in seconds. Small (0.02-0.05) is buzzy
// and textured, large (0.2-0.5) is smoother but smears attacks.
~gl[\grainSize] = 0.1;
// grainDensity: how many grains overlap at any moment (1-16). Low values
// sound grainy and gappy, high values dense and smooth.
~gl[\grainDensity] = 4;
// grainJitter: scatters each grain up to this many seconds either side of
// where the slice is playing. 0 is clean, 0.05-0.2 is shimmering.
~gl[\grainJitter] = 0;

// Swing: delays every second slice by this fraction of the slice before
// it. 0 is straight, 1/3 is a triplet shuffle, 0.9 is the most allowed.
~gl[\swing] = 0;

// Envelope times in seconds.
~gl[\attackTime] = 0.1;
~gl[\releaseTime] = 0.1;

// Output.
~gl[\level] = 1;
~gl[\panPos] = 0;
~gl[\outBus] = 0;
)
