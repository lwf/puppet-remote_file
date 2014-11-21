require 'digest/md5'

class Puppet::Provider::Remote_file < Puppet::Provider
  def destroy
    File.unlink @resource[:path]
  end

  def exists?
    if File.file? @resource[:path]
      if cs = @resource[:checksum]
        Digest::MD5.file(@resource[:path]) == cs
      else
        true
      end
    end
  end
end
