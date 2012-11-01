Lab Manager
===========
The VM Ware product Lab Manager managers virtual machines. This simple
client allows access to the confguration data via the Lab Manager SOAP
interface.

Requirements
------------
Ruby >= 1.8.7

Installation
------------
>  gem install lab_manager

Usage
-----
Find out the names of machines in a configuratoin

```
lab = LabManager.new(organization, username, password)
machines = lab.machines(configuration, :exclude => excludeMachines)
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

