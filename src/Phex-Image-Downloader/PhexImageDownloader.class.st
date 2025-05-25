Class {
	#name : 'PhexImageDownloader',
	#superclass : 'Object',
	#instVars : [
		'server',
		'downloads',
		'directory',
		'filename',
		'linkReuseEnabled'
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

{ #category : 'parameters' }
PhexImageDownloader >> directory: aFilePath [

	directory := aFilePath
]

{ #category : 'parameters' }
PhexImageDownloader >> disableLinkReuse [

	linkReuseEnabled := false
]

{ #category : 'private' }
PhexImageDownloader >> downloaded: aFileName [

	downloads add: aFileName.
	self registry asFileReference writeStreamDo: [ :stream |
		STON put: downloads asArray asJsonOnStream: stream
	]
]

{ #category : 'accessing' }
PhexImageDownloader >> downloads [ 

	^ downloads := self registry readStream size <= 0 
		ifTrue: [ OrderedCollection new ]
		ifFalse: [ (STON fromStream: self registry readStream) asOrderedCollection ]
]

{ #category : 'parameters' }
PhexImageDownloader >> enableLinkReuse [

	linkReuseEnabled := true
]

{ #category : 'accessing' }
PhexImageDownloader >> filename [

	^ filename
]

{ #category : 'private' }
PhexImageDownloader >> handleRequest: aRequest [

	| fileName fileStream response |

	fileName := [ ZnUtils decodeBase64: aRequest uri lastPathSegment. ] on: Error do: [ 
		^ ZnResponse noContent 
	].

	(self isDownloaded: fileName) ifTrue: [ ^ ZnResponse noContent ].
	
	fileStream := [  (directory / fileName) asFileReference binaryReadStream ] on: Error do: [ 
		^ ZnResponse serverError: 'Server failure'
	].
	
	response := ZnResponse ok: (ZnStreamingEntity type: ZnMimeType applicationOctetStream).
	response stream: fileStream.
	response contentLength: fileStream size.
	response headers at: 'Content-Disposition:' put: ('attachment; filename="{1}"' format: { 
		self filename ifEmpty: [ fileName ]
	}).
	self downloaded: fileName.

	^ response
]

{ #category : 'initialization' }
PhexImageDownloader >> initialize [

	filename := String empty.
	self disableLinkReuse
]

{ #category : 'private' }
PhexImageDownloader >> isDownloaded: aFileName [

	^ self downloads includes: aFileName
]

{ #category : 'private' }
PhexImageDownloader >> registry [

	^ (FileLocator imageDirectory / 'downloads.json') 
		ensureCreateFile;
		yourself
]

{ #category : 'parameters' }
PhexImageDownloader >> rename: aFileName [

	filename := aFileName
]

{ #category : 'services' }
PhexImageDownloader >> start: aPort [

	server := ZnServer on: aPort.
	server delegate: self.
	server start

]

{ #category : 'services' }
PhexImageDownloader >> stop [

	server stop
]
