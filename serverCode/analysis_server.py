#!/usr/bin/env python
# This python script will extract certain audiodescriptors from a file


import essentia
import essentia.standard
from essentia import *
from essentia.standard import *

def extractor(filename):
    # load our audio into an array
    audio = MonoLoader(filename = filename)()

    # create the pool and windowing and spectrum
    pool = Pool()
    w = Windowing()
    spectrum = Spectrum()

    #create necessary algorithms
    # compute the centroid for all frames in our audio and add it to the pool
    for frame in FrameGenerator(audio, frameSize = 1024, hopSize = 512):

        centroid = Centroid() # spectral centroid
        c = centroid(spectrum(w(frame)))
        pool.add('value.centroid', c)

        # calculate dissonance & inharmonicity
        spectralpeaks = SpectralPeaks() # spectral peaks returns freq & mag of the spectral peaks, for dissonance
        sp_frequencies, sp_magnitudes = spectralpeaks(spectrum(w(frame)))
        diss = Dissonance()
        dissonance = diss(sp_frequencies, sp_magnitudes)
        pool.add('value.dissonance', dissonance)

        # zerocrossings
        zerox = ZeroCrossingRate()
        z = zerox(w(frame))
        pool.add('value.zerox', z)

        # calculate pitch & pitch confidence
        pitch = PitchYinFFT()
        pitch, pitchConfidence = pitch(spectrum(w(frame)))
        pool.add('value.pitch', pitch)
        pool.add('value.pitchconfidence', pitchConfidence)

        # pitch salience. might try low samplingrate?
        salience = PitchSalience()
        ps = salience(spectrum(w(frame)))
        pool.add('value.salience', ps)


# what is missing?

    # aggregate the results
    aggrpool = PoolAggregator(defaultStats = [ 'mean', 'var' ])(pool)

    # write result to file
    YamlOutput(filename = filename + '.sig')(aggrpool)


# some python magic so that this file works as a script as well as a module
# if you do not understand what that means, you don't need to care
if __name__ == '__main__':
    import sys
    print 'Script %s called with arguments: %s' % (sys.argv[0], sys.argv[1:])

    try:
        extractor(sys.argv[1])
        print 'Success!'

    except KeyError:
        print 'ERROR: You need to call this script with a filename argument...'
