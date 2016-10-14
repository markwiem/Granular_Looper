# Granular Looper
# Mark Wiem 2015/10/13
# play grainular portions of a sample at desired location, speed, and duration

#load your local sample of choice
juicy_sound = '/Users/markwiem/Documents/CODE/Sonic_Pi/Samples/TestSamples/BeNice.wav'

#select the start positions, scaled between 0-1, for the playback points, as many as you'd like
#value = [0.1, 0.5, 0.2, 0.6, 0.7, 0.6, 0.1, 0.11, 0.2, 0.6, 0.601]
value = [0.1, 0.101, 0.1, 0.102]

#desired length of sample play in seconds
length = 0.5

#linearize the length of any sample between 0-1
# based on the following equation
# n2 = (B*C - A*D)/(B - A) + n1*(D - C)/(B - A)
define :linear_scale do |input, in_range_low, in_range_high, out_range_low, out_range_high|
  output = 0
  output = (((in_range_high*out_range_low) - (in_range_low*out_range_high))/(in_range_high - in_range_low)) + (input*(out_range_high - out_range_low)/(in_range_high - in_range_low))
  return output
end

#total_sample_length = sample_duration(juicy) #return sample duration in second
total_sample_length = sample_duration(juicy_sound) #return sample duration in second
scaled_sample_length = linear_scale(length, 0, total_sample_length, 0, 1) # return scaled sample length between 0-1

count = 0
loop do
  intro = value[count]
  outro = intro + scaled_sample_length
  sample juicy_sound, start: intro, finish: outro, attack: 0.1, release: 0.1, rate: 0.9
  sleep length # sleep in seconds
  if count == (value.length)-1
    count = 0
  else
    count += 1
  end
end