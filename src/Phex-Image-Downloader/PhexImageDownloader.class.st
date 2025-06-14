"
## Description
`PhexImageDownloader` is an HTTP server that listens for requests to download a given file.

## Usage example

To start a PhexImageDownloader and:
- Serve the following directory `{home}/images`.
- Rename files to ""archive.zip"" as they are being downloaded.
- Enable reusable links.
- Listen the port 8080.

```st
PhexImageDownloader new
	directory: FileLocator home / 'images';
	rename: 'archive.zip';
	enableLinkReuse;
	start: 8080
```

## Additional information

By default, the server will not enable link reuse.  
To keep the state of used links it reads and updates the ""downloads.json"" file, at the root directory of the image.  
The ""downloads.json"" file contains the name of files already downloaded.  

```json
[ ""filename1"", ""filename2"" ]
```

During the download, the HTTP connection of a client might disconnect for various reasons.  
The project does not control the client's correct reception of the entire file.
Therefore the file link will be considered as already used and become unusable again,
In this case, it is possibe to re-activate the link, by removing the targeted filename from the ""downloads.json"" file.

However, beware, the server does not control the correct format of the ""downloads.json"" file.
Moreover, any modification to the ""downloads.json"" file is immediately taken into account by the server.
Wrong modifications can lead to unexpected answers or requests timeouts (debugger opening leading, hence no response delivered).

## Dependencies

I rely on Zinc-HTTP, in particular `ZnServer` and `ZnClient`.


"
Class {
	#name : 'PhexImageDownloader',
	#superclass : 'ZnStaticFileServerDelegate',
	#instVars : [
		'server',
		'downloads',
		'linkReuseEnabled',
		'filename'
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
PhexImageDownloader >> disableLinkReuse [

	linkReuseEnabled := false
]

{ #category : 'private' }
PhexImageDownloader >> downloaded: aFileName [

	linkReuseEnabled ifTrue: [ ^ self ].

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

	| request response fileName |

	request := aRequest copy.
	
	1 to: request uri segments size do: [ :index |
		| segment | 
		segment := request uri segments at: index. 
		request uri segments at: index put: (
			[ ZnUtils decodeBase64: segment ] on: Error do: [ segment ]
		) 
	].

	fileName := (self actualFilenameFor: request uri) 
		ifNil: [ ^ ZnResponse notFound: aRequest uri ]
		ifNotNil: [ :f | f asFileReference basename ].

	(self isDownloaded: fileName) ifTrue: [ 
		^ ZnResponse notFound: aRequest uri
	].
	
	response := super handleRequest: request.
	
	response headers at: 'Content-Disposition:' put: ('attachment; filename="{1}"' format: { 
		self filename ifEmpty: [ fileName ]
	}).
	
	self downloaded: fileName.

	^ response
]

{ #category : 'initialization' }
PhexImageDownloader >> initialize [

	super initialize.

	filename := String empty.
	self disableLinkReuse
]

{ #category : 'private' }
PhexImageDownloader >> isDownloaded: aFileName [

	^ linkReuseEnabled not and: [ self downloads includes: aFileName ]
]

{ #category : 'private' }
PhexImageDownloader >> registry [

	^ (directory / 'downloads.json') 
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
