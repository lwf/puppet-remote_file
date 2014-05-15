# remote_file

Provides remote_file, a resource to download remote files. Tests forthcoming.

## Usage

```puppet
remote_file { '/path/to/your/file':
        ensure   => 'present',
        source   => 'http://example.com/file.tar.gz',
        checksum => 'd41d8cd98f00b204e9800998ecf8427e'
}
```

## License

Apache License Version 2.0

## Contact

Torbjörn Norinder
