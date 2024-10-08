require 'spec_helper'

RSpec.describe Gitolite::Config::Repo do
  before(:each) do
    @repo = Gitolite::Config::Repo.new("CoolRepo")
  end

  describe '#new' do
    it 'should create a repo called "CoolRepo"' do
      expect(@repo.name).to eq "CoolRepo"
    end
  end

  describe "deny rules" do
    it 'should maintain the order of rules for a repository' do
      @repo.add_permission("RW+", "", "bob", "joe", "sam")
      @repo.add_permission("R", "", "sue", "jen", "greg")
      @repo.add_permission("-", "refs/tags/test[0-9]", "@students", "jessica")
      @repo.add_permission("RW", "refs/tags/test[0-9]", "@teachers", "bill", "todd")
      @repo.add_permission("R", "refs/tags/test[0-9]", "@profs")

      expect(@repo.permissions.length).to eq 2
      expect(@repo.permissions[0].size).to eq 2
      expect(@repo.permissions[1].size).to eq 3
    end
  end

  describe '#add_permission' do
    it 'should allow adding a permission to the permissions list' do
      @repo.add_permission("RW+")
      expect(@repo.permissions.length).to eq 1
      expect(@repo.permissions.first.keys.first).to eq "RW+"
    end

    it 'should allow adding a permission while specifying a refex' do
      @repo.add_permission("RW+", "refs/heads/master")
      expect(@repo.permissions.length).to eq 1
      expect(@repo.permissions.first.keys.first).to eq "RW+"
      expect(@repo.permissions.first.values.last.first.first).to eq "refs/heads/master"
    end

    it 'should allow specifying users individually' do
      @repo.add_permission("RW+", "", "bob", "joe", "susan", "sam", "bill")
      expect(@repo.permissions.first["RW+"][""]).to eq %w[bob joe susan sam bill]
    end

    it 'should allow specifying users as an array' do
      users = %w[bob joe susan sam bill]

      @repo.add_permission("RW+", "", users)
      expect(@repo.permissions.first["RW+"][""]).to eq users
    end

    it 'should not allow adding an invalid permission via an InvalidPermissionError' do
      expect { @repo.add_permission("BadPerm") }.to raise_error(Gitolite::Config::Repo::InvalidPermissionError)
    end
  end

  describe "permissions" do
    before(:each) do
      @repo = Gitolite::Config::Repo.new("CoolRepo")
    end

    it 'should allow adding the permission C' do
      @repo.add_permission("C", "", "bob")
    end

    it 'should allow adding the permission -' do
      @repo.add_permission("-", "", "bob")
    end

    it 'should allow adding the permission R' do
      @repo.add_permission("R", "", "bob")
    end

    it 'should allow adding the permission RM' do
      @repo.add_permission("RM", "", "bob")
    end

    it 'should allow adding the permission RW' do
      @repo.add_permission("RW", "", "bob")
    end

    it 'should allow adding the permission RWM' do
      @repo.add_permission("RWM", "", "bob")
    end

    it 'should allow adding the permission RW+' do
      @repo.add_permission("RW+", "", "bob")
    end

    it 'should allow adding the permission RW+M' do
      @repo.add_permission("RW+M", "", "bob")
    end

    it 'should allow adding the permission RWC' do
      @repo.add_permission("RWC", "", "bob")
    end

    it 'should allow adding the permission RWCM' do
      @repo.add_permission("RWCM", "", "bob")
    end

    it 'should allow adding the permission RW+C' do
      @repo.add_permission("RW+C", "", "bob")
    end

    it 'should allow adding the permission RW+CM' do
      @repo.add_permission("RW+CM", "", "bob")
    end

    it 'should allow adding the permission RWD' do
      @repo.add_permission("RWD", "", "bob")
    end

    it 'should allow adding the permission RWDM' do
      @repo.add_permission("RWDM", "", "bob")
    end

    it 'should allow adding the permission RW+D' do
      @repo.add_permission("RW+D", "", "bob")
    end

    it 'should allow adding the permission RW+DM' do
      @repo.add_permission("RW+DM", "", "bob")
    end

    it 'should allow adding the permission RWCD' do
      @repo.add_permission("RWCD", "", "bob")
    end

    it 'should allow adding the permission RWCDM' do
      @repo.add_permission("RWCDM", "", "bob")
    end

    it 'should allow adding the permission RW+CD' do
      @repo.add_permission("RW+CD", "", "bob")
    end

    it 'should allow adding the permission RW+CDM' do
      @repo.add_permission("RW+CDM", "", "bob")
    end
  end

  describe 'git config options' do
    it 'should allow setting a git configuration option' do
      email = "bob@zilla.com"
      expect(@repo.set_git_config("email", email)).to eq email
    end

    it 'should allow deletion of an existing git configuration option' do
      email = "bob@zilla.com"
      @repo.set_git_config("email", email)
      expect(@repo.unset_git_config("email")).to eq email
    end

  end

  describe 'gitolite options' do
    it 'should allow setting a gitolite option' do
      master = "kenobi"
      slaves = "one"
      expect(@repo.set_gitolite_option("mirror.master", master)).to eq master
      expect(@repo.set_gitolite_option("mirror.slaves", slaves)).to eq slaves
      expect(@repo.options.length).to eq 2
    end

    it 'should allow deletion of an existing gitolite option' do
      master = "kenobi"
      slaves = "one"
      @repo.set_gitolite_option("mirror.master", master)
      @repo.set_gitolite_option("mirror.slaves", slaves)
      expect(@repo.options.length).to eq 2
      expect(@repo.unset_gitolite_option("mirror.master")).to eq master
      expect(@repo.options.length).to eq 1
    end
  end

  describe 'permission management' do
    it 'should combine two entries for the same permission and refex' do
      users = %w[bob joe susan sam bill]
      more_users = %w[sally peyton andrew erin]

      @repo.add_permission("RW+", "", users)
      @repo.add_permission("RW+", "", more_users)
      expect(@repo.permissions.first["RW+"][""]).to eq users.concat(more_users)
      expect(@repo.permissions.first["RW+"][""].length).to eq 9
    end

    it 'should not list the same users twice for the same permission level' do
      users = %w[bob joe susan sam bill]
      more_users = %w[bob peyton andrew erin]
      even_more_users = %w[bob jim wayne courtney]

      @repo.add_permission("RW+", "", users)
      @repo.add_permission("RW+", "", more_users)
      @repo.add_permission("RW+", "", even_more_users)
      expect(@repo.permissions.first["RW+"][""]).to eq users.concat(more_users).concat(even_more_users).uniq!
      expect(@repo.permissions.first["RW+"][""].length).to eq 11
    end
  end
end
