Puppet::Type.newtype(:remote_file) do
  ensurable

  newparam(:name) do
    desc "File path"
    isnamevar
  end

  newparam(:source) do
    desc "Location of the source file."
  end

  newparam(:checksum) do
    desc "MD5 checksum of this file. Will not download if local file matches"
  end
end
