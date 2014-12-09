##
# List tags of the remote repo
class GitTags

  def initialize(remote)
    @remote = remote
  end
  attr_accessor :remote

  def refs
    @refs ||= rows.map(&:chomp)
  end

  def rows
    @rows ||= IO.popen(%{git ls-remote --tags #{remote}}).readlines
  end

  def tags
    @tags ||= refs.map { |row| row.sub(%r{^.*refs/tags/([^\^]*).*$}, "#{$1}")}.uniq.compact.sort
  end

end
