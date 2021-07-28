class { 'apache': }
->
file {'/var/www/html/index.html':
  ensure  => present,
  content => "Hello World!",
  owner => "www-data",
  group => "www-data",
  mode => "644"
}