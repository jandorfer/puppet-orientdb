# Class: orientdb
#
# This module manages OrientDB, downloading it, setting it up and running as a service.
#
# Parameters:
#
# Actions: 
#
# Requires: 
#   puppetlabs/stdlib
#   nanliu/staging
class orientdb {

  $user = "orientdb"
  $group = $user

  $version = "orientdb-graphed-1.5.1"
  $package = "${version}.zip"
  $source = "https://s3.amazonaws.com/orientdb/releases/${package}"

  $install_root = "/opt/orientdb"
  $install_version = "${install_root}/${version}"
  $install_dir = "${install_root}/default"

  user { $user:
    ensure      => present,
    gid         => $group
  }

  group { $group:
    ensure      => present
  }

  file { $install_root:
    ensure      => "directory",
    owner       => $user,
    group       => $group
  }

  staging::deploy { $package:
    source      => $source,
    target      => $install_root,
    user        => $user,
    group       => $group,
    require     => File[$install_root]
  }
  ->
  exec { "chmod_install_dir":
    command     => "/bin/chmod 755 ${install_version}/bin/*.sh"
  }

  file { $install_dir:
    ensure      => "link",
    target      => $install_version,
    owner       => $user,
    group       => $group,
    require     => Staging::Deploy[$package]
  }

  file { "${install_dir}/config/orientdb-server-config.xml":
    ensure      => "file",
    content     => template("orientdb/orientdb-server-config.xml.erb"),
    owner       => $user,
    group       => $group,
    mode        => 640,
    require     => File[$install_dir]
  }

  file { "${install_dir}/bin/orientdb.sh":
    ensure      => "file",
    content     => template("orientdb/orientdb.sh.erb"),
    owner       => $user,
    group       => $group,
    mode        => 755,
    require     => File[$install_dir]
  }

  file { "/etc/init.d/orientdb":
    ensure      => "link",
    target      => "${install_dir}/bin/orientdb.sh",
    require     => File["${install_dir}/bin/orientdb.sh"]
  }
  
  exec { "add_orientdb_service":
    command     => "/sbin/chkconfig --add orientdb",
    onlyif      => "/usr/bin/test `/sbin/chkconfig --list | /bin/grep orientdb | /usr/bin/wc -l` -eq 0",
    require     => File["/etc/init.d/orientdb"],
    before      => Service["orientdb"]
  }

  service { "orientdb":
    ensure      => running,
    enable      => true,
    hasrestart  => true,
    hasstatus   => true,
    subscribe   => File["${install_dir}/config/orientdb-server-config.xml"],
    require     => [
      File["${install_dir}/config/orientdb-server-config.xml"],
      File["/etc/init.d/orientdb"]
    ]
  }
}
