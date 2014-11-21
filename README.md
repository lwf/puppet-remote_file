# remote_file

Provides remote_file, a resource to download remote files. Tests forthcoming.

## Usage

```puppet
remote_file { '/path/to/your/file':
  ensure   => present,
  source   => 'http://example.com/file.tar.gz',
  checksum => 'd41d8cd98f00b204e9800998ecf8427e'
}
```

If the remote source provides an HTTP Last-Modified header, the type can
alternatively ensure the last-modified version of the remote file is deployed
(as determined by the Last-Modified time).

````puppet
remote_file { 'jenkins.war':
  ensure   => latest,
  path     => '/opt/apache-tomcat/tomcat8/webapps/jenkins.war',
  source   => 'http://updates.jenkins-ci.org/latest/jenkins.war',
}
````

## License

Apache License Version 2.0

## Contact

Torbjörn Norinder
