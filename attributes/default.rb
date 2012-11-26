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
default["developer_mode"] = true  # cluster_attribute  # we want secure passwords by default
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
	    "quantum_api_service" => "quantum",
	    "quantum_api_process_name" => "quantum-server",
	    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
    }
end
