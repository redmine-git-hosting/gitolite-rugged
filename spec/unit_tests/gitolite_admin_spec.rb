require 'spec_helper'

describe Gitolite::GitoliteAdmin do
  conf_dir   = File.join(File.dirname(__FILE__), '..', 'fixtures', 'configs')
  repo_dir   = File.join(File.dirname(__FILE__), '..', 'fixtures', 'gitolite-admin')

  # Rugged doesn't complain when giving nil keys for testing
  settings = {private_key: nil, public_key: nil, update_on_init: false}


  def in_fake_gitolite_repo(source_dir, &block)
    Dir.mktmpdir('gitolite-rugged-admin-repo') do |dir|
      tmp_repo = File.join(dir, "gitolite-admin")
      FileUtils.cp_r(source_dir, tmp_repo)
      FileUtils.mv(File.join(tmp_repo, ".gitted"), File.join(tmp_repo, '.git'))
      yield tmp_repo
    end
  end


  describe '#is_gitolite_admin_repo?' do
    it 'should detect a non gitolite-admin repository' do
      expect(GitoliteAdmin.is_gitolite_admin_repo?('/tmp')).to be false
    end
  end


  describe '#admin_url' do
    it 'should give Gitolite Admin url' do
      in_fake_gitolite_repo(repo_dir) do |tmp_repo|
        gl_admin = GitoliteAdmin.new(tmp_repo, settings)
        expect(gl_admin.admin_url).to eq 'ssh://git@localhost/gitolite-admin.git'
      end
    end
  end


  describe '#config' do
    it 'should render gitolite config' do
      in_fake_gitolite_repo(repo_dir) do |tmp_repo|
        gl_admin = GitoliteAdmin.new(tmp_repo, settings)
        expect(gl_admin.config).to be_a Gitolite::Config
      end
    end
  end


  describe '#ssh_keys' do
    it 'should render gitolite config' do
      in_fake_gitolite_repo(repo_dir) do |tmp_repo|
        gl_admin = GitoliteAdmin.new(tmp_repo, settings)
        expect(gl_admin.ssh_keys).to be_a Hash
      end
    end
  end


  describe '#save' do
    it 'should commit file to gitolite-admin repository' do
      in_fake_gitolite_repo(repo_dir) do |tmp_repo|
        gl_admin = GitoliteAdmin.new(tmp_repo, settings)

        c = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
        c.filename = 'gitolite.conf'

        gl_admin.config = c
        gl_admin.save

        new_file = File.join(tmp_repo, 'conf', c.filename)
        expect(File.file?(new_file)).to be true
        expect(IO.read(new_file)).to eq IO.read(File.join(conf_dir, 'complicated-output.conf'))
      end
    end
  end

end
