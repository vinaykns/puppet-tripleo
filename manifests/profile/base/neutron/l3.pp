# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::neutron::l3
#
# Neutron L3 Agent server profile for tripleo
#
# === Parameters
#
# [*neutron_ovs_use_veth*]
#   (Optional) Whether to set ovs_use_veth (for older kernel support)
#   Defaults to hiera('neutron_ovs_use_veth', false)
#
# [*enabled*]
#   (Optional) Whether to enable the Neutron L3 Agent service
#   Defaults to undef
#
# [*manage_service*]
#   (Optional) Whether to manage the Neutron L3 Agent service
#   Defaults to undef
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::l3 (
  $enabled        = undef,
  $manage_service = undef,
  $step           = hiera('step'),
) {
  if $step >= 4 {
    include ::tripleo::profile::base::neutron
    class { '::neutron::agents::l3':
      manage_service => $manage_service,
      enabled        => $enabled
    }

    Service<| title == 'neutron-server' |> -> Service <| title == 'neutron-l3' |>
  }
}