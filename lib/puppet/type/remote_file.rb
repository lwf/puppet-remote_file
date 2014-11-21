require 'uri'

Puppet::Type.newtype(:remote_file) do

  feature :lastmodified, "The provider can check http last-modified"

  ensurable do
    defaultvalues
    defaultto :present

    newvalue(:latest, :required_features => :lastmodified) do
      provider.create
    end

    def should_to_s(newvalue = @should)
      if newvalue == :latest
        # This code may throw errors if we cannot retrieve the latest available
        # version. If we cannot determine the remote mtime, just fall back to
        # saying we're trying to enforce "latest".
        begin
          provider.remote_mtime.iso8601
        rescue Exception
          'latest'
        end
      else
        super newvalue
      end
    end

    def change_to_s(current_value, new_value)
      if current_value == :absent and @should.include?(:latest)
        "created with last-modified version #{should_to_s(new_value)}"
      elsif @should.include?(:latest)
        "replaced #{current_value} version with last-modified version, #{should_to_s(new_value)}"
      else
        super(current_value, new_value)
      end
    end

    def retrieve
      if @should.include?(:latest)
        return :absent unless provider.exists?
        provider.local_mtime.iso8601
      else
        super
      end
    end

    def insync?(is)
      if @should.include?(:latest)
        is == provider.remote_mtime.iso8601
      else
        super
      end
    end
  end

  newparam(:path) do
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

  newparam(:verify_peer) do
    desc "Whether or not to require verification of the the remote server identity"
    validate do |value|
      unless (value =~ /true|false/i or [true, false].include?(value))
        raise ArgumentError.new("#{value} is not a boolean, should be either true or false")
      end
    end
    munge do |value|
      case value
      when /true/i
        true
      when /false/i
        false
      else
        value
      end
    end
  end

  newparam(:username) do
    desc "Basic authentication username"
  end

  newparam(:password) do
    desc "Basic authentication password"
  end

  validate do
    # :username and :password must be specified together. It is an error to
    # specify one but not the other. If only one is specified, fail validation.
    if !parameters[:username].nil? ^ !parameters[:password].nil?
      fail "username and password must both be specified if either is specified"
    end
  end
end
