Class {
	#name : 'PhexImageDownloader',
	#superclass : 'Object',
	#instVars : [
		'server',
		'downloads',
		'directory'
	],
	#classInstVars : [
		'instance'
	],
	#category : 'Phex-Image-Downloader',
	#package : 'Phex-Image-Downloader'
}

{ #category : 'accessing' }
PhexImageDownloader class >> start: aPort directory: aDirectory [

	instance ifNil: [ instance := self new ].
	instance directory: aDirectory.
	instance start: aPort
]

{ #category : 'accessing' }
PhexImageDownloader class >> stop [
	
	instance ifNil: [ 
		self error: 'No instance of the downloader is running. Use ', (self class >> #start:) name
	].

	instance stop.
	instance := nil.
	
	^ instance
]

{ #category : 'accessing' }
PhexImageDownloader >> directory: aFilePath [

	directory := aFilePath
]

{ #category : 'adding' }
PhexImageDownloader >> downloaded: aFileName [

	downloads add: aFileName.
	self registry asFileReference writeStreamDo: [ :stream |
		STON put: downloads asArray asJsonOnStream: stream
	]
]

{ #category : 'origins' }
PhexImageDownloader >> downloads [ 

	^ downloads := self registry readStream size <= 0 
		ifTrue: [ OrderedCollection new ]
		ifFalse: [ (STON fromStream: self registry readStream) asOrderedCollection ]
]

{ #category : 'public' }
PhexImageDownloader >> handleRequest: aRequest [

	| fileName fileStream response |

	[
		fileName := ZnUtils decodeBase64: aRequest uri lastPathSegment.
		
		(self downloads includes: fileName) ifTrue: [ ^ ZnResponse noContent ].
		
		fileStream := (directory / fileName) asFileReference binaryReadStream.

		response := ZnResponse ok: ((ZnStreamingEntity type: ZnMimeType applicationOctetStream)
				stream: fileStream;
				contentLength: fileStream size;
				yourself).
		
		response headers at: 'Content-Disposition:' put: 'attachment; filename="experiment.zip"'.

		self downloaded: fileName.
		
		^ response
	] on: Error do: [ 
		^ ZnResponse noContent 
	].
]

{ #category : 'registry' }
PhexImageDownloader >> registry [

	^ (FileLocator imageDirectory / 'downloads.json') 
		ensureCreateFile;
		yourself
]

{ #category : 'accessing' }
PhexImageDownloader >> start: aPort [

	server := ZnServer on: aPort.
	server delegate: self.
	server start

]

{ #category : 'accessing' }
PhexImageDownloader >> stop [

	server stop
]
