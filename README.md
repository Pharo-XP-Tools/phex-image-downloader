# Phex image downloader

The EVREF experimental server does not expose any access to the stored files.  
To distribute Pharo images prepared for experiments, a server is required, hence this project.

## Installation

```st
Metacello new
  githubUser: 'Pharo-XP-Tools' project: 'Phex-Image-Downloader' commitish: 'main' path: 'src';
  baseline: 'PhexImageDownloader';
  load
```

## Description
`PhexImageDownloader` is an HTTP server that listens for requests to download a given file.

## Usage example

To start a PhexImageDownloader and:
- Serve the following directory `{home}/images`.
- Rename files to "archive.zip" as they are being downloaded.
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


**Link format**

To cope with special characters in filenames, the server expects base64 URIs.  
For example, `http://localhost:8008/ZXhhbXBsZS1maWxlbmFtZQ==`refers to `http://localhost:8008/example-filename`.

**Link usage**

By default, the server will not enable link reuse.  
To keep the state of used links it reads and updates the "downloads.json" file, at the root directory of the image.  
The "downloads.json" file contains the name of files already downloaded.  

```json
[ "filename1", "filename2" ]
```

During the download, the HTTP connection of a client might disconnect for various reasons.  
The project does not control the client's correct reception of the entire file.
Therefore the file link will be considered as already used and become unusable again,
In this case, it is possibe to re-activate the link, by removing the targeted filename from the "downloads.json" file.

However, beware, the server does not control the correct format of the "downloads.json" file.
Moreover, any modification to the "downloads.json" file is immediately taken into account by the server.
Wrong modifications can lead to unexpected answers or requests timeouts (debugger opening leading, hence no response delivered).

## Dependencies

I rely on Zinc-HTTP, in particular `ZnServer` and `ZnClient`.
