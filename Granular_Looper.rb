# Granular Looper v1.0
# Mark Wiem 2016/10/17
######################################
# First Official Version.
#Allows for sample to be played at multiple points in file, for multiple lengths of time.

#Work to add swing to samples to add variety to loops

#load your local sample of choice
juicy_sound = '/Users/markwiem/Documents/CODE/Sonic_Pi/Samples/TestSamples/BeNice.wav'

#select the start positions, scaled between 0-1, for the playback points, as many as you'd like
start_location = [0.35, 0.37, 0.55]

#desired play_length of sample play in seconds
play_length = [0.5, 0.35, 0.5]

'''
user Req: Enter play_length as a value in seconds
program req: value must be between 0-1

-return user entered play_length, entered in seconds, as a value 0-1
'''

#linearize the play_length of any sample between 0-1
# based on the following equation
# n2 = (B*C - A*D)/(B - A) + n1*(D - C)/(B - A)
define :scale_UI_to_zero_one do |play_length_seconds, sample_length_seconds|
  scaled_sample_length = 0
  scaled_sample_length = play_length_seconds*(1/sample_length_seconds)
  return scaled_sample_length
end

count = 0
loop do
  intro = start_location[count] #scaled 0-1
  outro = intro + scale_UI_to_zero_one(play_length[count], sample_duration(juicy_sound)) #scaled 0-1
  sample juicy_sound, start: intro, finish: outro, attack: 0.1, release: 0.1, rate: 0.9
  sleep play_length[count] # sleep in seconds
  if count == (start_location.length)-1
    count = 0
  else
    count += 1
  end
end