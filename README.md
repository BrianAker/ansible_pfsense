ansible-pfsense
==============

This is just the basics around setting up pfsense with Ansible.

The Makefile is just a wrapper around common ansible commands.

Inventory is broken up into the follow groups:

[pfsense:children]
firewall_appliance
dhcp_appliance
