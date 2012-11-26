#
## Cookbook Name:: quantum
## Recipe:: server
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
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "mysql::client"
include_recipe "mysql::ruby"
include_recipe "osops-utils"

if not node["package_component"].nil?
    release = node["package_component"]
else
    release = "folsom"
end

platform_options = node["quantum"]["platform"][release]

if node["developer_mode"]
    node.set_unless["quantum"]["db"]["password"] = "quantum"
else
    node.set_unless["quantum"]["db"]["password"] = secure_password
end

node.set_unless['quantum']['service_pass'] = secure_password

package "quantum-server" do
    action :install
end

ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone", "keystone", "service-api")
keystone = get_settings_by_role("keystone", "keystone")

# Create db and user
# return connection info
# defined in osops-utils/libraries
mysql_info = create_db_and_user("mysql", 
				node["quantum"]["db"]["name"],
				node["quantum"]["db"]["username"],
				node["quantum"]["db"]["password"])

platform_options["mysql_python_packages"].each do |pkg|
    package pkg do
        action :install
    end
end

platform_options["quantum_packages"].each do |pkg|
    package pkg do
        action :upgrade
	options platform_options["package_overrides"]
    end
end

service "quantum-server" do
    service_name platform_options["quantum_api_server"]
    supports :status => true, :restart => true
    action :nothing
end

keystone_register "Register Service Tenant" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token keystone["admin_token"]
    tenant_name node["quantum"]["service_tenant_name"]
    tenant_description "Service Tenant"
    tenant_enabled "true"
    action :create_tenant
end

keystone_register "Register Service User" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token keystone["admin_token"]
    tenant_name node["quantum"]["service_tenant_name"]
    user_name node["quantum"]["service_user"]
    user_pass node["quantum"]["service_pass"]
    user_enabled "true"
    action :create_user
end

keystone_register "Grant 'admin' role to service user for service tenant" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token keystone["admin_token"] 
    tenant_name node["quantum"]["service_tenant_name"]
    user_name node["quantum"]["service_user"]
    role_name node["qunatum"]["service_role"]
    action :grant_role
end

