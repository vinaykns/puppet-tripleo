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
# == Class: tripleo::profile::base::nova::compute::libvirt
#
# Nova Compute Libvirt profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::nova::compute::libvirt (
  $step = hiera('step'),
) {

  if $step >= 4 {
    include ::tripleo::profile::base::nova::compute

    file { ['/etc/libvirt/qemu/networks/autostart/default.xml',
      '/etc/libvirt/qemu/networks/default.xml']:
      ensure => absent,
      before => Service['libvirt'],
    }

    # in case libvirt has been already running before the Puppet run, make
    # sure the default network is destroyed
    exec { 'libvirt-default-net-destroy':
      command => '/usr/bin/virsh net-destroy default',
      onlyif  => '/usr/bin/virsh net-info default | /bin/grep -i "^active:\s*yes"',
      before  => Service['libvirt'],
    }

    # Ceph + Libvirt
    $rbd_ephemeral_storage = hiera('nova::compute::rbd::ephemeral_storage', false)
    $rbd_persistent_storage = hiera('rbd_persistent_storage', false)
    if $rbd_ephemeral_storage or $rbd_persistent_storage {
      $client_keys = hiera('ceph::profile::params::client_keys')
      $client_user = join(['client.', hiera('tripleo::profile::base::cinder::volume::rbd::cinder_rbd_user_name')])
      class { '::nova::compute::rbd':
        libvirt_rbd_secret_key => $client_keys[$client_user]['secret'],
      }
    }

    # TODO(emilien): Some work needs to be done in puppet-nova to separate nova-compute config
    # when running libvirt and libvirt itself, so we allow micro-services deployments.
    if str2bool(hiera('nova::use_ipv6', false)) {
      $vncserver_listen = '::0'
    } else {
      $vncserver_listen = '0.0.0.0'
    }

    if $rbd_ephemeral_storage {
      class { '::nova::compute::libvirt':
        libvirt_disk_cachemodes => ['network=writeback'],
        libvirt_hw_disk_discard => 'unmap',
        vncserver_listen        => $vncserver_listen,
      }
    } else {
      class { '::nova::compute::libvirt' :
        vncserver_listen => $vncserver_listen,
      }
    }

  }

}