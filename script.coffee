window.URL = window.URL || window.webkitURL
window.AudioContext = window.AudioContext || window.mozAudioContext || window.webkitAudioContext || window.msAudioContext || window.oAudioContext
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia


successCallback = (stream) ->

	context = new AudioContext
	sourceNode = context.createMediaStreamSource(stream)

	analyser = context.createAnalyser()
	analyser.smoothingTimeConstant = 0.3
	#analyser.fftSize = 1024
	analyser.fftSize = 128

	scriptNode = context.createScriptProcessor(2048, 1, 1)
	
	actualFrequency = document.querySelector ".frequency .actual"
	
	scriptNode.onaudioprocess = ->

		# get the average, bincount is fftsize / 2
		array = new Uint8Array(analyser.frequencyBinCount)
		analyser.getByteFrequencyData(array)

		actualFrequency.innerHTML = (array[0] + array[array.length-1]) / 2

	sourceNode.connect(analyser)
	#sourceNode.connect(context.destination)
	analyser.connect(scriptNode)
	scriptNode.connect(context.destination)


errorCallback = (stream) -> 
  alert "Bummer"


if navigator.getUserMedia
  navigator.getUserMedia {video: false, audio: true}, successCallback, errorCallback