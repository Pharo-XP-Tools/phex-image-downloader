Class {
	#name : 'BaselineOfPhexImageDownloader',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPhexImageDownloader',
	#package : 'BaselineOfPhexImageDownloader'
}

{ #category : 'baselines' }
BaselineOfPhexImageDownloader >> baseline: spec [

	<baseline>
	spec for: #common do: [
			spec package: #'Phex-Image-Downloader'.
	] 
]
