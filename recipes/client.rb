#
## Cookbook Name:: quantum
## Recipe:: client
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

# TODO: removeme completely?

include_recipe "osops-utils"

api_endpoint = get_bind_endpoint("quantum", "api")
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")

if not node["package_component"].nil?
    release = node["package_component"]
else
    release = "folsom"
end

mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
