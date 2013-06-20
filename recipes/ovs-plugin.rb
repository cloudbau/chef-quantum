## Cookbook Name:: quantum
## Recipe:: ovs-plugin
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
include_recipe "osops-utils"

if not node["package_component"].nil?
	    release = node["package_component"]
else
	    release = "folsom"
end

platform_options = node["quantum"]["platform"][release]
plugin = node["quantum"]["plugin"]

node["quantum"][plugin]["packages"].each do |pkg| 
    package pkg do
        action :upgrade
        options platform_options["package_overrides"]
    end
end

bash "installing linux headers to compile openvswitch module" do
  code <<-EOH
    apt-get install -y linux-headers-`uname -r`
  EOH
end

service "quantum-plugin-openvswitch-agent" do
    service_name node["quantum"]["ovs"]["service_name"]
    provider Chef::Provider::Service::Upstart
    supports :status => true, :restart => true
    action :nothing
end

service "openvswitch-switch" do
    service_name "openvswitch-switch"
    supports :status => true, :restart => true
    action :nothing
end

mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
api_endpoint = get_bind_endpoint("quantum", "api")
local_ip = get_ip_for_net('nova', node)		### FIXME
quantum = get_settings_by_role("quantum-server", "quantum")

template "/etc/quantum/api-paste.ini" do
    source "#{release}/api-paste.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        "keystone_api_ipaddress" => ks_admin_endpoint["host"],
        "keystone_admin_port" => ks_admin_endpoint["port"],
        "keystone_protocol" => ks_admin_endpoint["scheme"],
        "service_tenant_name" => node["quantum"]["service_tenant_name"],
        "service_user" => node["quantum"]["service_user"],
        "service_pass" => node["quantum"]["service_pass"]
    )
end

template "/etc/quantum/quantum.conf" do
    source "#{release}/quantum.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        "db_ip_address" => mysql_info["host"],
        "db_user" => quantum["db"]["username"],
        "db_password" => quantum["db"]["password"],
        "db_name" => quantum["db"]["name"],
        "quantum_debug" => node["quantum"]["debug"],
        "quantum_verbose" => node["quantum"]["verbose"],
        "quantum_ipaddress" => api_endpoint["host"],
        "quantum_port" => api_endpoint["port"],
        "rabbit_ipaddress" => rabbit_info["host"],
        "rabbit_port" => rabbit_info["port"],
        "overlapping_ips" => node["quantum"]["overlap_ips"],
        "quantum_plugin" => node["quantum"]["plugin"]
    )
end

template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
    source "#{release}/ovs_quantum_plugin.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      "db_ip_address" => mysql_info["host"],
      "db_user" => quantum["db"]["username"],
      "db_password" => quantum["db"]["password"],
      "db_name" => quantum["db"]["name"],
      "ovs_network_type" => node["quantum"]["ovs"]["network_type"],
      "ovs_enable_tunneling" => node["quantum"]["ovs"]["tunneling"],
      "ovs_tunnel_ranges" => node["quantum"]["ovs"]["tunnel_ranges"],
      "ovs_integration_bridge" => node["quantum"]["ovs"]["integration_bridge"],
      "ovs_tunnel_bridge" => node["quantum"]["ovs"]["tunnel_bridge"],
      "ovs_debug" => node["quantum"]["debug"],
      "ovs_verbose" => node["quantum"]["verbose"],
      "ovs_local_ip" => local_ip,
      "use_provider_networks" => node["quantum"]["ovs"]["use_provider_networks"],
      "provider_network_bridge_mappings" => node["quantum"]["ovs"]["provider_network_bridge_mappings"],
    )
    # notifies :restart, resources(:service => "quantum-server"), :immediately
    notifies :restart, resources(:service => "quantum-plugin-openvswitch-agent"), :immediately
    notifies :enable, resources(:service => "quantum-plugin-openvswitch-agent"), :immediately
    notifies :restart, resources(:service => "openvswitch-switch"), :immediately
end

execute "create integration bridge" do
    command "ovs-vsctl add-br #{node["quantum"]["ovs"]["integration_bridge"]}"
    action :run
    not_if "ovs-vsctl show | grep 'Bridge br-int'" ## FIXME
end

execute "create external bridge" do
    command "ovs-vsctl add-br #{node["quantum"]["ovs"]["external_bridge"]}"
    action :run
    not_if "ovs-vsctl show | grep 'Bridge br-ex'" ## FIXME
end

if node["quantum"]["ovs"]["use_provider_networks"]
  node["quantum"]["ovs"]["provider_network_bridge_mappings"].each do |network_name, network_info|
    execute "create provider network_bridge for #{network_name}" do
      bridge = network_info['bridge']
      command "ovs-vsctl add-br #{bridge}"
      action :run
      not_if "ovs-vsctl show | grep 'Bridge #{bridge}'" ## FIXME
    end
    
    execute "connecting provider port to bridge for #{network_name}" do
      bridge = network_info['bridge']
      port = = network_info['port']
      command "add-port #{bridge} #{port}"
      action :run
      not_if "ovs-vsctl show | grep 'Port \"#{port}'" ## FIXME
    end
  end
end