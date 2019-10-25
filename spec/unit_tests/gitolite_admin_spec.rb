require 'spec_helper'
require 'ostruct'

RSpec.describe Gitolite::GitoliteAdmin do

  def build_gitolite_admin_klass(path = '/tmp/toto')
    Gitolite::GitoliteAdmin.new(path, { private_key: nil, public_key: nil, update_on_init: false })
  end


  def build_ssh_key_klass
    Gitolite::SSHKey.from_string(Faker::Ssh.public_key, 'root')
  end


  def in_fake_gitolite_repo(source_dir, &block)
    Dir.mktmpdir('gitolite-rugged-admin-repo') do |dir|
      tmp_repo = File.join(dir, 'gitolite-admin')
      FileUtils.cp_r(source_dir, tmp_repo)
      FileUtils.mv(File.join(tmp_repo, '.gitted'), File.join(tmp_repo, '.git'))
      yield tmp_repo
    end
  end


  describe '.is_gitolite_admin_repo?' do
    it 'should detect a non gitolite-admin repository' do
      expect(Gitolite::GitoliteAdmin.is_gitolite_admin_repo?('/tmp')).to be false
    end
  end


  describe 'mocked/stubbed' do
    let(:klass) { build_gitolite_admin_klass }

    before(:each) { expect_any_instance_of(Gitolite::GitoliteAdmin).to receive(:set_repo).and_return(double('Rugged::Repository')) }

    describe '#path' do
      it 'should return the path of the Gitolite Admin repository' do
        expect(klass.path).to eq '/tmp/toto'
      end
    end


    describe '#config' do
      it 'should return the current config' do
        expect(klass.config).to be_an_instance_of(Gitolite::Config)
      end
    end


    describe '#config' do
      it 'should set a new configuration' do
        config = Gitolite::Config.new(fixture_path('configs', 'complicated.conf'))
        expect(klass.config = config).to be_an_instance_of(Gitolite::Config)
      end
    end


    describe '#ssh_keys' do
      it 'should return a hash of keys' do
        expect(klass.ssh_keys).to be_a Hash
      end
    end


    describe '#reload!' do
      it 'should reload the configuration' do
        expect(klass).to receive(:load_keys)
        expect(klass).to receive(:load_config)
        klass.reload!
      end
    end


    describe '#admin_url' do
      it 'should return Gitolite admin url' do
        expect(klass.admin_url).to eq 'ssh://git@localhost/gitolite-admin.git'
      end
    end


    describe '#commit_author' do
      it 'should return a hash about git author' do
        expect(klass.commit_author).to eq({ email: 'gitolite-rugged@localhost', name: 'gitolite-rugged gem' })
      end
    end


    describe '#exists?' do
      it 'should say if the Gitolite Admin directory exists' do
        expect(Dir).to receive(:exists?).with(klass.path)
        klass.exists?
      end
    end


    describe '#config_dir_path' do
      it 'should give Gitolite config_dir_path' do
        expect(klass.config_dir_path).to eq File.join('/tmp/toto', 'conf')
      end
    end


    describe '#config_file_path' do
      it 'should give Gitolite config_file_path' do
        expect(klass.config_file_path).to eq File.join('/tmp/toto', 'conf', 'gitolite.conf')
      end
    end


    describe '#key_dir_path' do
      it 'should give Gitolite key_dir_path' do
        expect(klass.key_dir_path).to eq File.join('/tmp/toto', 'keydir/')
      end
    end


    describe '#relative_config_file' do
      it 'should give Gitolite relative_config_file' do
        expect(klass.relative_config_file).to eq 'conf/gitolite.conf'
      end
    end


    describe '#relative_key_dir' do
      it 'should give Gitolite relative_key_dir' do
        expect(klass.relative_key_dir).to eq 'keydir/'
      end
    end


    describe '#lock_file_path' do
      it 'should give Gitolite lock_file_path' do
        expect(klass.lock_file_path).to eq File.join('/tmp/toto', '.lock')
      end
    end


    describe '#get_references' do
      context 'when reference exists' do
        it 'should return a commit id' do
          expect(klass.repo).to receive(:references).and_return({ 'foo' => OpenStruct.new(target: 'commit_id') })
          expect(klass.get_references('foo')).to eq 'commit_id'
        end
      end

      context 'when reference dont exists' do
        it 'should return nil' do
          expect(klass.repo).to receive(:references).and_return({})
          klass.get_references('foo')
        end
      end
    end


    describe '#add_key' do
      it 'should raise an error if param passed is not a Gitolite::SSHKey' do
        expect {
          klass.add_key('toto')
        }.to raise_error(ArgumentError)
      end

      it 'should add a ssh key to the global hash' do
        key = build_ssh_key_klass
        expect(klass.add_key(key)).to be true
      end
    end


    describe '#rm_key' do
      it 'should raise an error if param passed is not a Gitolite::SSHKey' do
        expect {
          klass.rm_key('toto')
        }.to raise_error(ArgumentError)
      end

      context 'when the key exists' do
        it 'should remove a ssh key from the global hash' do
          key = build_ssh_key_klass
          expect(klass.add_key(key)).to be true
          expect(klass.rm_key(key)).to be true
        end
      end

      context 'when the key dont exists' do
        it 'should remove a ssh key from the global hash' do
          key = build_ssh_key_klass
          expect(klass.rm_key(key)).to be false
        end
      end
    end


    describe '#clone' do
      it 'should clone the Gitolite admin repository' do
        expect(klass).to receive(:clean_up)
        expect(Rugged::Repository).to receive(:clone_at).with(klass.admin_url, klass.path, credentials: klass.credentials)
        klass.clone
      end
    end


    describe '#clean_up' do
      it 'should clean_up the Gitolite admin repository' do
        expect(klass).to receive(:exists?).and_return(true)
        expect(FileUtils).to receive(:rm_rf).with(klass.path)
        klass.clean_up
      end
    end


    describe '#reset!' do
      it 'should reset the configuration' do
        expect(klass.repo).to receive(:reset).with('origin/master', :hard)
        klass.reset!
      end
    end


    describe '#apply' do
      it 'should apply the configuration' do
        expect(klass.repo).to receive(:push).with('origin', ['refs/heads/master'], credentials: klass.credentials)
        klass.apply
      end
    end



    describe '#update' do
      it 'should update the repository with remote content' do
        index = double('Rugged::Index')
        expect(klass).to receive(:reset!)
        expect(klass).to receive(:local_branch).at_least(:once).and_return('refs/heads/master')
        expect(klass).to receive(:remote_branch).at_least(:once).and_return('refs/heads/master')
        expect(klass.repo).to receive(:fetch).with('origin', credentials: klass.credentials)
        expect(klass.repo).to receive(:merge_commits).with(klass.local_branch, klass.remote_branch).and_return(index)
        expect(index).to receive(:write_tree).with(klass.repo).and_return('foo')
        expect(Rugged::Commit).to receive(:create)
        expect(klass).to receive(:reload!)
        klass.update
      end
    end


    describe '#save_and_apply' do
      it 'should save_and_apply the configuration' do
        expect(klass).to receive(:save).with('message')
        expect(klass).to receive(:apply)
        klass.save_and_apply('message')
      end
    end


    describe '#transaction' do
      it 'should put a lock around the action' do
        FileUtils.touch '/tmp/toto'
        expect(klass).to receive(:lock_file_path).and_return('/tmp/toto')
        expect(klass).to receive(:apply)
        expect { |b|
          klass.transaction(&b)
        }.to yield_with_no_args
        FileUtils.rm_f '/tmp/toto'
      end
    end


    describe '#local_branch' do
      it 'should return the local_branch' do
        expect(klass).to receive(:get_references).with('refs/heads/master')
        klass.local_branch
      end
    end


    describe '#remote_branch' do
      it 'should return the remote_branch' do
        expect(klass).to receive(:get_references).with('refs/remotes/origin/master')
        klass.remote_branch
      end
    end


    describe '#update_ref' do
      it 'should return the update_ref' do
        expect(klass.update_ref).to eq 'refs/heads/master'
      end
    end


    describe '#update_message' do
      it 'should return the update_message' do
        expect(klass.update_message).to eq "[gitolite-rugged] Merged `origin/master` into `master`"
      end
    end

  end


  describe 'for real' do
    describe '#save' do
      it 'should commit file to gitolite-admin repository' do
        in_fake_gitolite_repo(fixture_path('gitolite-admin')) do |tmp_repo|
          gl_admin = build_gitolite_admin_klass(tmp_repo)

          config = Gitolite::Config.new(fixture_path('configs', 'complicated.conf'))
          config.filename = 'gitolite.conf'

          gl_admin.config = config
          gl_admin.save

          new_file = File.join(tmp_repo, 'conf', config.filename)

          expect(File.file?(new_file)).to be true
          expect(IO.read(new_file)).to eq IO.read(fixture_path('configs', 'complicated-output.conf'))
        end
      end
    end
  end

end
