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

// Start positions, scaled 0-1 across the file. As many as you like.
~gl[\startPoints] = [0.35, 0.45, 0.55];

// How long each slice plays, in seconds of the source file. This is also
// the time until the next slice starts. Paired with startPoints by index.
~gl[\playLengths] = [0.5, 5, 1.5];

// Playback rate (1 = original speed and pitch). At 0.9 a slice lasts
// slightly longer than its play length, so neighbouring slices overlap.
~gl[\playRate] = 0.9;

// Envelope times in seconds.
~gl[\attackTime] = 0.1;
~gl[\releaseTime] = 0.1;

// Output.
~gl[\level] = 1;
~gl[\panPos] = 0;
~gl[\outBus] = 0;
)
