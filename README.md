## gitolite-rugged
[![Gem Version](https://badge.fury.io/rb/gitolite-rugged.svg)](http://badge.fury.io/rb/gitolite-rugged)
[![Build Status](https://travis-ci.org/oliverguenther/gitolite-rugged.svg?branch=devel)](https://travis-ci.org/oliverguenther/gitolite-rugged)
[![Code Climate](https://codeclimate.com/github/oliverguenther/gitolite-rugged.png)](https://codeclimate.com/github/oliverguenther/gitolite-rugged)

### This gem is a fork from the [jbox-gitolite](https://github.com/jbox-web/gitolite) gem employing [libgit2/rugged](https://github.com/libgit2/rugged).


This gem is designed to provide a Ruby interface to the [Gitolite](https://github.com/sitaramc/gitolite) Git backend system.

It provides these functionalities :

* SSH Public Keys Management
* Repositories Management
* Gitolite Admin Repository Bootstrapping

## Requirements ##
* Ruby 1.9.x or 2.0.x
* a working [gitolite](https://github.com/sitaramc/gitolite) installation
* The [rugged](https://github.com/libgit2/rugged) bindings to libgit2 with SSH-key credentials added (Version >= 0.21 or dev branch).

## Installation ##

    gem install gitolite-rugged


## Usage ##

### Bootstrapping the gitolite-admin.git repository ###

You can have `gitolite-rugged` clone the repository for you on demand, however I would recommend cloning it manually.
See it as a basic check that your gitolite installation was correctly set up.

In both cases, use the following code to create an instance of the manager:

	settings = { :public_key => '~/.ssh/id_rsa.pub', :private_key => '~/.ssh/id_rsa' }
	admin = Gitolite::GitoliteAdmin.new('/home/myuser/gitolite-admin', settings)
		
For cloning and pushing to the gitolite-admin.git, you have to provide several options to `GitoliteAdmin` in the settings hash. The following keys are used.

* **:git_user** The git user to SSH to (:git_user@localhost:gitolite-admin.git), defaults to 'git'
* **:host** Hostname for clone url. Defaults to 'localhost'
* **:private_key** The key file containing the private SSH key for :git_user
* **:public_key** The key file containing the public SSH key for :git_user
* **:author_name:** The git author name to commit with (default: 'gitolite-rugged gem')
* **:author_email** The git author e-mail address to commit with (default: 'gitolite-rugged@localhost')
* **:commit_msg** The commit message to use when updating the repo (default: 'Commited by the gitolite-rugged gem')

### Managing Public Keys ###

To add a key, create a `SSHKey` object and use the `add_key(key)` method of GitoliteAdmin.

	# From filesystem
	key_from_file = SSHKey.from_file("/home/alice/.ssh/id_rsa.pub")
	
	# From String, which requires us to add an owner manually
	key_from_string = SSHKey.from_string('ssh-rsa AAAAB3N/* .... */JjZ5SgfIKab bob@localhost', 'bob')
	
	admin.add_key(key_from_string)
	admin.add_key(key_from_file)
	
Note that you can add a *location* using the syntax described in [the Gitolite documentation](http://gitolite.com/gitolite/users.html#old-style-multi-keys).
	

To write out the changes to the keys to the filesystem and push them to gitolite, call `admin.save_and_apply`.
You can also manually call `admin.save` to commit the changes locally, but not push them.


### Managing Repositories ###

To add a new repository, we first create and configure it, and then add it to the memory representation of gitolite:

	repo = Gitolite::Config::Repo.new('foobar')
	repo.add_permission("RW+", "alice", "bob")
	
	# Add the repo
	admin.config.add_repo(repo)
	
To remove a repository called 'foobar', execute `config.rm_repo('foobar')`.


### Groups ###

As in the [Gitolite Config](http://gitolite.com/gitolite/groups.html) you can define groups as an alias to repos or users.

	# Creating a group
	devs = Gitolite::Config::Group.new('developers')
	devs.add_users("alice", "bob")
	
	# Adding a group to config
	admin.config.add_group(devs)



## Copyrights & License
gitolite-rugged is completely free and open source and released under the [MIT License](https://github.com/oliverguenther/gitolite/blob/devel/LICENSE.txt).

Copyright (c) 2014 Oliver Günther (mail@oliverguenther.de)

Based on the jbox-gitolite fork by Nicolas Rodriguez, which itself is based on the original gitolite gem by Stafford Brunk.

Copyright (c) 2013-2014 Nicolas Rodriguez (nrodriguez@jbox-web.com), JBox Web (http://www.jbox-web.com)

Copyright (c) 2011-2013 Stafford Brunk (stafford.brunk@gmail.com)
