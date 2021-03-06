#
## Cookbook Name:: quantum
## Attributes:: default
##
## Copyright 2012, Rackspace US, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##

########################################################################
# Toggles - These can be overridden at the environment level
default["developer_mode"] = false  # cluster_attribute  # we want secure passwords by default
#########################################################################

default["quantum"]["services"]["api"]["scheme"] = "http"
default["quantum"]["services"]["api"]["network"] = "public"
default["quantum"]["services"]["api"]["port"] = 9696
default["quantum"]["services"]["api"]["path"] = ""

default["quantum"]["db"]["name"] = "quantum"
default["quantum"]["db"]["username"] = "quantum"

default["quantum"]["service_tenant_name"] = "service"
default["quantum"]["service_user"] = "quantum"
default["quantum"]["service_role"] = "admin"

#logging stuff
default["quantum"]["syslog"]["use"] = true
default["quantum"]["syslog"]["facility"] = "LOG_LOCAL3"
default["quantum"]["syslog"]["config_facility"] = "local3"
default["quantum"]["debug"] = "False"
default["quantum"]["verbose"] = "False"

default["quantum"]["logging.conf"]["use"] = false
default["quantum"]["logging.conf"]["formatter"] = "quantum.openstack.common.log.LegacyFormatter"
default["quantum"]["logging.conf"]["logfile"] = "/var/log/quantum/quantum.log"

# Attention: the following parameter MUST be set to False if Quantum is
# # being used in conjunction with nova security groups and/or metadata service.
default["quantum"]["overlap_ips"] = "False"
default["quantum"]["use_namespaces"] = "False" # should correspond to overlap_ips used for dhcp agent and l3 agent.

# Manage plugins here, currently only supports openvswitch (ovs)
default["quantum"]["plugin"] = "ovs"

# Plugin defaults
# OVS
default["quantum"]["ovs"]["packages"] = [ "quantum-plugin-openvswitch", "quantum-plugin-openvswitch-agent" ]
default["quantum"]["ovs"]["service_name"] = "quantum-plugin-openvswitch-agent"
default["quantum"]["ovs"]["network_type"] = "gre"
default["quantum"]["ovs"]["tunneling"] = "True" 		# Must be true if network type is GRE
default["quantum"]["ovs"]["tunnel_ranges"] = "1:1000"		# Enumerating ranges of GRE tunnel IDs that are available for tenant network allocation (if GRE)
default["quantum"]["ovs"]["integration_bridge"] = "br-int"	# Don't change without a good reason..
default["quantum"]["ovs"]["tunnel_bridge"] = "br-tun"		# only used if tunnel_ranges is set
default["quantum"]["ovs"]["external_bridge"] = "br-ex"
default["quantum"]["ovs"]["external_interface"] = "eth1"


case platform
when "fedora", "redhat", "centos"
    default["quantum"]["platform"]["folsom"] = {
	    "mysql_python_packages" => [ "MySQL-python" ],
	    "quantum_packages" => [ "openstack-quantum", "python-quantumclient" ],
	    "quantum_api_service" => "openstack-quantum",
	    "quantum_api_process_name" => "",
	    "package_overrides" => ""
    }
when "ubuntu"
    default["quantum"]["platform"]["folsom"] = {
	    "mysql_python_packages" => [ "python-mysqldb" ],
	    "quantum_packages" => [ "quantum-server", "python-quantum", "quantum-common" ],
	    "quantum_dhcp_packages" => [ "dnsmasq-base", "dnsmasq-utils", "libnetfilter-conntrack3", "quantum-dhcp-agent" ],
	    "quantum_l3_packages" => ["quantum-l3-agent"],
	    "quantum_api_service" => "quantum-server",
	    "quantum_dhcp_agent" => "quantum-dhcp-agent",
	    "quantum_l3_agent" => "quantum-l3-agent",
	    "quantum_api_process_name" => "quantum-server",
	    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
    }
end



default["quantum"]["ovs"]["use_provider_networks"] = false
# e.g.
# { "provider_network_1" => { "bridge" => "br-ex", 
#                             "port" => "eth0",
#                             "vlan_start" => 200,
#                             "vlan_end" => 399
#                           }
# }
default["quantum"]["ovs"]["provider_network_bridge_mappings"] = { }
