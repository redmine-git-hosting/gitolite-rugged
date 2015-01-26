require 'spec_helper'

describe Gitolite::SSHKey do

  key_dir    = File.join(File.dirname(__FILE__), 'fixtures', 'keys', 'bob')
  output_dir = '/tmp'

  describe "#from_string" do
    it 'should construct an SSH key from a string' do
      key = File.join(key_dir, 'bob.pub')
      key_string = File.read(key)
      s = SSHKey.from_string(key_string, "bob")

      s.owner.should == 'bob'
      s.location.should == ""
      s.blob.should == key_string.split[1]
    end

    it 'should raise an ArgumentError when an owner isnt specified' do
      key_string = "not_a_real_key"
      lambda { SSHKey.from_string(key_string) }.should raise_error
    end

    it 'should have a location when one is specified' do
      key = File.join(key_dir, 'bob.pub')
      key_string = File.read(key)
      s = SSHKey.from_string(key_string, "bob", "kansas")

      s.owner.should == 'bob'
      s.location.should == "kansas"
      s.blob.should == key_string.split[1]
    end

    it 'should raise an ArgumentError when owner is nil' do
      lambda { SSHKey.from_string("bad_string", nil) }.should raise_error
    end

    it 'should raise an ArgumentError when we get an invalid SSHKey string' do
      lambda { SSHKey.from_string("bad_string", "bob") }.should raise_error
    end
  end

  describe "#from_file" do
    it 'should load a key from a file' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      key_string = File.read(key).split

      s.owner.should == "bob"
      s.blob.should == key_string[1]
      s.location.should == ''
    end

    it 'should load a key from a file' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob'
      s.location.should == ''
    end

    it 'should load a key with an e-mail owner from a file' do
      key = File.join(key_dir, 'bob@example.com.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob@example.com'
      s.location.should == ''
    end

    it 'should load a key from a file within location' do
      key = File.join(key_dir, 'desktop', 'bob.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob'
      s.location.should == 'desktop'
    end

    it 'should load a key from a file within location' do
      key = File.join(key_dir, 'school', 'bob.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob'
      s.location.should == 'school'
    end
  end

  describe '#keys' do
    it 'should load ssh key properly' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      parts = File.read(key).split #should get type, blob, email

      s.type.should == parts[0]
      s.blob.should == parts[1]
      s.email.should == parts[2]
    end
  end

  describe '#new' do
    it 'should create a valid ssh key' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address

      s = SSHKey.new(type, blob, email)

      s.to_s.should == [type, blob, email].join(' ')
      s.owner.should == email
    end

    it 'should create a valid ssh key while specifying an owner' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name

      s = SSHKey.new(type, blob, email, owner)

      s.to_s.should == [type, blob, email].join(' ')
      s.owner.should == owner
    end

    it 'should create a valid ssh key while specifying an owner and location' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Name.location

      s = SSHKey.new(type, blob, email, owner, location)

      s.to_s.should == [type, blob, email].join(' ')
      s.owner.should == owner
      s.location.should == location
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

      s.hash.should == hash_test
    end
  end

  describe '#filename' do
    it 'should create a filename that is the <email>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address

      s = SSHKey.new(type, blob, email)

      s.filename.should == "#{email}.pub"
    end

    it 'should create a filename that is the <owner>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name

      s = SSHKey.new(type, blob, email, owner)

      s.filename.should == "#{owner}.pub"
    end

    it 'should create a filename that is the <email>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)

      s = SSHKey.new(type, blob, email, nil, location)

      s.filename.should == "#{email}.pub"
      s.relative_path.should == File.join(email, location, "#{email}.pub")
    end

    it 'should create a filename that is the <owner>@<location>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)

      s = SSHKey.new(type, blob, email, owner, location)

      s.filename.should == "#{owner}.pub"
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
      s.to_s.should == File.read(File.join(output_dir, owner, location, s.filename))
    end

    it 'should return the filename written' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)

      s = SSHKey.new(type, blob, email, owner, location)
      s.to_file(output_dir).should == File.join(output_dir, owner, location, s.filename)
    end
  end

  describe '==' do
    it 'should have two keys equalling one another' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address

      s1 = SSHKey.new(type, blob, email)
      s2 = SSHKey.new(type, blob, email)

      s1.should == s2
    end
  end
end
