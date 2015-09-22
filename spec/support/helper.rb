module Helper

  def load_fixture(*args)
    File.read(fixture_path(*args))
  end


  def fixture_path(*args)
    path = File.join(File.dirname(__FILE__), '..', 'fixtures', *args)
    File.expand_path(path)
  end

end
