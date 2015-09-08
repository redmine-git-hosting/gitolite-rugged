## gitolite-rugged

[![GitHub license](https://img.shields.io/github/license/jbox-web/gitolite-rugged.svg)](https://github.com/jbox-web/gitolite-rugged/blob/devel/LICENSE)
[![GitHub release](https://img.shields.io/github/release/jbox-web/gitolite-rugged.svg)](https://github.com/jbox-web/gitolite-rugged/releases/latest)
[![Build Status](https://travis-ci.org/jbox-web/gitolite-rugged.svg?branch=devel)](https://travis-ci.org/jbox-web/gitolite-rugged)
[![Code Climate](https://codeclimate.com/github/jbox-web/gitolite-rugged/badges/gpa.svg)](https://codeclimate.com/github/jbox-web/gitolite-rugged)
[![Dependency Status](https://gemnasium.com/jbox-web/gitolite-rugged.svg)](https://gemnasium.com/jbox-web/gitolite-rugged)

### This gem is a fork from the [jbox-gitolite](https://github.com/jbox-web/gitolite) gem employing [libgit2/rugged](https://github.com/libgit2/rugged).

This gem is designed to provide a Ruby interface to the [Gitolite](https://github.com/sitaramc/gitolite) Git backend system.

It provides these functionalities :

* SSH Public Keys Management
* Repositories Management
* Gitolite Admin Repository Bootstrapping

## Requirements
* Ruby 2.x
* a working [Gitolite](https://github.com/sitaramc/gitolite) installation

## Installation

Install dependencies :

    # On Debian/Ubuntu
    root# apt-get install build-essential libssh2-1 libssh2-1-dev cmake libgpg-error-dev

    # On Fedora/CentoS/RedHat
    root# yum groupinstall "Development Tools"
    root# yum install libssh2 libssh2-devel cmake libgpg-error-devel

Then put this in your ```Gemfile``` :

    gem 'gitolite-rugged', git: 'https://github.com/jbox-web/gitolite-rugged.git', tag: '1.2.0'

then

    bundle install


## Usage

### Bootstrapping the gitolite-admin.git repository

You can have `gitolite-rugged` clone the repository for you on demand, however I would recommend cloning it manually.
See it as a basic check that your gitolite installation was correctly set up.

In both cases, use the following code to create an instance of the manager:

    settings = { :public_key => '~/.ssh/id_rsa.pub', :private_key => '~/.ssh/id_rsa' }
    admin = Gitolite::GitoliteAdmin.new('/home/myuser/gitolite-admin', settings)

For cloning and pushing to the gitolite-admin.git, you have to provide several options to `GitoliteAdmin` in the settings hash. The following keys are used.

* **:git_user** The git user to SSH to (:git_user@localhost:gitolite-admin.git), defaults to 'git'
* **:hostname** Hostname for clone url. Defaults to 'localhost'
* **:private_key** The key file containing the private SSH key for :git_user
* **:public_key** The key file containing the public SSH key for :git_user
* **:author_name:** The git author name to commit with (default: 'gitolite-rugged gem')
* **:author_email** The git author e-mail address to commit with (default: 'gitolite-rugged@localhost')
* **:commit_msg** The commit message to use when updating the repo (default: 'Commited by the gitolite-rugged gem')

### Managing Public Keys

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


### Managing Repositories

To add a new repository, we first create and configure it, and then add it to the memory representation of gitolite:

    repo = Gitolite::Config::Repo.new('foobar')
    repo.add_permission("RW+", "alice", "bob")

    # Add the repo
    admin.config.add_repo(repo)

To remove a repository called 'foobar', execute `config.rm_repo('foobar')`.


### Groups

As in the [Gitolite Config](http://gitolite.com/gitolite/groups.html) you can define groups as an alias to repos or users.

    # Creating a group
    devs = Gitolite::Config::Group.new('developers')
    devs.add_users("alice", "bob")

    # Adding a group to config
    admin.config.add_group(devs)


## Contribute

You can contribute to this plugin in many ways such as :
* Helping with documentation
* Contributing code (features or bugfixes)
* Reporting a bug
* Submitting translations

You can also donate :)
