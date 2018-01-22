# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::certmonger::opendaylight
#
# Request a certificate for the opendaylight service and do the necessary setup.
#
# === Parameters
#
# [*hostname*]
#   The hostname of the node. this will be set in the CN of the certificate.
#
# [*service_certificate*]
#   The path to the certificate that will be used for TLS in this service.
#
# [*service_key*]
#   The path to the key that will be used for TLS in this service.
#
# [*certmonger_ca*]
#   (Optional) The CA that certmonger will use to generate the certificates.
#   Defaults to hiera('certmonger_ca', 'local').
#
# [*postsave_cmd*]
#   (Optional) Specifies the command to execute after requesting a certificate.
#   Defaults to 'if systemctl -q is-active opendaylight; then systemctl restart opendaylight; else true; fi'
#
# [*principal*]
#   (Optional) The haproxy service principal that is set for opendaylight in kerberos.
#   Defaults to undef
#
class tripleo::certmonger::opendaylight (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $postsave_cmd  = 'if systemctl -q is-active opendaylight; then systemctl restart opendaylight; else true; fi',
  $principal     = undef,
) {
  include ::certmonger

  certmonger_certificate { 'opendaylight' :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd,
    ca           => $certmonger_ca,
    wait         => true,
    require      => Class['::certmonger'],
  }
  file { $service_certificate :
    owner   => 'odl',
    group   => 'odl',
    require => Certmonger_certificate['opendaylight']
  }
  file { $service_key :
    owner   => 'odl',
    group   => 'odl',
    require => Certmonger_certificate['opendaylight']
  }

  File[$service_certificate] -> Odl_keystore<| title == 'controller' |>
  File[$service_key] -> Odl_keystore<| title == 'controller' |>
}
