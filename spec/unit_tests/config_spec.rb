require 'spec_helper'

RSpec.describe Gitolite::Config do

  conf_dir   = File.join(File.dirname(__FILE__), '..', 'fixtures', 'configs')
  output_dir = '/tmp'

  describe "#new" do
    it 'should read a simple configuration' do
      c = Gitolite::Config.new(File.join(conf_dir, 'simple.conf'))
      expect(c.repos.length).to eq 2
      expect(c.groups.length).to eq 0
    end

    it 'should read a complex configuration' do
      c = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      expect(c.groups.length).to eq 5
      expect(c.repos.length).to eq 13
    end

    describe 'gitweb operations' do
      before :all do
        @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      end

      it 'should correctly read gitweb options for an existing repo' do
        r = @config.get_repo('gitolite')
        expect(r.owner).to eq "Sitaram Chamarty"
        expect(r.description).to eq "fast, secure, access control for git in a corporate environment"
      end

      it 'should correctly read a gitweb option with no owner for an existing repo' do
        r = @config.get_repo('foo')
        expect(r.owner).to be nil
        expect(r.description).to eq "Foo is a nice test repo"
      end

      it 'should correctly read gitweb options for a new repo' do
        r = @config.get_repo('foobar')
        expect(r.owner).to eq "Bob Zilla"
        expect(r.description).to eq "Foobar is top secret"
      end

      it 'should correctly read gitweb options with no owner for a new repo' do
        r = @config.get_repo('bar')
        expect(r.owner).to be nil
        expect(r.description).to eq "A nice place to get drinks"
      end

      it 'should raise a ParseError when a description is not specified' do
        t = Tempfile.new('bad_conf.conf')
        t.write('gitolite "Bob Zilla"')
        t.close

        expect { Gitolite::Config.new(t.path) }.to raise_error(Gitolite::Config::ParseError)

        t.unlink
      end

      it 'should raise a ParseError when a Gitweb description is specified for a group' do
        t = Tempfile.new('bad_conf.conf')
        t.write('@gitolite "Bob Zilla" = "Test description"')
        t.close

        expect { Gitolite::Config.new(t.path) }.to raise_error(Gitolite::Config::ParseError)

        t.unlink
      end
    end

    describe "git config settings" do
      before :all do
        @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      end

      it 'should correctly read in git config settings' do
        r = @config.get_repo(:gitolite)
        expect(r.config.length).to eq 4
      end
    end

    describe "gitolite options" do
      before :all do
        @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      end

      it 'should correctly read in gitolite options' do
        r = @config.get_repo(:foo)
        expect(r.options.length).to eq 3
      end

      it 'should raise a ParseError when a value is not specified' do
        t = Tempfile.new('bad_conf.conf')
        t.write("repo foobar\n  option mirror.master =")
        t.close

        expect { Gitolite::Config.new(t.path) }.to raise_error(Gitolite::Config::ParseError)

        t.unlink
      end
    end
  end

  # describe "#init" do
  #   it 'should create a valid, blank Gitolite::Config' do
  #     c = Gitolite::Config.init

  #     c.should be_an_instance_of Gitolite::Config
  #     c.repos.should_not be nil
  #     c.repos.length.should be 0
  #     c.groups.should_not be nil
  #     c.groups.length.should be 0
  #     c.filename.should == "gitolite.conf"
  #   end

  #   it 'should create a valid, blank Gitolite::Config with the given filename' do
  #     filename = "test.conf"
  #     c = Gitolite::Config.init(filename)

  #     c.should be_an_instance_of Gitolite::Config
  #     c.repos.should_not be nil
  #     c.repos.length.should be 0
  #     c.groups.should_not be nil
  #     c.groups.length.should be 0
  #     c.filename.should == filename
  #   end
  # end

  describe "repo management" do
    before :each do
      @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
    end

    describe "#get_repo" do
      it 'should fetch a repo by a string containing the name' do
        expect(@config.get_repo('gitolite')).to be_an_instance_of Gitolite::Config::Repo
      end

      it 'should fetch a repo via a symbol representing the name' do
        expect(@config.get_repo(:gitolite)).to be_an_instance_of Gitolite::Config::Repo
      end

      it 'should return nil for a repo that does not exist' do
        expect(@config.get_repo(:glite)).to be nil
      end
    end

    describe "#has_repo?" do
      it 'should return false for a repo that does not exist' do
        expect(@config.has_repo?(:glite)).to be false
      end

      it 'should check for the existance of a repo given a repo object' do
        r = @config.repos["gitolite"]
        expect(@config.has_repo?(r)).to be true
      end

      it 'should check for the existance of a repo given a string containing the name' do
        expect(@config.has_repo?('gitolite')).to be true
      end

      it 'should check for the existance of a repo given a symbol representing the name' do
        expect(@config.has_repo?(:gitolite)).to be true
      end
    end

    describe "#add_repo" do
      it 'should throw an ArgumentError for non-Gitolite::Config::Repo objects passed in' do
        expect { @config.add_repo("not-a-repo") }.to raise_error(ArgumentError)
      end

      it 'should add a given repo to the list of repos' do
        r = Gitolite::Config::Repo.new('cool_repo')
        nrepos = @config.repos.size
        @config.add_repo(r)

        expect(@config.repos.size).to eq nrepos + 1
        expect(@config.has_repo?(:cool_repo)).to be true
      end

      it 'should merge a given repo with an existing repo' do
        #Make two new repos
        repo1 = Gitolite::Config::Repo.new('cool_repo')
        repo2 = Gitolite::Config::Repo.new('cool_repo')

        #Add some perms to those repos
        repo1.add_permission("RW+", "", "bob", "joe", "sam")
        repo1.add_permission("R", "", "sue", "jen", "greg")
        repo1.add_permission("-", "refs/tags/test[0-9]", "@students", "jessica")
        repo1.add_permission("RW", "refs/tags/test[0-9]", "@teachers", "bill", "todd")
        repo1.add_permission("R", "refs/tags/test[0-9]", "@profs")

        repo2.add_permission("RW+", "", "jim", "cynthia", "arnold")
        repo2.add_permission("R", "", "daniel", "mary", "ben")
        repo2.add_permission("-", "refs/tags/test[0-9]", "@more_students", "stephanie")
        repo2.add_permission("RW", "refs/tags/test[0-9]", "@student_teachers", "mike", "judy")
        repo2.add_permission("R", "refs/tags/test[0-9]", "@leaders")

        #Add the repos
        @config.add_repo(repo1)
        @config.add_repo(repo2)

        #Make sure perms were properly merged
      end

      it 'should overwrite an existing repo when overwrite = true' do
        #Make two new repos
        repo1 = Gitolite::Config::Repo.new('cool_repo')
        repo2 = Gitolite::Config::Repo.new('cool_repo')

        #Add some perms to those repos
        repo1.add_permission("RW+", "", "bob", "joe", "sam")
        repo1.add_permission("R", "", "sue", "jen", "greg")
        repo2.add_permission("RW+", "", "jim", "cynthia", "arnold")
        repo2.add_permission("R", "", "daniel", "mary", "ben")

        #Add the repos
        @config.add_repo(repo1)
        @config.add_repo(repo2, true)

        #Make sure repo2 overwrote repo1
      end
    end

    describe "#rm_repo" do
      it 'should remove a repo for the Gitolite::Config::Repo object given' do
        r = @config.get_repo(:gitolite)
        r2 = @config.rm_repo(r)
        expect(r2.name).to eq r.name
        expect(r2.permissions.length).to eq r.permissions.length
        expect(r2.owner).to eq r.owner
        expect(r2.description).to eq r.description
      end

      it 'should remove a repo given a string containing the name' do
        r = @config.get_repo(:gitolite)
        r2 = @config.rm_repo('gitolite')
        expect(r2.name).to eq r.name
        expect(r2.permissions.length).to eq r.permissions.length
        expect(r2.owner).to eq r.owner
        expect(r2.description).to eq r.description
      end

      it 'should remove a repo given a symbol representing the name' do
        r = @config.get_repo(:gitolite)
        r2 = @config.rm_repo(:gitolite)
        expect(r2.name).to eq r.name
        expect(r2.permissions.length).to eq r.permissions.length
        expect(r2.owner).to eq r.owner
        expect(r2.description).to eq r.description
      end
    end
  end

  describe "group management" do
    before :each do
      @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
    end

    describe "#has_group?" do
      it 'should find the staff group using a symbol' do
        expect(@config.has_group?(:staff)).to be true
      end

      it 'should find the staff group using a string' do
       expect(@config.has_group?('staff')).to be true
      end

      it 'should find the staff group using a Gitolite::Config::Group object' do
        g = Gitolite::Config::Group.new("staff")
        expect(@config.has_group?(g)).to be true
      end
    end

    describe "#get_group" do
      it 'should return the Gitolite::Config::Group object for the group name String' do
        g = @config.get_group("staff")
        expect(g.is_a?(Gitolite::Config::Group)).to be true
        expect(g.size).to eq 6
      end

      it 'should return the Gitolite::Config::Group object for the group name Symbol' do
        g = @config.get_group(:staff)
        expect(g.is_a?(Gitolite::Config::Group)).to be true
        expect(g.size).to eq 6
      end
    end

    describe "#add_group" do
      it 'should throw an ArgumentError for non-Gitolite::Config::Group objects passed in' do
        expect { @config.add_group("not-a-group") }.to raise_error(ArgumentError)
      end

      it 'should add a given group to the groups list' do
        g = Gitolite::Config::Group.new('cool_group')
        ngroups = @config.groups.size
        @config.add_group(g)
        expect(@config.groups.size).to eq ngroups + 1
        expect(@config.has_group?(:cool_group)).to be true
      end

    end

    describe "#rm_group" do
      it 'should remove a group for the Gitolite::Config::Group object given' do
        g = @config.get_group(:oss_repos)
        g2 = @config.rm_group(g)
        expect(g).to_not be nil
        expect(g2.name).to eq g.name
      end

      it 'should remove a group given a string containing the name' do
        g = @config.get_group(:oss_repos)
        g2 = @config.rm_group('oss_repos')
        expect(g2.name).to eq g.name
      end

      it 'should remove a group given a symbol representing the name' do
        g = @config.get_group(:oss_repos)
        g2 = @config.rm_group(:oss_repos)
        expect(g2.name).to eq g.name
      end
    end

  end

  describe "#to_file" do
    it 'should create a file at the given path with the config\'s file name' do
      c = Gitolite::Config.init
      file = c.to_file(output_dir)
      expect(File.file?(File.join(output_dir, c.filename))).to be true
      File.unlink(file)
    end

    it 'should create a file at the given path with the config file passed' do
      c = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      file = c.to_file(output_dir)
      expect(File.file?(File.join(output_dir, c.filename))).to be true
    end

    it 'should create a file at the given path when a different filename is specified' do
      filename = "test.conf"
      c = Gitolite::Config.init
      c.filename = filename
      file = c.to_file(output_dir)
      expect(File.file?(File.join(output_dir, filename))).to be true
      File.unlink(file)
    end

    it 'should create the given directory if it does not exist' do
      c = Gitolite::Config.init
      Dir.mktmpdir("foo") do |dir|
        target = File.join(dir, "someconfigfile")
        expect(File.exist?(target)).to be false
        c.to_file(target)
        expect(File.exist?(target)).to be true
      end
    end

    it 'should resolve group dependencies such that all groups are defined before they are used' do
      c = Gitolite::Config.init
      c.filename = "test_deptree.conf"

      # Build some groups out of order
      g = Gitolite::Config::Group.new "groupa"
      g.add_users "bob", "@groupb"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupb"
      g.add_users "joe", "sam", "susan", "andrew"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupc"
      g.add_users "jane", "@groupb", "brandon"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupd"
      g.add_users "larry", "@groupc"
      c.add_group(g)

      # Write the config to a file
      file = c.to_file(output_dir)

      # Read the conf and make sure our order is correct
      f = File.read(file)
      lines = f.lines.map {|l| l.strip}

      # Compare the file lines.  Spacing is important here since we are doing a direct comparision
      expect(lines[0]).to eq "@groupb             = andrew joe sam susan"
      expect(lines[1]).to eq "@groupc             = @groupb brandon jane"
      expect(lines[2]).to eq "@groupd             = @groupc larry"
      expect(lines[3]).to eq "@groupa             = @groupb bob"

      # Cleanup
      File.unlink(file)
    end

    it 'should raise a GroupDependencyError if there is a cyclic dependency' do
      c = Gitolite::Config.init
      c.filename = "test_deptree.conf"

      # Build some groups out of order
      g = Gitolite::Config::Group.new "groupa"
      g.add_users "bob", "@groupb"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupb"
      g.add_users "joe", "sam", "susan", "@groupc"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupc"
      g.add_users "jane", "@groupa", "brandon"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupd"
      g.add_users "larry", "@groupc"
      c.add_group(g)

      # Attempt to write the config file
      expect { c.to_file(output_dir)}.to raise_error(Gitolite::Config::GroupDependencyError)
    end

    it 'should resolve group dependencies even when there are disconnected portions of the graph' do
      c = Gitolite::Config.init
      c.filename = "test_deptree.conf"

      # Build some groups out of order
      g = Gitolite::Config::Group.new "groupa"
      g.add_users "bob", "timmy", "stephanie"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupb"
      g.add_users "joe", "sam", "susan", "andrew"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupc"
      g.add_users "jane", "earl", "brandon", "@groupa"
      c.add_group(g)

      g = Gitolite::Config::Group.new "groupd"
      g.add_users "larry", "chris", "emily"
      c.add_group(g)

      # Write the config to a file
      file = c.to_file(output_dir)

      # Read the conf and make sure our order is correct
      f = File.read(file)
      lines = f.lines.map {|l| l.strip}

      # Compare the file lines.  Spacing is important here since we are doing a direct comparision
      expect(lines[0]).to eq "@groupd             = chris emily larry"
      expect(lines[1]).to eq "@groupb             = andrew joe sam susan"
      expect(lines[2]).to eq "@groupa             = bob stephanie timmy"
      expect(lines[3]).to eq "@groupc             = @groupa brandon earl jane"

      # Cleanup
      File.unlink(file)
    end
  end

  describe "#gitweb_descriptions" do
    it 'should return a list of gitweb descriptions' do
      c = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      expect(c.gitweb_descriptions).to eq [
        "bar = \"A nice place to get drinks\"",
        "foo = \"Foo is a nice test repo\"",
        "foobar \"Bob Zilla\" = \"Foobar is top secret\"",
        "gitolite \"Sitaram Chamarty\" = \"fast, secure, access control for git in a corporate environment\""
      ]
    end
  end


  describe "#cleanup_config_line" do
    before(:each) do
      @config = Gitolite::Config.init
    end

    it 'should remove comments' do
      s = "#comment"
      expect(@config.instance_eval { cleanup_config_line(s) }.empty?).to be true
    end

    it 'should remove inline comments, keeping content before the comment' do
      s = "blablabla #comment"
      expect(@config.instance_eval { cleanup_config_line(s) }).to eq "blablabla"
    end

    it 'should pad = with spaces on each side' do
      s = "bob=joe"
      expect(@config.instance_eval { cleanup_config_line(s) }).to eq "bob = joe"
    end

    it 'should replace multiple space characters with a single space' do
      s = "bob       =        joe"
      expect(@config.instance_eval { cleanup_config_line(s) }).to eq "bob = joe"
    end

    it 'should cleanup whitespace at the beginning and end of lines' do
      s = "            bob = joe            "
      expect(@config.instance_eval { cleanup_config_line(s) }).to eq "bob = joe"
    end

    it 'should cleanup whitespace and comments effectively' do
      s = "            bob     =     joe             #comment"
      expect(@config.instance_eval { cleanup_config_line(s) }).to eq "bob = joe"
    end
  end
end
