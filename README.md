This repo provides some Vagrant/Puppet manifests that automatically install and
configure a test environment for the EPICS Channel Access Gateway. The
environment consists of the following virtual machines:

| Virtual Machine | Description                                 |
|-----------------|---------------------------------------------|
| testioc         | IOC providing some PVs                      |
| gateway         | machine with two NICs running the gateway   |
| client          | machine that comes with catools for testing |

Username and password for all machines is "vagrant", "vagrant".

# Software requirements

* Virtual Box
* Vagrant
* Git
* Puppet
* librarian-puppet

# Getting started
Run the following commands to bring up the virtual machines:
```
librarian-puppet install
vagrant up
```
As soon as the VMs are running you can go ahead and start the testioc:
```
vagrant ssh testioc
(testioc)$ sudo service softioc-phase1 start
```
Then you can connect to one of the test PVs from the client, e.g.
```
vagrant ssh client
camonitor double-counter-1Hz
```

## Note for Windows users
Run
```
git config --global core.autocrlf false
```
before checking out the Git repositories. Otherwise Git will convert Unix
line breaks (LF) to CR+LF. This will break init scripts etc.!

# Contact
Author: Martin Konrad \<konrad at frib.msu.edu\>