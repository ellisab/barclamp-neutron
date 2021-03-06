# Copyright 2014 SUSE
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

haproxy_loadbalancer "neutron-server" do
  address node[:neutron][:api][:service_host]
  port node[:neutron][:api][:service_port]
  use_ssl (node[:neutron][:api][:protocol] == "https")
  servers CrowbarPacemakerHelper.haproxy_servers_for_service(node, "neutron", "neutron-server", "server")
  action :nothing
end.run_action(:create)

# Wait for all "neutron-server" nodes to reach this point so we know that they
# will have all the required packages installed and configuration files updated
# before we create the pacemaker resources.
crowbar_pacemaker_sync_mark "sync-neutron_before_ha"

# Avoid races when creating pacemaker resources
crowbar_pacemaker_sync_mark "wait-neutron_ha_resources"

primitive_name = "neutron-server"

pacemaker_primitive primitive_name do
  agent node[:neutron][:ha][:server][:server_ra]
  op node[:neutron][:ha][:server][:op]
  action :create
end

pacemaker_clone "cl-#{primitive_name}" do
  rsc primitive_name
  action [:create, :start]
end

crowbar_pacemaker_sync_mark "create-neutron_ha_resources"
