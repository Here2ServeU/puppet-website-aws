# site.pp manifest

node default {
  # Ensure Nginx is installed and running
  case $facts['os']['family'] {
    'Debian': {
      package { 'nginx':
        ensure => installed,
      }

      service { 'nginx':
        ensure    => running,
        enable    => true,
        subscribe => Package['nginx'],
      }
    }

    'RedHat': {
      package { 'nginx':
        ensure => installed,
        name   => 'nginx', # Adjust this if Amazon Linux uses a different package name
      }

      service { 'nginx':
        ensure    => running,
        enable    => true,
        subscribe => Package['nginx'],
      }
    }

    default: {
      notify { "Unsupported OS family: ${facts['os']['family']}":
        message => "Nginx installation is not supported on this OS family.",
      }
    }
  }

  # Ensure the index.html file is copied to the Nginx document root
  file { '/var/www/html/index.html':
    ensure  => file,
    source  => 'puppet:///modules/webapp/index.html',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
}

