window.AudioContext = window.AudioContext || window.mozAudioContext || window.webkitAudioContext || window.msAudioContext || window.oAudioContext
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia


successCallback = (stream) ->

	context = new AudioContext
	sourceNode = context.createMediaStreamSource(stream)

	analyser = context.createAnalyser()
	analyser.smoothingTimeConstant = 0.5
	analyser.fftSize = 2048
	#analyser.fftSize = 128
	

	lp = context.createBiquadFilter()
	lp.type = lp.LOWPASS
	lp.frequency = 8000
	lp.Q = 0.1

	hp = context.createBiquadFilter()
	hp.type = hp.HIGHPASS
	hp.frequency = 20
	hp.Q = 0.1



	scriptNode = context.createScriptProcessor(2048, 1, 1)
	
	actualFrequency = document.querySelector ".frequency .actual"
	
	canvas = document.querySelector "canvas"
	ctx = canvas.getContext "2d"
	
	scriptNode.onaudioprocess = (e) ->

		input = e.inputBuffer.getChannelData 0


		canvas.width = canvas.width;
		ctx.fillStyle = "#ffffff"


		for i in [0...input.length]
			ctx.fillRect i, (canvas.height/2 - Math.floor(input[i]*100)), 1, 1

		sign = (x) ->
			x > 0

		crossings = 0
		for p in [0...input.length-1]
			crossings++ if sign(input[p]) != sign(input[p+1])

		actualFrequency.innerHTML = crossings

		#console.log(input) if Math.floor(Math.random()*100) == 0;
		
		
		# bincount is fftsize / 2
		#audioData = new Uint8Array(analyser.frequencyBinCount)
		#analyser.getByteFrequencyData(audioData)


		#console.log(audioData) if Math.floor(Math.random()*100) == 0;

		###
		
		average = 0
		for i in [0...audioData.length]
			average += audioData[i]
		average = average / audioData.length
		
		max = 0
		for i in [0...audioData.length]
			max = Math.max(max, audioData[i])



		numSamples = audioData.length;
		numCrossing = 0;
		for p in [0...numSamples-1]
			if (audioData[p] > 0 && audioData[p + 1] <= 0) || (audioData[p] < 0 && audioData[p + 1] >= 0)
				numCrossing++


		#console.log numCrossing


		numSecondsRecorded = numSamples / context.sampleRate
		numCycles = numCrossing / 2
		frequency = numCycles / numSecondsRecorded


		#actualFrequency.innerHTML = (array[0] + array[array.length-1]) / 2
		actualFrequency.innerHTML = frequency


		canvas.width = canvas.width;
		ctx.fillStyle = "#ffffff"


		# draw canvas
		for i in [0...audioData.length]
			ctx.fillRect i, (canvas.height - audioData[i]), 1, 1

		###

	#sourceNode.connect lp
	#sourceNode.connect analyser
	sourceNode.connect scriptNode
	lp.connect hp
	hp.connect analyser
	#sourceNode.connect(context.destination)
	#analyser.connect scriptNode
	scriptNode.connect context.destination


errorCallback = (stream) -> 
  alert "Bummer"


if navigator.getUserMedia
  navigator.getUserMedia {video: false, audio: true}, successCallback, errorCallback