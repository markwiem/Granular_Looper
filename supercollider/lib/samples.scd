// Granular Looper: sample loading
//
// ~gl[\samples] maps a symbol (the file name without extension) to a Buffer.
// Call ~gl[\loadSamples] from inside a Routine (e.g. s.waitForBoot) and
// s.sync afterwards before playing, because Buffer.read is asynchronous.

(
var gl;
~gl = ~gl ? ();
gl = ~gl;  // captured so the functions below work from any environment

gl[\samples] = gl[\samples] ? IdentityDictionary.new;
gl[\fallbackSample] = Platform.resourceDir +/+ "sounds/a11wlk01.wav";

// Load every sound file in `dir` that isn't loaded yet. Returns the
// dictionary of all loaded samples.
gl[\loadSamples] = { |dir, server|
	var extensions = ["wav", "aif", "aiff", "flac"];
	server = server ? Server.default;

	PathName(dir).files.do { |file|
		var name = file.fileNameWithoutExtension.asSymbol;
		if(extensions.includesEqual(file.extension.toLower)
			and: { gl[\samples][name].isNil }) {
			gl[\samples][name] = Buffer.read(server, file.fullPath);
		};
	};

	if(gl[\samples].isEmpty) {
		"Granular Looper: no samples in %, using %".format(
			dir, gl[\fallbackSample]
		).warn;
		gl[\samples][\a11wlk01] = Buffer.read(server, gl[\fallbackSample]);
	};

	gl[\samples]
};

// Load one file under a given name, replacing any sample with that name.
gl[\loadSample] = { |name, path, server|
	server = server ? Server.default;
	gl[\samples][name] !? (_.free);
	gl[\samples][name] = Buffer.read(server, path);
};

// The Buffer named by ~gl[\sampleName], or the first loaded one.
gl[\currentBuffer] = {
	var buf = gl[\samples][gl[\sampleName]];
	if(buf.isNil and: { gl[\samples].notEmpty }) {
		var name = gl[\samples].keys.asArray.sort.first;
		"Granular Looper: sample % not loaded, using %".format(
			gl[\sampleName], name
		).warn;
		gl[\sampleName] = name;
		buf = gl[\samples][name];
	};
	buf
};

gl[\freeSamples] = {
	gl[\samples].do(_.free);
	gl[\samples].clear;
};
)
