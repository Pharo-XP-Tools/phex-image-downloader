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

## Usage example

To start a PhexImageDownloader on the port 8080 and serve the directory of images in `{home}/images`, execute the following snippet:

```st
PhexImageDownloader start: 8080 directory: FileLocator home / 'images'
```

## Dependencies

I rely on Zinc-HTTP, in particular ZnServer and ZnClient.
