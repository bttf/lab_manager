Lab Manager
===========
The VM Ware product Lab Manager managers virtual machines. This simple
client allows access to the confguration data via the Lab Manager SOAP
interface.

Requirements
------------
* Ruby >= 1.8.7
* Bundler

Installation
------------
To use the gem just install it.
```
gem install lab-manager
```
To make changes just fork it, install the dependencies and test.
```
git clone https://github.com/IndependentPurchasingCooperative/lab_manager.git
cd lab_manager
gem install bundler
bundle install
rspec spec/lab_manager_spec.rb
```

Usage
-----
Find out the names of machines in a configuration

Configure the Lab Manager server one of these ways:

```
LabManager.url = "https://YOUR_DOMAIN/LabManager/SOAP/LabManager.asmx"
```

With the constructor:
```
LabManager.new(organization, username, password, "https://YOUR_DOMAIN/LabManager/SOAP/LabManager.asmx")
```

Create a configuration file:
```
echo 'url: "https://YOUR_DOMAIN/LabManager/SOAP/LabManager.asmx"' > ~/.lab_manager
```

Retrieve a list of machines from a configuration:
```
lab = LabManager.new(organization, username, password)
machines = lab.machines(configuration, :exclude => ["machine1", "machine2"])
puts "#{machines[0].name} #{machines[0].externalIp}"
```

If your environment has multiple workspaces then you will have to select
which one you are interacting with.

```
lab.workspace = "WORKSPACE NAME"
```

A convenience method to integrate with a bash script converts this information
intl a csv format.

```
Machine.to_csv(machines)
```

Release Notes
=============
* 1.0.3 - Revert back the monkey patch since the property setting didn't work.
* 1.0.2 - Refactor out monkey patch  and replace it with simple property assignment.
* 1.0.1 - Add ability to configure server url in file.
* 1.0.0 - Initial release

