require 'spec_helper'

describe Gitolite::GitoliteAdmin do
  conf_dir   = File.join(File.dirname(__FILE__), 'fixtures', 'configs')
  repo_dir   = File.join(File.dirname(__FILE__), 'fixtures', 'gitolite-admin')

  # Rugged doesn't complain when giving nil keys for testing
  settings = {private_key: nil, public_key: nil, update_on_init: false}

  describe '#is_gitolite_admin_repo?' do
    it 'should detect a non gitolite-admin repository' do
      expect(GitoliteAdmin.is_gitolite_admin_repo?('/tmp')).to be false
    end
  end

  describe '#save' do
    it 'should commit file to gitolite-admin repository' do
      Dir.mktmpdir('gitolite-rugged-admin-repo') do |dir|

        tmp_repo = File.join(dir, "gitolite-admin")
        FileUtils.cp_r(repo_dir, tmp_repo)
        FileUtils.mv(File.join(tmp_repo, ".gitted"), File.join(tmp_repo, '.git'))

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
