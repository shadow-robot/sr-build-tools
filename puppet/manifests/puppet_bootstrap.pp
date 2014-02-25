#
# Boot strap our puppet environment.
# Basically that means installing some modules from puppetforge.
#

Exec {
  path => [
    '/usr/local/bin',
    '/opt/local/bin',
    '/usr/bin',
    '/usr/sbin',
    '/bin',
    '/sbin',
    '/opt/vagrant_ruby/bin/'],
  logoutput => true,
}

# On the default modulepath for the root user
file { '/etc/puppet/modules':
  ensure => directory,
}

exec { 'puppet module install puppetlabs/apt':
  creates => '/etc/puppet/modules/apt/manifests/init.pp',
}

