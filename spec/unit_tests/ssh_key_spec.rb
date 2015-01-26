require 'spec_helper'

describe Gitolite::SSHKey do

  key_dir    = File.join(File.dirname(__FILE__), '..', 'fixtures', 'keys', 'bob')
  output_dir = '/tmp'

  describe "#from_string" do
    it 'should construct an SSH key from a string' do
      key = File.join(key_dir, 'bob.pub')
      key_string = File.read(key)
      s = SSHKey.from_string(key_string, "bob")

      expect(s.owner).to eq 'bob'
      expect(s.location).to eq ""
      expect(s.blob).to eq key_string.split[1]
    end

    it 'should raise an ArgumentError when an owner isnt specified' do
      key_string = "not_a_real_key"
      expect(lambda { SSHKey.from_string(key_string) }).to raise_error
    end

    it 'should have a location when one is specified' do
      key = File.join(key_dir, 'bob.pub')
      key_string = File.read(key)
      s = SSHKey.from_string(key_string, "bob", "kansas")

      expect(s.owner).to eq 'bob'
      expect(s.location).to eq "kansas"
      expect(s.blob).to eq key_string.split[1]
    end

    it 'should raise an ArgumentError when owner is nil' do
      expect(lambda { SSHKey.from_string("bad_string", nil) }).to raise_error
    end

    it 'should raise an ArgumentError when we get an invalid SSHKey string' do
      expect(lambda { SSHKey.from_string("bad_string", "bob") }).to raise_error
    end
  end

  describe "#from_file" do
    it 'should load a key from a file' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      key_string = File.read(key).split

      expect(s.owner).to eq "bob"
      expect(s.blob).to eq key_string[1]
      expect(s.location).to eq ''
    end

    it 'should load a key from a file' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      expect(s.owner).to eq 'bob'
      expect(s.location).to eq ''
    end

    it 'should load a key with an e-mail owner from a file' do
      key = File.join(key_dir, 'bob@example.com.pub')
      s = SSHKey.from_file(key)
      expect(s.owner).to eq 'bob@example.com'
      expect(s.location).to eq ''
    end

    it 'should load a key from a file within location' do
      key = File.join(key_dir, 'desktop', 'bob.pub')
      s = SSHKey.from_file(key)
      expect(s.owner).to eq 'bob'
      expect(s.location).to eq 'desktop'
    end

    it 'should load a key from a file within location' do
      key = File.join(key_dir, 'school', 'bob.pub')
      s = SSHKey.from_file(key)
      expect(s.owner).to eq 'bob'
      expect(s.location).to eq 'school'
    end
  end

  describe '#keys' do
    it 'should load ssh key properly' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      parts = File.read(key).split #should get type, blob, email

      expect(s.type).to eq parts[0]
      expect(s.blob).to eq parts[1]
      expect(s.email).to eq parts[2]
    end
  end

  describe '#new' do
    it 'should create a valid ssh key' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address

      s = SSHKey.new(type, blob, email)

      expect(s.to_s).to eq [type, blob, email].join(' ')
      expect(s.owner).to eq email
    end

    it 'should create a valid ssh key while specifying an owner' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name

      s = SSHKey.new(type, blob, email, owner)

      expect(s.to_s).to eq [type, blob, email].join(' ')
      expect(s.owner).to eq owner
    end

    it 'should create a valid ssh key while specifying an owner and location' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Name.location

      s = SSHKey.new(type, blob, email, owner, location)

      expect(s.to_s).to eq [type, blob, email].join(' ')
      expect(s.owner).to eq owner
      expect(s.location).to eq location
    end
  end

  describe '#hash' do
    it 'should have two hash equalling one another' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Name.location

      hash_test = [owner, location, type, blob, email].hash
      s = SSHKey.new(type, blob, email, owner, location)

      expect(s.hash).to eq hash_test
    end
  end

  describe '#filename' do
    it 'should create a filename that is the <email>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address

      s = SSHKey.new(type, blob, email)

      expect(s.filename).to eq "#{email}.pub"
    end

    it 'should create a filename that is the <owner>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name

      s = SSHKey.new(type, blob, email, owner)

      expect(s.filename).to eq "#{owner}.pub"
    end

    it 'should create a filename that is the <email>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)

      s = SSHKey.new(type, blob, email, nil, location)

      expect(s.filename).to eq "#{email}.pub"
      expect(s.relative_path).to eq File.join(email, location, "#{email}.pub")
    end

    it 'should create a filename that is the <owner>@<location>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)

      s = SSHKey.new(type, blob, email, owner, location)

      expect(s.filename).to eq "#{owner}.pub"
    end
  end

  describe '#to_file' do
    it 'should write a "valid" SSH public key to the file system' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)

      s = SSHKey.new(type, blob, email, owner, location)

      ## write file
      s.to_file(output_dir)

      ## compare raw string with written file
      expect(s.to_s).to eq File.read(File.join(output_dir, owner, location, s.filename))
    end

    it 'should return the filename written' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)

      s = SSHKey.new(type, blob, email, owner, location)
      expect(s.to_file(output_dir)).to eq File.join(output_dir, owner, location, s.filename)
    end
  end

  describe '==' do
    it 'should have two keys equalling one another' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address

      s1 = SSHKey.new(type, blob, email)
      s2 = SSHKey.new(type, blob, email)

      expect(s1).to eq s2
    end
  end
end
