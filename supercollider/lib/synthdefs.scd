// Granular Looper: SynthDefs
//
// One slice player per channel count (\gl_slice_1 for mono files,
// \gl_slice_2 for stereo). Each synth plays one segment of a buffer under a
// linear attack/hold/release envelope and frees itself when the envelope ends.
// The pattern in looper.scd computes `hold` so the envelope ends exactly where
// the segment's `finish` point is reached, which is what Sonic Pi does for
// `sample ..., start:, finish:, attack:, release:`.
//
// `hold` is used instead of `sustain` because the default Event computes its
// own `sustain` (dur * legato) and would send that to the synth.
//
// \gl_grain_1 / \gl_grain_2 are the grain-mode players. They play the same
// segment under the same envelope, but with Warp1: many short overlapping
// grains read from a pointer that moves through the file at `speed`, while
// each grain plays at `pitch`. So speed and pitch are independent. The
// pointer starts at startFrac and moves `speed` seconds of source per
// second (negative backwards, 0 frozen); `jitter` scatters each grain up to
// that many seconds either side of it.

(
~gl = ~gl ? ();

~gl[\synthDefs] = [1, 2].collect { |numChannels|
	SynthDef(("gl_slice_" ++ numChannels).asSymbol, {
		|out = 0, buf = 0, startFrac = 0, rate = 1, amp = 1, pan = 0,
		attack = 0.1, hold = 0, release = 0.1|
		var env, sig;

		env = EnvGen.ar(
			Env.linen(attack, hold, release, curve: \lin),
			doneAction: Done.freeSelf
		);
		sig = PlayBuf.ar(
			numChannels,
			buf,
			rate * BufRateScale.kr(buf),
			startPos: startFrac * BufFrames.kr(buf),
			loop: 0
		);
		sig = sig * env * amp;
		sig = if(numChannels == 1) {
			Pan2.ar(sig, pan)
		} {
			Balance2.ar(sig[0], sig[1], pan)
		};
		Out.ar(out, sig);
	})
};

~gl[\synthDefs] = ~gl[\synthDefs] ++ [1, 2].collect { |numChannels|
	SynthDef(("gl_grain_" ++ numChannels).asSymbol, {
		|out = 0, buf = 0, startFrac = 0, speed = 1, pitch = 1, amp = 1,
		pan = 0, attack = 0.1, hold = 0, release = 0.1,
		grainSize = 0.1, density = 4, jitter = 0|
		var env, pointer, edge, sig, bufDur = BufDur.kr(buf);

		env = EnvGen.ar(
			Env.linen(attack, hold, release, curve: \lin),
			doneAction: Done.freeSelf
		);
		// One new jitter offset per grain: grains start density/grainSize
		// times a second.
		pointer = startFrac
			+ Sweep.kr(1, speed / bufDur)
			+ (LFNoise0.kr(density / grainSize) * jitter / bufDur);
		// Warp1 wraps around the ends of the buffer, so keep every grain
		// inside the file: half a grain (in source time) from either end.
		edge = (grainSize * pitch.abs * 0.5 / bufDur).min(0.5);
		sig = Warp1.ar(
			numChannels,
			buf,
			pointer.clip(edge, 1 - edge),
			pitch * BufRateScale.kr(buf),
			grainSize,
			overlaps: density,
			windowRandRatio: 0.1,  // keeps regular grains from sounding buzzy
			interp: 4
		);
		// Overlapping grains add up, so more density is louder. This keeps
		// it close to slice-mode level from density 1 to 8.
		sig = sig * env * amp * (2 / density).sqrt;
		sig = if(numChannels == 1) {
			Pan2.ar(sig, pan)
		} {
			Balance2.ar(sig[0], sig[1], pan)
		};
		Out.ar(out, sig);
	})
};

~gl[\synthDefs].do(_.add);
)
