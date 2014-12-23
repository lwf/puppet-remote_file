# remote_file

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [License](#license)
8. [Contact](#contact)

## Overview

Provides a resource type to download files from remote servers.

## Module Description

The remote_file module provides a utility resource type to download files from
remote servers. This is useful in situations where application content is being
served from a non-package file repository, where a local copy of installation
media for software needs to be retrieved as part of a custom installation
procedure, or any number of other use cases.

Retrieving content from remote servers is a general and very basic
configuration capability.

## Usage

Specify the path to a file that should exist locally, and parameters that
describe where to get it if it does not exist or is not in sync. For example:

```puppet
remote_file { '/etc/myfile':
  ensure => present,
  source => 'http://example.com/file.tar.gz',
}
```

The `path` parameter is the remote_file type's namevar.

```puppet
remote_file { 'app_config_file':
  ensure => present,
  path   => '/etc/myfile',
  source => 'http://example.com/file.tar.gz',
}
```

In the above examples, the `/etc/myfile` resource is considered to be in sync
if it exists. If it does not, it will be downloaded from the specified source
and whatever content is retrieved will be saved in the specified path. On
subsequent runs, so long as that file still exists, the resource will be
considered in sync.

The `remote_file` type supports tighter synchronization tolerances either
through the specification of an md5 checksum or by checking a remote HTTP
server's Last-Modified header. For example, the following resource specifies a
checksum:

```puppet
remote_file { '/path/to/your/file':
  ensure   => present,
  source   => 'http://example.com/file.tar.gz',
  checksum => 'd41d8cd98f00b204e9800998ecf8427e'
}
```

If the remote source provides an HTTP Last-Modified header, the remote_file
type can use that information to determine synchronization. When a file is
downloaded, its mtime is set to match the server's Last-Modified header.
Synchronization is later satisfied if the mtime of the local file matches the
Last-Modified header from the remote server.

```puppet
remote_file { 'jenkins.war':
  ensure   => latest,
  path     => '/opt/apache-tomcat/tomcat8/webapps/jenkins.war',
  source   => 'http://updates.jenkins-ci.org/latest/jenkins.war',
}
```

## Reference

### Type: remote_file

#### Parameters

* `ensure`: Valid values are present, absent, latest.
* `path`: Namevar. The local path to the file, or where to save the remote
  content to.
* `source`: The source location of the file, or where to get it from if it is
  needed. This should be a URI.
* `checksum`: MD5 checksum of this file. A new copy of the file will not be
  downloaded if the local file's checksum matches this value.
* `verify_peer`: Boolean. Whether or not to require verification of the the
  remote server identity.
* `username`: Username to use for basic authentication.
* `password`: Password to use for basic authentication.


### Provider: ruby

The ruby provider, included with this module, implements the remote_file type
using Net::HTTP from Ruby's standard library.

## Limitations

Currently only http, https, and file URI sources are supported by the default
ruby provider.

## License

Apache License Version 2.0

## Contact

Torbjörn Norinder
