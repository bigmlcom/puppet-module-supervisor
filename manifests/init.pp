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
  
  define supervisor::service(
    $enable=true, $ensure=running,
    $subscribes=[],
    $command, $numprocs=1, $priority=999,
    $autorestart="unexpected",
    $startsecs=1, $retries=3, $exitcodes="0,2",
    $stopsignal="TERM", $stopwait=10, $user="",
    $group="", $redirect_stderr=false,
    $stdout_logfile="",
    $stdout_logfile_maxsize="250MB", $stdout_logfile_keep=10,
    $stderr_logfile="",
    $stderr_logfile_maxsize="250MB", $stderr_logfile_keep=10,
    $environment="", $chdir="", $umask="") {
      $autostart = $ensure ? {
        running => true,
        stopped => false,
        default => false
      }

      file {
        "${supervisor_conf_dir}/${name}.ini":
          content => $enable ? {
            true => template("supervisor/service.ini.erb"),
            default => undef },
          ensure => $enable ? {
            false => absent,
            default => undef },
          require => File[$supervisor_conf_dir, "${supervisor_log_dir}/${name}"],
          notify => Exec["supervisor::update"];
        "${supervisor_log_dir}/${name}":
          owner => $user ? {
            "" => "root",
            default => $user },
          group => $group ? {
            "" => "root",
            default => $group },
          mode => 750,
          ensure => $ensure ? {
            purged => absent,
            default => directory },
          recurse => $ensure ? {
            purged => true,
            default => false },
          force => $ensure ? {
            purged => true,
            default => false };
      }

      if $ensure != "purged" {
        service {
          "supervisor::${name}":
            ensure => $ensure,
            provider => base,
            restart => "/usr/bin/supervisorctl restart ${name}",
            start => "/usr/bin/supervisorctl start ${name}",
            status => "/usr/bin/supervisorctl status | awk '/^${name}/{print \$2}' | grep '^RUNNING$'",
            stop => "/usr/bin/supervisorctl stop ${name}",
            require => [ Package["supervisor"], Service["supervisor"] ],
        }
      }
    }
  
}
