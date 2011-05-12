$supervisor_conf_dir = "/etc/supervisor"
$supervisor_conf = "/etc/supervisor/supervisord.conf"
$supervisor_log_dir = "/var/log/supervisor"
$supervisor_run_dir = "/var/run/supervisor"

class supervisor {
  package {
    "supervisor":
      ensure => installed;
  }

  file {
    $supervisor_conf_dir:
      purge => true,
      ensure => directory,
      require => Package["supervisor"];
    [$supervisor_log_dir,
     $supervisor_run_dir]:
       purge => true,
       backup => false,
       ensure => directory,
       require => Package["supervisor"];
     $supervisor_conf:
       content => template("supervisor/supervisord.conf.erb"),
       require => Package["supervisor"];
     "/etc/logrotate.d/supervisor":
       content => template("supervisor/logrotate.erb"),
       require => Package["supervisor"];
  }

  service {
    "supervisor":
      enable => true,
      ensure => running,
      hasrestart => false,
      require => Package["supervisor"],
      pattern => "/usr/bin/supervisord";
  }

  exec {
    "supervisor::update":
      command => "/usr/bin/supervisorctl update",
      logoutput => on_failure,
      refreshonly => true,
      require => Service["supervisor"];
  }
}
