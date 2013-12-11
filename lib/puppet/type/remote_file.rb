require 'uri'

Puppet::Type.newtype(:remote_file) do
  ensurable

  newparam(:name) do
    desc "File path"
    isnamevar
    validate do |value|
      unless value =~ /^(\/.*[^\/]|[c-zC-Z]:(\/|\\).*[^(\/|\\)])$/
        raise ArgumentError.new("%s is not a valid fully qualified path" % value)
      end
    end
  end

  newparam(:source) do
    desc "Location of the source file."
    validate do |value|
      unless value =~ URI.regexp(['http', 'https', 'file'])
        raise ArgumentError.new("%s is not a valid URL" % value)
      end
    end
  end

  newparam(:checksum) do
    desc "MD5 checksum of this file. Will not download if local file matches"
    validate do |value|
      unless value.empty? or value.length == 32
        raise ArgumentError.new("%s is not a valid MD5 hash, should be exactly 32 bytes long" % value)
      end
    end
  end
end
