# Granular Looper Tests
# Mark Wiem 2016/10/16
# refactor and correct instrument's sample scaling 

#load your local sample of choice
juicy_sound = '/Users/markwiem/Documents/CODE/Sonic_Pi/Samples/TestSamples/BeNice.wav'

#select the start positions, scaled between 0-1, for the playback points, as many as you'd like
#start_location = [0.1, 0.5, 0.2, 0.6, 0.7, 0.6, 0.1, 0.11, 0.2, 0.6, 0.601]
start_location = 0.35

#desired play_length of sample play in seconds
play_length = 5.75

'''
user Req: Enter play_length as a value in seconds
program req: value must be between 0-1

solution - return user entered play_length, entered in seconds, as a value 0-1
'''

#linearize the play_length of any sample between 0-1
# based on the following equation
# n2 = (B*C - A*D)/(B - A) + n1*(D - C)/(B - A)
define :scale_UI_to_zero_one do |play_length_seconds, sample_length_seconds|
  scaled_sample_length = 0
  scaled_sample_length = play_length_seconds*(1/sample_length_seconds)
  return scaled_sample_length
end


intro = start_location #scaled 0-1
outro = intro + scale_UI_to_zero_one(play_length, sample_duration(juicy_sound)) #scaled 0-1

sample juicy_sound, start: intro, finish: outro, attack: 0.1, release: 0.1, rate: 0.9
