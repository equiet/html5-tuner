scale = document.querySelector ".scale"

for i in [0..80]
	div = document.createElement "div"
	hr = document.createElement "hr"
	div.appendChild hr
	scale.appendChild div




window.AudioContext = window.AudioContext or window.mozAudioContext or window.webkitAudioContext or window.msAudioContext or window.oAudioContext
navigator.getUserMedia = navigator.getUserMedia or navigator.mozGetUserMedia or navigator.webkitGetUserMedia or navigator.msGetUserMedia or navigator.oGetUserMedia


canvas = document.querySelector "canvas"
needle = document.querySelector	".needle"


context = canvas.getContext '2d'
audioContext = new AudioContext()


sampleRate = audioContext.sampleRate
fftSize = 8192
fft = new FFT(fftSize, sampleRate / 4)


buffer = (0 for i in [0...fftSize])
bufferFillSize = 2048
bufferFiller = audioContext.createJavaScriptNode bufferFillSize, 1, 1
bufferFiller.onaudioprocess = (e) ->
	input = e.inputBuffer.getChannelData 0
	for b in [bufferFillSize...buffer.length]
		buffer[b - bufferFillSize] = buffer[b]
	for b in [0...input.length]
		buffer[buffer.length - bufferFillSize + b] = input[b]


gauss = new WindowFunction(DSP.GAUSS)


lp = audioContext.createBiquadFilter()
lp.type = lp.LOWPASS
lp.frequency = 8000
lp.Q = 0.1

hp = audioContext.createBiquadFilter()
hp.type = hp.HIGHPASS
hp.frequency = 20
hp.Q = 0.1


success = (stream) ->

	maxTime = 0
	noiseCount = 0
	noiseThreshold = -Infinity
	maxPeaks = 0
	maxPeakCount = 0


	src = audioContext.createMediaStreamSource stream
	src.connect lp
	lp.connect hp
	hp.connect bufferFiller
	bufferFiller.connect audioContext.destination


	process = ->

		bufferCopy = (b for b in buffer)

		gauss.process bufferCopy
    
		downsampled = []
		for s in [0...bufferCopy.length] by 4
			downsampled.push bufferCopy[s]
    
		upsampled = []
		for s in downsampled
			upsampled.push s
			upsampled.push 0
			upsampled.push 0
			upsampled.push 0
    
		fft.forward upsampled
    
		if noiseCount < 10
			noiseThreshold = Math.max(noiseThreshold, i) for i in fft.spectrum
			noiseThrehold = if noiseThreshold > 0.001 then 0.001 else noiseThreshold
			noiseCount++
      
		spectrumPoints = (x: x, y: fft.spectrum[x] for x in [0...(fft.spectrum.length / 4)])
		spectrumPoints.sort (a, b) -> (b.y - a.y)
    
		peaks = []
		for p in [0...8]
			if spectrumPoints[p].y > noiseThreshold * 5
				peaks.push spectrumPoints[p]
		
		if peaks.length > 0
			for p in [0...peaks.length]
				if peaks[p]?
					for q in [0...peaks.length]
						if p isnt q and peaks[q]?
							if Math.abs(peaks[p].x - peaks[q].x) < 5
								peaks[q] = null
			peaks = (p for p in peaks when p?)
			peaks.sort (a, b) -> (a.x - b.x)
			
			maxPeaks = if maxPeaks < peaks.length then peaks.length else maxPeaks
			if maxPeaks > 0 then maxPeakCount = 0
			
			peak = null
			
			firstFreq = peaks[0].x * (sampleRate / fftSize)
			if peaks.length > 1
				secondFreq = peaks[1].x * (sampleRate / fftSize)
				if 1.4 < (firstFreq / secondFreq) < 1.6
					peak = peaks[1]
			if peaks.length > 2
				thirdFreq = peaks[2].x * (sampleRate / fftSize)
				if 1.4 < (firstFreq / thirdFreq) < 1.6
					peak = peaks[2]

			if peaks.length > 1 or maxPeaks is 1
				if not peak?
					peak = peaks[0]
		
				left = x: peak.x - 1, y: Math.log(fft.spectrum[peak.x - 1])
				peak = x: peak.x, y: Math.log(fft.spectrum[peak.x])
				right = x: peak.x + 1, y: Math.log(fft.spectrum[peak.x + 1])
		
				interp = (0.5 * ((left.y - right.y) / (left.y - (2 * peak.y) + right.y)) + peak.x)
				freq = interp * (sampleRate / fftSize)

				display.draw freq
		else
			maxPeaks = 0
			maxPeakCount++
			if maxPeakCount > 20
				display.clear()
		
		render()


	getPitch = (freq) ->
		minDiff = Infinity
		diff = Infinity
		for own key, val of frequencies
			if Math.abs(freq - val) < minDiff
				minDiff = Math.abs(freq - val)
				diff = freq - val
				note = key
		[note, diff]


	display = 

		draw: (freq) ->

			debugFreq = document.querySelector ".debug .frequency"
			debugFreq.innerHTML = freq

			###
			displayDiv = $('.tuner div')
			displayDiv.removeClass()
			displayDiv.addClass (if Math.abs(diff) < 0.25 then 'inTune' else 'outTune')
			displayStr = ''
			displayStr += if diff < -0.25 then '>&nbsp;' else '&nbsp;&nbsp;'
			displayStr += note.replace(/[0-9]+/g, '')
			displayStr += if diff > 0.25 then '&nbsp;<' else '&nbsp;&nbsp;'
			displayDiv.html displayStr
			###

		clear: ->

			debugFreq = document.querySelector ".debug .frequency"
			debugFreq.innerHTML = ""

			###
			displayDiv = $('.tuner div')
			displayDiv.removeClass()
			displayDiv.html ''
			###


	render = ->

		###
		context.clearRect 0, 0, canvas.width, canvas.height
		newMaxTime = _.reduce buffer, ((max, next) -> if Math.abs(next) > max then Math.abs(next) else max), -Infinity
		maxTime = if newMaxTime > maxTime then newMaxTime else maxTime
		context.fillStyle = '#EEE'
		timeWidth = (canvas.width - 100) / (buffer.length)
		for s in [0...buffer.length]
			context.fillRect timeWidth * s, canvas.height / 2, timeWidth, -(canvas.height / 2) * (buffer[s] / maxTime)
		context.fillStyle = '#F77'
		freqWidth = (canvas.width - 100) / (fft.spectrum.length / 4)
		for f in [10...(fft.spectrum.length / 4) - 10]
			context.fillRect freqWidth * f, canvas.height / 2, freqWidth, -Math.pow(1e4 * fft.spectrum[f], 2)
		###
	
	setInterval process, 100


error = (e) -> 
	console.log e
	console.log 'ARE YOU USING CHROME CANARY (23/09/2012) ON A MAC WITH "Web Audio Input" ENABLED IN chrome://flags?'


navigator.getUserMedia audio: true, success, error


