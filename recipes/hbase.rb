require 'shellwords'

include_recipe 'java::default'

platform = node['platform']
distro = node['lsb']['codename']

unless distro
  if platform?('debian') && node['platform_version'].start_with?('6.0')
    # On Debian, Ohai requires the `lsb-release` package to pick up the
    # codename. Since we only support squeeze, just hardcode it.
    distro = 'squeeze'
  else
    Chef::Application.fatal!('Unable to detect LSB codename. Ensure LSB support packages are installed.')
  end
end

apt_repository 'cloudera_cdh' do
  uri          "http://archive.cloudera.com/cdh4/#{platform}/#{distro}/amd64/cdh"
  distribution "#{distro}-cdh4"
  components   ['contrib']
  key          "http://archive.cloudera.com/cdh4/#{platform}/#{distro}/amd64/cdh/archive.key"
  arch         'amd64'
  deb_src      true
  action       :add
end

%w(hbase hbase-master).each do |name|
  package name
end

apt_repository 'cloudera_gplextras' do
  uri          "http://archive.cloudera.com/gplextras/#{platform}/#{distro}/amd64/gplextras/"
  distribution "#{distro}-gplextras4"
  components   ['contrib']
  key          "http://archive.cloudera.com/gplextras/#{platform}/#{distro}/amd64/gplextras/archive.key"
  arch         'amd64'
  deb_src      true
  action       :add
  only_if      { node['hbase']['lzo_compression'] }
end

%w(lzop hadoop-lzo-cdh4).each do |name|
  package name do
    only_if { node['hbase']['lzo_compression'] }
  end
end

directory node['hbase']['root_dir'] do
  owner    'hbase'
  group    'hbase'
  mode      0755
  recursive true
end

chef_conf_dir = "/etc/hbase/#{node['hbase']['conf_dir']}"

directory chef_conf_dir do
  mode      0755
  recursive true
end

template '/etc/default/hbase' do
  source 'hbase-defaults.erb'
  notifies :restart, 'service[hbase-master]'
end

template "#{chef_conf_dir}/hbase-site.xml" do
  source 'hbase-site.xml.erb'
  notifies :restart, 'service[hbase-master]'
end

execute 'update_hbase_conf_alternatives' do
  command "update-alternatives --install /etc/hbase/conf hbase-conf #{chef_conf_dir.shellescape} 60"
end

service 'hbase-master' do
  action [:enable, :start]
  supports :status => true, :restart => true
end

# The hbase-master service init scripts deadlock if hbase is started and then
# immediately restarted. Delay any restart notifications by at least 7 seconds.
ruby_block 'delay_notifications' do
  block { sleep 7 }
end
