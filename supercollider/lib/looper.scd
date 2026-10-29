// Granular Looper: the looper pattern
//
// Pdef(\granularLooper) steps through ~gl[\startPoints] and
// ~gl[\playLengths] in order, forever, playing one slice per step. This is
// the `loop do ... end` from the Sonic Pi script: each slice starts at
// startPoint (0-1 across the file by default; see positionUnits), plays
// playLength seconds of the source, and the next slice starts playLength
// seconds later, or a little later than that for swung slices.
//
// The lists are re-read at the start of every pass and the other settings
// on every slice, so everything in config.scd can be changed while it runs.

(
var gl;
~gl = ~gl ? ();
gl = ~gl;  // captured so the pattern works from any environment

// Port of scale_UI_to_zero_one: a length in seconds as a fraction of the
// sample's length.
gl[\secondsToFraction] = { |seconds, sampleSeconds|
	seconds / sampleSeconds
};

// A start point in ~gl[\positionUnits] as a fraction (0-1) of the sample:
//   \fraction  0-1 across the file (the original Sonic Pi behaviour)
//   \percent   0-100 across the file
//   \seconds   seconds from the start of the file
gl[\positionToFraction] = { |position, sampleSeconds, units|
	switch(units ? \fraction,
		\fraction, { position },
		\percent, { position / 100 },
		\seconds, { gl[\secondsToFraction].(position, sampleSeconds) },
		{
			"Granular Looper: unknown positionUnits %, using \\fraction"
			.format(units).warn;
			gl[\positionUnits] = \fraction;
			position
		}
	)
};

// Swing: every second slice starts late by `swing` times the length of the
// slice before it, so a pair of equal slices sounds long-short. 0 is
// straight, 1/3 is a triplet shuffle. Capped at 0.9 so a swung slice never
// lands on the one after it.
gl[\swingLag] = { |step, previousLength, swing|
	if(step.odd) { (swing ? 0).clip(0, 0.9) * previousLength } { 0 }
};

// Work out where one slice starts and how its envelope is shaped, the way
// Sonic Pi does for `sample buf, start:, finish:, attack:, release:`.
// `finish` is clipped to the end of the file, the segment's real length
// (in output seconds) depends on the rate, and `hold` fills whatever the
// attack and release don't. If attack + release is longer than the segment,
// both are shortened in proportion so the slice still stops at `finish`.
// `start` is in ~gl[\positionUnits].
// Returns [startFrac, hold, attack, release], or nil for a silent slice.
gl[\sliceTiming] = { |start, length, sampleSeconds, rate, attack, release|
	var finish, segment, ramps, scale;

	start = gl[\positionToFraction].(start, sampleSeconds, gl[\positionUnits]).clip(0, 1);
	finish = (start + gl[\secondsToFraction].(length, sampleSeconds)).clip(0, 1);
	segment = (finish - start) * sampleSeconds / rate.abs;
	ramps = attack + release;

	if(rate == 0 or: { segment <= 0 }) {
		nil
	} {
		if(ramps > segment) {
			scale = segment / ramps;
			attack = attack * scale;
			release = release * scale;
		};
		[
			if(rate < 0) { finish } { start },
			max(0, segment - attack - release),
			attack,
			release
		]
	}
};

// The rate that sets how long a slice lasts: playRate in slice mode,
// grainSpeed in grain mode. A frozen grain slice (speed 0) lasts as long as
// it would at speed 1.
gl[\timingRate] = { |ev|
	if(ev[\grainMode]) {
		if(ev[\speed] == 0) { 1 } { ev[\speed] }
	} {
		ev[\rate]
	}
};

// One pass through the slice lists.
gl[\onePass] = {
	var count = min(gl[\startPoints].size, gl[\playLengths].size);

	if(count == 0 or: { gl[\currentBuffer].value.isNil }) {
		// Nothing to play: wait a beat and look again, rather than spin.
		Pn(Event.silent(1), 1)
	} {
		Pbind(
			\startPoint, Pseq(gl[\startPoints].keep(count)),
			\playLength, Pseq(gl[\playLengths].keep(count)),
			\buf, Pfunc { gl[\currentBuffer].value },
			\grainMode, Pfunc { gl[\mode] == \grain },
			\instrument, Pfunc { |ev|
				(if(ev[\grainMode]) { "gl_grain_" } { "gl_slice_" }
					++ ev[\buf].numChannels.clip(1, 2)).asSymbol
			},
			\rate, Pfunc { gl[\playRate] },
			\speed, Pfunc { gl[\grainSpeed] },
			\pitch, Pfunc { gl[\grainPitch] },
			\grainSize, Pfunc { gl[\grainSize].max(0.001) },
			\density, Pfunc { gl[\grainDensity].clip(1, 32) },
			\jitter, Pfunc { gl[\grainJitter].max(0) },
			\amp, Pfunc { gl[\level] },
			\pan, Pfunc { gl[\panPos] },
			\out, Pfunc { gl[\outBus] },
			\timing, Pfunc { |ev|
				gl[\sliceTiming].(
					ev[\startPoint], ev[\playLength], ev[\buf].duration,
					gl[\timingRate].(ev), gl[\attackTime], gl[\releaseTime]
				) ? \silent  // a nil here would end the Pbind
			},
			\type, Pfunc { |ev| if(ev[\timing] == \silent) { \rest } { \note } },
			[\startFrac, \hold, \attack, \release], Pfunc { |ev|
				if(ev[\timing] == \silent) { [0, 0, 0, 0] } { ev[\timing] }
			},
			// Sleep in seconds: one beat is one second at the default tempo.
			\dur, Pkey(\playLength)
		)
	}
};

// Loop the passes forever. Swing counts slices across passes, so it keeps
// alternating evenly even when the list has an odd number of slices.
gl[\pattern] = Plazy {
	var step = 0, previousLength = 0;
	Pn(Plazy { gl[\onePass].value }).collect { |ev|
		ev[\lag] = gl[\swingLag].(step, previousLength, gl[\swing]);
		previousLength = ev[\dur];
		step = step + 1;
		ev
	}
};

Pdef(\granularLooper, gl[\pattern]);
)
