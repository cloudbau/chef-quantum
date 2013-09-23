## Cookbook Name:: quantum
## Recipe:: nvp-plugin
##
## Copyright 2013, cloudbau GmbH
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
include_recipe "quantum::quantum-common"

mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
api_endpoint = get_bind_endpoint("quantum", "api")
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

template "/etc/quantum/plugins/nicira/nvp.ini" do
    source "nvp.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :sql_connection => "mysql://#{quantum["db"]["username"]}:#{quantum["db"]["password"]}@#{mysql_info["host"]}/#{quantum["db"]["name"]}",
      :nvp_controllers => node[:nvp][:nvp_controllers],
      :nvp_cluster_uuid => node[:nvp][:nvp_cluster_uuid],
      :default_tz_uuid => node[:nvp][:default_tz_uuid],
      :default_l3_gateway_service_uuid => node[:nvp][:default_l3_gateway_service_uuid],
      :default_l2_gateway_service_uuid => node[:nvp][:default_l3_gateway_service_uuid],
      :default_iface_name => node[:nvp][:default_iface_name]
    )
    # notifies :restart, resources(:service => "openvswitch-switch"), :immediately
end
