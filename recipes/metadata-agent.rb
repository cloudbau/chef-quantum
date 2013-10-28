#
## Cookbook Name:: quantum
## Recipe:: dhcp agent
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

include_recipe "osops-utils"
include_recipe "quantum::quantum-common"

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
if node["quantum"]["metadata_shared_secret"].nil?
    node.normal["quantum"]["metadata_shared_secret"] = secure_password
end

if not node["package_component"].nil?
    release = node["package_component"]
else
    release = "folsom"
end

platform_options = node["quantum"]["platform"][release]
plugin = node["quantum"]["plugin"]

service "neutron-metadata-agent" do
    service_name platform_options["quantum_metadata_agent"]
    provider Chef::Provider::Service::Upstart if platform?("ubuntu")
    supports :status => true, :restart => true
    action [ :enable, :start ]
end

quantum = get_settings_by_role("quantum-server", "quantum")

ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
template "/etc/neutron/metadata_agent.ini" do
    source "#{release}/metadata_agent.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      "service_pass" => quantum["service_pass"],
      "service_user" => quantum["service_user"],
      "service_tenant_name" => quantum["service_tenant_name"],
      "keystone_protocol" => ks_admin_endpoint["scheme"],
      "keystone_api_ipaddress" => ks_admin_endpoint["host"],
      "keystone_admin_port" => ks_admin_endpoint["port"],
      "keystone_path" => ks_admin_endpoint["path"],
      "quantum_debug" => node["quantum"]["debug"],
      "quantum_verbose" => node["quantum"]["verbose"],
      "quantum_plugin" => node["quantum"]["plugin"],
      "metadata_shared_secret" => node["quantum"]["metadata_shared_secret"]
    )
    notifies :restart, resources(:service => "neutron-metadata-agent"), :immediately
    notifies :enable, resources(:service => "neutron-metadata-agent"), :immediately
end
