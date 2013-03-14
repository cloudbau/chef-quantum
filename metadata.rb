maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description	  "Installs/Configures Openstack Quantum Service"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recipe		 "quantum::server", "Installs packages required for quantum-server"

%w{ ubuntu fedora }.each do |os|
	  supports os
end

%w{ database mysql osops-utils }.each do |dep|
	  depends dep
end
